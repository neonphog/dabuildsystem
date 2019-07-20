FROM i386/debian:jessie-slim AS dabuild.step1
COPY ./qemu-i386-static /usr/bin/qemu-i386-static
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
  gcc g++ make m4 zlib1g-dev xz-utils curl

FROM dabuild.step1 AS dabuild.step2
COPY ./dabuild-download-deps.bash /dabuild-download-deps.bash
RUN /bin/bash /dabuild-download-deps.bash

FROM dabuild.step2 AS dabuild.step3
RUN cd /sources/gmp-6.1.2 && \
  cp -v configfsf.guess config.guess && \
  cp -v configfsf.sub config.sub && \
  ./configure --prefix=/buildsystem --enable-cxx --disable-static --build="$(uname -m)-unknown-linux-gnu" && \
  make && \
  make install

FROM amd64/debian:jessie-slim
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
COPY ./qemu-x86_64-static /usr/bin/qemu-x86_64-static
COPY --from=dabuild.step3 /buildsystem /buildsystem
