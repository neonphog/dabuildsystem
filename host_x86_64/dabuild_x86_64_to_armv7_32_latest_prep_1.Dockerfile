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
  gcc g++ make m4 zlib1g-dev xz-utils curl
