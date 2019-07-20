FROM dabuild_x86_64_to_x86_64:latest_prep_1
COPY ./dabuild-download-deps.bash /dabuild-download-deps.bash
RUN /bin/bash /dabuild-download-deps.bash

RUN cd /sources/gmp-6.1.2 && \
  cp -v configfsf.guess config.guess && \
  cp -v configfsf.sub config.sub && \
  ./configure --prefix=/buildsystem --enable-cxx --disable-static --build="$(uname -m)-unknown-linux-gnu" && \
  make && \
  make install
