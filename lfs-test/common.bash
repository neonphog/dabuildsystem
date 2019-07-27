#!/bin/bash

set -Eeuxo pipefail

LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT="x86_64-lfs-linux-gnu"

_name_tmp="da-build-tmp"
_repo="neonphog/dabuildsystem"
_img_build_base="debian:stretch-slim"
_img_da_build_tmp="${_repo}:${_name_tmp}"
_img_da_latest="${_repo}:latest"

function dl() {
  local __url="${1}"
  local __file="${2}"
  local __hash="${3}"
  if [ ! -f "${__file}" ]; then
    curl -L -O "${__url}"
  fi
  echo "${__file} hashes to $(sha256sum ${__file})"

  if echo "${__hash}  ${__file}" | sha256sum --check; then
    return
  fi

  echo "hash mismatch, attempting to re-download once"
  curl -L -O "${__url}"
  echo "${__file} hashes to $(sha256sum ${__file})"

  echo "${__hash}  ${__file}" | sha256sum --check
}
