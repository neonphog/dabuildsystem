FROM neonphog/dabuildsystem:da_x86_64_p1
RUN cd /sources/gmp-6.1.2 && \
  cp -v configfsf.guess config.guess && \
  cp -v configfsf.sub config.sub && \
  ./configure --prefix=/buildsystem --enable-cxx --disable-static --build="$(uname -m)-unknown-linux-gnu" && \
  make -j$(nproc) && \
  make install
RUN cd /sources/mpfr-4.0.2 && \
  ./configure --prefix=/buildsystem --disable-static --enable-thread-safe && \
  make -j$(nproc) && \
  make install
RUN cd /sources/mpc-1.1.0 && \
  ./configure --prefix=/buildsystem --disable-static && \
  make -j$(nproc) && \
  make install
