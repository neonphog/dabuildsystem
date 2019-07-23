#!/bin/bash

set -Eeuxo pipefail

function gen_docker() {
  local __arch="${1}"
  local __qemu="${2}"
  local __base="${3}"

  local __image="da_${__arch}"
  local __step="./host_x86_64/${__image}"

  cat > "${__step}_p1.Dockerfile" <<EOF
FROM ${__base}
COPY ./${__qemu} /usr/bin/${__qemu}
ENV \\
  PATH="/buildsystem/bin:\${PATH}" \\
  C_INCLUDE_PATH="/buildsystem/include" \\
  CPLUS_INCLUDE_PATH="/buildsystem/include" \\
  LIBRARY_PATH="/buildsystem/lib" \\
  PKG_CONFIG_PATH="/buildsystem/lib/pkgconfig:/usr/lib/pkgconfig" \\
  LD_LIBRARY_PATH="/buildsystem/lib" \\
  CFLAGS="-I/buildsystem/include" \\
  CXXFLAGS="-I/buildsystem/include" \\
  LDFLAGS="-L/buildsystem/lib"
RUN printf \\
"deb http://archive.debian.org/debian/ jessie main\\n"\\
"deb-src http://archive.debian.org/debian/ jessie main\\n"\\
"deb http://security.debian.org jessie/updates main\\n"\\
"deb-src http://security.debian.org jessie/updates main\\n"\\
  > /etc/apt/sources.list
RUN apt-get update || true
RUN apt-get install -y --no-install-recommends \\
  gcc g++ make m4 zlib1g-dev xz-utils curl ca-certificates
RUN mkdir -p /sources &&\\
  cd /sources &&\\
  printf \\
"#!/bin/bash\\n"\\
"\\n"\\
"set -Eeuxo pipefail\\n"\\
"\\n"\\
"function dl() {\\n"\\
"  local __url=\"\\\${1}\"\\n"\\
"  local __file=\"\\\${2}\"\\n"\\
"  local __hash=\"\\\${3}\"\\n"\\
"  if [ ! -f \"\\\${__file}\" ]; then\\n"\\
"    curl -L -O \"\\\${__url}\"\\n"\\
"  fi\\n"\\
"  echo \"\\\${__file} hashes to \\\$(sha256sum \\\${__file})\"\\n"\\
"\\n"\\
"  if echo \"\\\${__hash}  \\\${__file}\" | sha256sum --check; then\\n"\\
"    return\\n"\\
"  fi\\n"\\
"\\n"\\
"  echo \"hash mismatch, attempting to re-download once\"\\n"\\
"  curl -L -O \"\\\${__url}\"\\n"\\
"  echo \"\\\${__file} hashes to \\\$(sha256sum \\\${__file})\"\\n"\\
"\\n"\\
"  echo \"\\\${__hash}  \\\${__file}\" | sha256sum --check\\n"\\
"}\\n"\\
"\\n"\\
"dl \"\\\${1}\" \"\\\${2}\" \"\\\${3}\"\\n"\\
  > /sources/da-dl.bash &&\\
  chmod a+x /sources/da-dl.bash
RUN cd /sources && ./da-dl.bash \\
  "http://ftp.gnu.org/gnu/gmp/gmp-6.1.2.tar.xz" \\
  "gmp-6.1.2.tar.xz" \\
  "87b565e89a9a684fe4ebeeddb8399dce2599f9c9049854ca8c0dfbdea0e21912" &&\\
  tar xf gmp-6.1.2.tar.xz
RUN cd /sources && ./da-dl.bash \\
  "http://www.mpfr.org/mpfr-4.0.2/mpfr-4.0.2.tar.xz" \\
  "mpfr-4.0.2.tar.xz" \\
  "1d3be708604eae0e42d578ba93b390c2a145f17743a744d8f3f8c2ad5855a38a" && \\
  tar xf mpfr-4.0.2.tar.xz
RUN cd /sources && ./da-dl.bash \\
  "https://ftp.gnu.org/gnu/mpc/mpc-1.1.0.tar.gz" \\
  "mpc-1.1.0.tar.gz" \\
  "6985c538143c1208dcb1ac42cedad6ff52e267b47e5f970183a3e75125b43c2e" && \\
  tar xf mpc-1.1.0.tar.gz
RUN cd /sources && ./da-dl.bash \\
  "http://ftp.gnu.org/gnu/gcc/gcc-8.2.0/gcc-8.2.0.tar.xz" \\
  "gcc-8.2.0.tar.xz" \\
  "196c3c04ba2613f893283977e6011b2345d1cd1af9abeac58e916b1aab3e0080" && \\
  tar xf gcc-8.2.0.tar.xz
EOF

  cat > "${__step}_p2.Dockerfile" <<EOF
FROM neonphog/dabuildsystem:${__image}_p1
RUN cd /sources/gmp-6.1.2 && \\
  cp -v configfsf.guess config.guess && \\
  cp -v configfsf.sub config.sub && \\
  ./configure --prefix=/buildsystem --enable-cxx --disable-static --build="\$(uname -m)-unknown-linux-gnu" && \\
  make -j\$(nproc) && \\
  make install
RUN cd /sources/mpfr-4.0.2 && \\
  ./configure --prefix=/buildsystem --disable-static --enable-thread-safe && \\
  make -j\$(nproc) && \\
  make install
RUN cd /sources/mpc-1.1.0 && \\
  ./configure --prefix=/buildsystem --disable-static && \\
  make -j\$(nproc) && \\
  make install
EOF

  cat > "${__step}_p3.Dockerfile" <<EOF
FROM neonphog/dabuildsystem:${__image}_p2
RUN cd /sources/gcc-8.2.0 && \\
  sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64 && \\
  mkdir build && \\
  cd build && \\
  SED=sed ../configure --prefix=/buildsystem --enable-languages=c,c++ --disable-multilib --disable-bootstrap --disable-libmpx --with-system-zlib && \\
  make -j\$(nproc) && \\
  make install && \\
  ln -sv /buildsystem/bin/gcc /buildsystem/bin/cc && \\
  install -v -dm755 /buildsystem/lib/bfd-plugins && \\
  ln -sfv ../../libexec/gcc/\$(gcc -dumpmachine)/8.2.0/liblto_plugin.so /buildsystem/lib/bfd-plugins/
EOF

  cat > "${__step}.Dockerfile" <<EOF
FROM ${__base}
ENV \\
  PATH="/buildsystem/bin:\${PATH}" \\
  C_INCLUDE_PATH="/buildsystem/include" \\
  CPLUS_INCLUDE_PATH="/buildsystem/include" \\
  LIBRARY_PATH="/buildsystem/lib" \\
  PKG_CONFIG_PATH="/buildsystem/lib/pkgconfig:/usr/lib/pkgconfig" \\
  LD_LIBRARY_PATH="/buildsystem/lib" \\
  CFLAGS="-I/buildsystem/include" \\
  CXXFLAGS="-I/buildsystem/include" \\
  LDFLAGS="-L/buildsystem/lib"
COPY ./qemu-x86_64-static /usr/bin/qemu-x86_64-static
COPY --from=neonphog/dabuildsystem:${__image}_p3 /buildsystem /buildsystem
EOF

  cat > "${__step}_test.bash" <<EOF
#!/bin/bash

set -Eeuxo pipefail

docker build -t "neonphog/dabuildsystem:${__image}_p1" -f "./${__image}_p1.Dockerfile" .
docker build -t "neonphog/dabuildsystem:${__image}_p2" -f "./${__image}_p2.Dockerfile" .
docker build -t "neonphog/dabuildsystem:${__image}_p3" -f "./${__image}_p3.Dockerfile" .
docker build -t "neonphog/dabuildsystem:${__image}" -f "./${__image}.Dockerfile" .
EOF
  chmod a+x "${__step}_test.bash"
}

gen_docker \
  "x86_32" \
  "qemu-i386-static" \
  "i386/debian:jessie-slim"

gen_docker \
  "x86_64" \
  "qemu-x86_64-static" \
  "amd64/debian:jessie-slim"

gen_docker \
  "armv7_32" \
  "qemu-arm-static" \
  "arm32v7/debian:jessie-slim"

gen_docker \
  "armv8_64" \
  "qemu-aarch64-static" \
  "arm64v8/debian:jessie-slim"
