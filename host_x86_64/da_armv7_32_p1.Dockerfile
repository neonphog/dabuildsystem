FROM arm32v7/debian:jessie-slim
COPY ./qemu-arm-static /usr/bin/qemu-arm-static
ENV \
  PATH="/buildsystem/bin:${PATH}" \
  C_INCLUDE_PATH="/buildsystem/include" \
  CPLUS_INCLUDE_PATH="/buildsystem/include" \
  LIBRARY_PATH="/buildsystem/lib" \
  PKG_CONFIG_PATH="/buildsystem/lib/pkgconfig:/usr/lib/pkgconfig" \
  LD_LIBRARY_PATH="/buildsystem/lib" \
  CFLAGS="-I/buildsystem/include" \
  CXXFLAGS="-I/buildsystem/include" \
  LDFLAGS="-L/buildsystem/lib"
RUN printf \
"deb http://archive.debian.org/debian/ jessie main\n"\
"deb-src http://archive.debian.org/debian/ jessie main\n"\
"deb http://security.debian.org jessie/updates main\n"\
"deb-src http://security.debian.org jessie/updates main\n"\
  > /etc/apt/sources.list
RUN apt-get update || true
RUN apt-get install -y --no-install-recommends \
  gcc g++ make m4 zlib1g-dev xz-utils curl ca-certificates
RUN mkdir -p /sources &&\
  cd /sources &&\
  printf \
"#!/bin/bash\n"\
"\n"\
"set -Eeuxo pipefail\n"\
"\n"\
"function dl() {\n"\
"  local __url=\"\${1}\"\n"\
"  local __file=\"\${2}\"\n"\
"  local __hash=\"\${3}\"\n"\
"  if [ ! -f \"\${__file}\" ]; then\n"\
"    curl -L -O \"\${__url}\"\n"\
"  fi\n"\
"  echo \"\${__file} hashes to \$(sha256sum \${__file})\"\n"\
"\n"\
"  if echo \"\${__hash}  \${__file}\" | sha256sum --check; then\n"\
"    return\n"\
"  fi\n"\
"\n"\
"  echo \"hash mismatch, attempting to re-download once\"\n"\
"  curl -L -O \"\${__url}\"\n"\
"  echo \"\${__file} hashes to \$(sha256sum \${__file})\"\n"\
"\n"\
"  echo \"\${__hash}  \${__file}\" | sha256sum --check\n"\
"}\n"\
"\n"\
"dl \"\${1}\" \"\${2}\" \"\${3}\"\n"\
  > /sources/da-dl.bash &&\
  chmod a+x /sources/da-dl.bash
RUN cd /sources && ./da-dl.bash \
  "http://ftp.gnu.org/gnu/gmp/gmp-6.1.2.tar.xz" \
  "gmp-6.1.2.tar.xz" \
  "87b565e89a9a684fe4ebeeddb8399dce2599f9c9049854ca8c0dfbdea0e21912" &&\
  tar xf gmp-6.1.2.tar.xz
RUN cd /sources && ./da-dl.bash \
  "http://www.mpfr.org/mpfr-4.0.2/mpfr-4.0.2.tar.xz" \
  "mpfr-4.0.2.tar.xz" \
  "1d3be708604eae0e42d578ba93b390c2a145f17743a744d8f3f8c2ad5855a38a" && \
  tar xf mpfr-4.0.2.tar.xz
RUN cd /sources && ./da-dl.bash \
  "https://ftp.gnu.org/gnu/mpc/mpc-1.1.0.tar.gz" \
  "mpc-1.1.0.tar.gz" \
  "6985c538143c1208dcb1ac42cedad6ff52e267b47e5f970183a3e75125b43c2e" && \
  tar xf mpc-1.1.0.tar.gz
RUN cd /sources && ./da-dl.bash \
  "http://ftp.gnu.org/gnu/gcc/gcc-8.2.0/gcc-8.2.0.tar.xz" \
  "gcc-8.2.0.tar.xz" \
  "196c3c04ba2613f893283977e6011b2345d1cd1af9abeac58e916b1aab3e0080" && \
  tar xf gcc-8.2.0.tar.xz
