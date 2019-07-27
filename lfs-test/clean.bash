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

rm -rf downloads || true
docker container rm -f $(docker container ls -a | grep "${_name_tmp}" | awk '{print $1}') || true
docker image rm -f $(docker image ls | grep "${_name_tmp}" | awk '{print $3}') || true
