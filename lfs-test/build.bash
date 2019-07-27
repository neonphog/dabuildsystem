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

mkdir -vp downloads
chmod -v a+wt downloads

# -- build base system -- #
docker rm "${_name_tmp}" || true
if [ "x$(docker image ls -q ${_img_da_build_tmp})" == "x" ]; then
  docker run -it --name="${_name_tmp}" \
    -v $(pwd):/host:ro \
    "${_img_build_base}" \
    bash /host/_build-da-build-tmp.bash
  docker commit "${_name_tmp}" "${_img_da_build_tmp}"
fi

# -- use base system to verify download cache -- #
docker rm "${_name_tmp}" || true
docker run --rm -it --name="${_name_tmp}" \
  -v $(pwd):/host:ro \
  -v $(pwd)/downloads:/downloads \
  "${_img_da_build_tmp}" \
  bash /host/_build-da-download.bash

step_prev=""
step_next="${_img_da_build_tmp}"
function build_step() {
  step_prev="${step_next}"
  step_next="${_name_tmp}-${1}"
  local __next_img="${_repo}:${step_next}"
  if [ "x$(docker image ls -q ${__next_img})" == "x" ]; then
    docker rm "${step_next}" || true
    if ! docker run -it --name="${step_next}" \
      -v $(pwd):/host:ro \
      -e BUILD_STEP="${step_next}" \
      "${step_prev}" \
      bash /host/_build-lfs.bash
    then
      docker rm "${step_next}"
      exit 127
    fi
    docker commit "${step_next}" "${__next_img}"
    docker rm "${step_next}"
  fi
  step_next="${__next_img}"
}

build_step binutils
build_step gcc

# -- execute the lfs build -- #
#docker rm "${_name_tmp}" || true
#docker run --privileged -it --name="${_name_tmp}" \
#  -v $(pwd):/host:ro \
#  "${_img_da_build_tmp}" \
#  bash /host/_build-lfs.bash
#docker commit "${_name_tmp}" "${_img_da_latest}"
