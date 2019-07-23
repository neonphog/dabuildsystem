FROM da_armv7_32_p1
RUN cd /sources/gmp-6.1.2 && \
  cp -v configfsf.guess config.guess && \
  cp -v configfsf.sub config.sub && \
  ./configure --prefix=/buildsystem --enable-cxx --disable-static --build="$(uname -m)-unknown-linux-gnu" && \
  make && \
  make install
RUN cd /sources/mpfr-4.0.2 && \
  ./configure --prefix=/buildsystem --disable-static --enable-thread-safe && \
  make && \
  make install
RUN cd /sources/mpc-1.1.0 && \
  ./configure --prefix=/buildsystem --disable-static && \
  make && \
  make install
