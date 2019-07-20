#!/bin/bash

set -Eeuxo pipefail

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

mkdir /sources
cd /sources

# -- download required deps -- #

dl \
  "http://ftp.gnu.org/gnu/gmp/gmp-6.1.2.tar.xz" \
  "gmp-6.1.2.tar.xz" \
  "87b565e89a9a684fe4ebeeddb8399dce2599f9c9049854ca8c0dfbdea0e21912"
tar xf gmp-6.1.2.tar.xz
