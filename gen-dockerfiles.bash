#!/bin/bash

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
  gcc g++ make m4 zlib1g-dev xz-utils curl
EOF

  cat > "${__step}_p2.Dockerfile" <<EOF
FROM ${__image}_p1
COPY ./dabuild-download-deps.bash /dabuild-download-deps.bash
RUN /bin/bash /dabuild-download-deps.bash

RUN cd /sources/gmp-6.1.2 && \\
  cp -v configfsf.guess config.guess && \\
  cp -v configfsf.sub config.sub && \\
  ./configure --prefix=/buildsystem --enable-cxx --disable-static --build="\$(uname -m)-unknown-linux-gnu" && \\
  make && \\
  make install
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
COPY --from=${__image}_p2 /buildsystem /buildsystem
EOF
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
