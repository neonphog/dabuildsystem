#!/bin/bash

function gen_docker() {
  local __file="${1}"
  local __qemu="${2}"
  local __docker="${3}"

  cat > "${__file}" <<EOF
FROM ${__docker} AS dabuild.step1
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

FROM dabuild.step1 AS dabuild.step2
COPY ./dabuild-download-deps.bash /dabuild-download-deps.bash
RUN /bin/bash /dabuild-download-deps.bash

FROM dabuild.step2 AS dabuild.step3
RUN cd /sources/gmp-6.1.2 && \\
  cp -v configfsf.guess config.guess && \\
  cp -v configfsf.sub config.sub && \\
  ./configure --prefix=/buildsystem --enable-cxx --disable-static --build="\$(uname -m)-unknown-linux-gnu" && \\
  make && \\
  make install

FROM amd64/debian:jessie-slim
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
COPY --from=dabuild.step3 /buildsystem /buildsystem
EOF
}

gen_docker \
  "./host_x86_64/target_x86_32.Dockerfile" \
  "qemu-i386-static" \
  "i386/debian:jessie-slim"

gen_docker \
  "./host_x86_64/target_x86_64.Dockerfile" \
  "qemu-x86_64-static" \
  "amd64/debian:jessie-slim"

gen_docker \
  "./host_x86_64/target_armv7_32.Dockerfile" \
  "qemu-arm-static" \
  "arm32v7/debian:jessie-slim"

gen_docker \
  "./host_x86_64/target_armv8_64.Dockerfile" \
  "qemu-aarch64-static" \
  "arm64v8/debian:jessie-slim"
