#!/bin/bash

set -Eeuxo pipefail

src_dir="${BASH_SOURCE[0]}"
while [ -h "${src_dir}" ]; do
  work_dir="$(cd -P "$(dirname "${src_dir}")" >/dev/null 2>&1 && pwd)"
  src_dir="$(readlink "${src_dir}")"
  [[ ${src_dir} != /* ]] && src_dir="${work_dir}/${src_dir}"
done
work_dir="$(cd -P "$(dirname "${src_dir}")" >/dev/null 2>&1 && pwd)"

cd "${work_dir}"

source ./common.bash

PATH="/tools/bin:/bin:/usr/bin"

echo "GOT BUILD_STEP: ${BUILD_STEP}"

# -- build temp binutils -- #

if [ "${BUILD_STEP}" == "da-build-tmp-binutils" ]; then
  cd $LFS/sources
  tar xf /host/downloads/binutils-2.32.tar.xz
  cd binutils-2.32
  mkdir -v build
  cd build
  ../configure --prefix=/tools            \
               --with-sysroot=$LFS        \
               --with-lib-path=/tools/lib \
               --target=$LFS_TGT          \
               --disable-nls              \
               --disable-werror
  make -j$(nproc)
  case $(uname -m) in
    x86_64) mkdir -v /tools/lib && ln -sv lib /tools/lib64 ;;
  esac
  make install
  rm -rf $LFS/sources/*
fi

# -- build temp gcc -- #

if [ "${BUILD_STEP}" == "da-build-tmp-gcc" ]; then
  cd $LFS/sources
  tar xf /host/downloads/gcc-8.2.0.tar.xz
  cd gcc-8.2.0
  tar xf /host/downloads/mpfr-4.0.2.tar.xz
  mv -v mpfr-4.0.2 mpfr
  tar xf /host/downloads/gmp-6.1.2.tar.xz
  mv -v gmp-6.1.2 gmp
  tar xf /host/downloads/mpc-1.1.0.tar.gz
  mv -v mpc-1.1.0 mpc
  for file in gcc/config/{linux,i386/linux{,64}}.h
  do
    cp -uv $file{,.orig}
    sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
        -e 's@/usr@/tools@g' $file.orig > $file
    echo '
  #undef STANDARD_STARTFILE_PREFIX_1
  #undef STANDARD_STARTFILE_PREFIX_2
  #define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
  #define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
    touch $file.orig
  done
  sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
  mkdir -v build
  cd build
  ../configure                                       \
      --target=$LFS_TGT                              \
      --prefix=/tools                                \
      --with-glibc-version=2.11                      \
      --with-sysroot=$LFS                            \
      --with-newlib                                  \
      --without-headers                              \
      --with-local-prefix=/tools                     \
      --with-native-system-header-dir=/tools/include \
      --disable-nls                                  \
      --disable-shared                               \
      --disable-multilib                             \
      --disable-decimal-float                        \
      --disable-threads                              \
      --disable-libatomic                            \
      --disable-libgomp                              \
      --disable-libmpx                               \
      --disable-libquadmath                          \
      --disable-libssp                               \
      --disable-libvtv                               \
      --disable-libstdcxx                            \
      --enable-languages=c,c++
  make -j$(nproc)
  make install
  rm -rf $LFS/sources/*
fi

#mkdir -pv $LFS/{dev,proc,sys,run}
#mknod -m 600 $LFS/dev/console c 5 1
#mknod -m 666 $LFS/dev/null c 1 3
#mount -v --bind /dev $LFS/dev
#mount -vt devpts devpts $LFS/dev/pts -o gid=5,mode=620
#mount -vt proc proc $LFS/proc
#mount -vt sysfs sysfs $LFS/sys
#mount -vt tmpfs tmpfs $LFS/run
#if [ -h $LFS/dev/shm ]; then
#  mkdir -pv $LFS/$(readlink $LFS/dev/shm)
#fi
