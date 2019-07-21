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
COPY --from=da_x86_64_p2 /buildsystem /buildsystem
