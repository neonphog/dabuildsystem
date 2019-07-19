FROM arm64v8/debian:jessie-slim
COPY ./qemu-aarch64-static /usr/bin/qemu-aarch64-static
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
COPY ./dabuildsystem.bash /dabuildsystem.bash
RUN /bin/bash /dabuildsystem.bash
