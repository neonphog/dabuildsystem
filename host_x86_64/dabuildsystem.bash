#!/bin/bash

set -Eeuxo pipefail

cat > /etc/apt/sources.list <<EOF
deb http://archive.debian.org/debian/ jessie main
deb-src http://archive.debian.org/debian/ jessie main
deb http://security.debian.org jessie/updates main
deb-src http://security.debian.org jessie/updates main
EOF

# arm doesn't have security updates.. allow failures here
apt-get update || true

apt-get install -y --no-install-recommends \
  gcc g++ make m4 zlib1g-dev xz-utils curl

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

# -- build deps -- #

cd /sources/gmp-6.1.2
cp -v configfsf.guess config.guess
cp -v configfsf.sub config.sub
./configure --prefix=/buildsystem --enable-cxx --disable-static --build="$(uname -m)-unknown-linux-gnu"
make
make install

# -- cleanup -- #

rm -rf /sources
rm -rf /var/lib/apt/lists/*
