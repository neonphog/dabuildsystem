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

cd /downloads

dl \
  http://ftp.gnu.org/gnu/binutils/binutils-2.32.tar.xz \
  binutils-2.32.tar.xz \
  0ab6c55dd86a92ed561972ba15b9b70a8b9f75557f896446c82e8b36e473ee04

dl \
  http://www.mpfr.org/mpfr-4.0.2/mpfr-4.0.2.tar.xz \
  mpfr-4.0.2.tar.xz \
  1d3be708604eae0e42d578ba93b390c2a145f17743a744d8f3f8c2ad5855a38a

dl \
  http://ftp.gnu.org/gnu/gmp/gmp-6.1.2.tar.xz \
  gmp-6.1.2.tar.xz \
  87b565e89a9a684fe4ebeeddb8399dce2599f9c9049854ca8c0dfbdea0e21912

dl \
  https://ftp.gnu.org/gnu/mpc/mpc-1.1.0.tar.gz \
  mpc-1.1.0.tar.gz \
  6985c538143c1208dcb1ac42cedad6ff52e267b47e5f970183a3e75125b43c2e

dl \
  http://ftp.gnu.org/gnu/gcc/gcc-8.2.0/gcc-8.2.0.tar.xz \
  gcc-8.2.0.tar.xz \
  196c3c04ba2613f893283977e6011b2345d1cd1af9abeac58e916b1aab3e0080
