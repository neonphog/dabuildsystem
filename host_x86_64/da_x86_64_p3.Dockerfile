FROM neonphog/dabuildsystem:da_x86_64_p2
RUN cd /sources/gcc-8.2.0 && \
  sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64 && \
  mkdir build && \
  cd build && \
  SED=sed ../configure --prefix=/buildsystem --enable-languages=c,c++ --disable-multilib --disable-bootstrap --disable-libmpx --with-system-zlib && \
  make -j$(nproc) && \
  make install && \
  ln -sv /buildsystem/bin/gcc /buildsystem/bin/cc && \
  install -v -dm755 /buildsystem/lib/bfd-plugins && \
  ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/8.2.0/liblto_plugin.so /buildsystem/lib/bfd-plugins/
