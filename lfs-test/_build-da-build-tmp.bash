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

apt-get update || true

apt-get install -y \
  build-essential bison gawk m4 python3 texinfo \
  vim curl wget ca-certificates

rm -rf /bin/sh
ln -s /bin/bash /bin/sh

mkdir -vp $LFS
mkdir -vp $LFS/sources
chmod -v a+wt $LFS/sources
mkdir -v $LFS/tools
ln -sv $LFS/tools /tools
