#!/bin/bash

# -- sane bash errors -- #
set -Eeuo pipefail

# -- resolve symlinks in path -- #

src_dir="${BASH_SOURCE[0]}"
while [ -h "${src_dir}" ]; do
  work_dir="$(cd -P "$(dirname "${src_dir}")" >/dev/null 2>&1 && pwd)"
  src_dir="$(readlink "${src_dir}")"
  [[ ${src_dir} != /* ]] && src_dir="${work_dir}/${src_dir}"
done
work_dir="$(cd -P "$(dirname "${src_dir}")" >/dev/null 2>&1 && pwd)"

cd "${work_dir}"

# -- functions -- #

function log() {
  echo "**dabuild** ${@}"
}

function dl() {
  local __url="${1}"
  local __file="${2}"
  local __hash="${3}"
  if [ ! -f "${__file}" ]; then
    curl -L -O "${__url}"
  fi
  log "${__file} hashes to $(sha256sum ${__file})"

  if echo "${__hash}  ${__file}" | sha256sum --check; then
    return
  fi

  log "hash mismatch, attempting to re-download once"
  curl -L -O "${__url}"
  log "${__file} hashes to $(sha256sum ${__file})"

  echo "${__hash}  ${__file}" | sha256sum --check
}

# -- variables -- #

this_arch="$(uname -m)"

qemu_url=""
qemu_file=""
qemu_hash=""

case "${this_arch}" in
  "x86_64")
    qemu_url="http://ftp.us.debian.org/debian/pool/main/q/qemu/qemu-user-static_3.1+dfsg-8~deb10u1_amd64.deb"
    qemu_file="qemu-user-static_3.1+dfsg-8~deb10u1_amd64.deb"
    qemu_hash="244d9e69509bb9930716d7bb0873c1bd1afcd7cba62161a49ca0b6d99c93bec2"
    ;;
  *)
    log "ERROR, unsupported host arch ${this_arch}, supported hosts: x86_64"
    exit 1
    ;;
esac

tgt_arch="${TGT_ARCH:-unset}"

qemu_bin=""
docker_from=""

case "${tgt_arch}" in
  "x86_32")
    qemu_bin="qemu-i386-static"
    docker_from="i386/debian:jessie-slim"
    ;;
  "x86_64")
    qemu_bin="qemu-x86_64-static"
    docker_from="amd64/debian:jessie-slim"
    ;;
  "armv7_32")
    qemu_bin="qemu-arm-static"
    docker_from="arm32v7/debian:jessie-slim"
    ;;
  "armv8_64")
    qemu_bin="qemu-aarch64-static"
    docker_from="arm64v8/debian:jessie-slim"
    ;;
  *)
    log "ERROR, unsupported target arch TGT_ARCH='${tgt_arch}', supported targets: x86_32, x86_64, armv7_32, armv8_64"
    exit 1
    ;;
esac

docker_img="dabuild-docker-${tgt_arch}"

# -- setup build directory -- #

common_dir="$(pwd)/build/common"
mkdir -p "${common_dir}"

work_dir="$(pwd)/build/${tgt_arch}"
mkdir -p "${work_dir}"
cd "${work_dir}"

out_dir="${work_dir}/output"
mkdir -p "${out_dir}"

docker_dir="${work_dir}/docker"
mkdir -p "${docker_dir}"

# -- qemu-user-static -- #

log "download and extract qemu-user-static"

( \
  cd "${common_dir}" && \
  dl "${qemu_url}" "${qemu_file}" "${qemu_hash}" && \
  mkdir -p ./qemu && \
  cd ./qemu && \
  ar x "../${qemu_file}" && \
  tar xf data.tar.xz \
)
#cp "${common_dir}/qemu/usr/bin/${qemu_bin}" "${docker_dir}/${qemu_bin}"

# - download deps -- #

( \
  cd "${common_dir}" && \
  dl \
    "http://ftp.gnu.org/gnu/gmp/gmp-6.1.2.tar.xz" \
    "gmp-6.1.2.tar.xz" \
    "87b565e89a9a684fe4ebeeddb8399dce2599f9c9049854ca8c0dfbdea0e21912" && \
  tar xf gmp-6.1.2.tar.xz && \
  dl \
    "http://www.mpfr.org/mpfr-4.0.2/mpfr-4.0.2.tar.xz" \
    "mpfr-4.0.2.tar.xz" \
    "1d3be708604eae0e42d578ba93b390c2a145f17743a744d8f3f8c2ad5855a38a" && \
  tar xf mpfr-4.0.2.tar.xz && \
  dl \
    "https://ftp.gnu.org/gnu/mpc/mpc-1.1.0.tar.gz" \
    "mpc-1.1.0.tar.gz" \
    "6985c538143c1208dcb1ac42cedad6ff52e267b47e5f970183a3e75125b43c2e" && \
  tar xf mpc-1.1.0.tar.gz && \
  dl \
    "http://ftp.gnu.org/gnu/gcc/gcc-8.2.0/gcc-8.2.0.tar.xz" \
    "gcc-8.2.0.tar.xz" \
    "196c3c04ba2613f893283977e6011b2345d1cd1af9abeac58e916b1aab3e0080" && \
  tar xf gcc-8.2.0.tar.xz \
)

# - generate build script - #
cat > "${common_dir}/docker-build.bash" <<EOF
#!/bin/bash
set -Eeuxo pipefail
mkdir -p /buildsystem

echo "WE ARE RUNNING THIS THING!!!"

echo "-- BUILD gmp --"
cd /common/gmp-6.1.2
cp -v configfsf.guess config.guess
cp -v configfsf.sub config.sub
./configure --prefix=/buildsystem --enable-cxx --disable-static --build=\$(uname -m)-unknown-linux-gnu
make
make install

echo "-- BUILD mpfr --"
cd /common/mpfr-4.0.2
./configure --prefix=/buildsystem --disable-static --enable-thread-safe
make
make install

echo "-- BUILD mpc --"
cd /common/mpc-1.1.0
./configure --prefix=/buildsystem --disable-static
make
make install

echo "DOCKER BUILD COMPLETE"
EOF
chmod a+x "${common_dir}/docker-build.bash"

# - copy common files into docker dir - #

cp -a "${common_dir}" "${docker_dir}"

# - run docker build - #

cat > "${docker_dir}/Dockerfile" <<EOF
FROM ${docker_from}

COPY ./common/qemu/usr/bin/${qemu_bin} /usr/bin/${qemu_bin}

RUN printf "1" > /cache-break

COPY ./common /common

ENV \
  PATH="/buildsystem/bin:\${PATH}" \
  C_INCLUDE_PATH="/buildsystem/include" \
  CPLUS_INCLUDE_PATH="/buildsystem/include" \
  LIBRARY_PATH="/buildsystem/lib" \
  PKG_CONFIG_PATH="/buildsystem/lib/pkgconfig:/usr/lib/pkgconfig" \
  LD_LIBRARY_PATH="/buildsystem/lib" \
  CFLAGS="-I/buildsystem/include" \
  CXXFLAGS="-I/buildsystem/include" \
  LDFLAGS="-L/buildsystem/lib"

RUN printf "deb http://archive.debian.org/debian/ jessie main\n"\
"deb-src http://archive.debian.org/debian/ jessie main\n"\
"deb http://security.debian.org jessie/updates main\n"\
"deb-src http://security.debian.org jessie/updates main\n"\
"" > /etc/apt/sources.list && \
apt-get update || true && \
apt-get install -y --no-install-recommends \
  gcc g++ make m4 \
  && \
cd /common && \
./docker-build.bash && \
rm -rf /var/lib/apt/lists/*
# rm -rf /common
EOF

( \
  cd "${docker_dir}" && \
  docker build -t "${docker_img}" . && \
  docker run --rm -it "${docker_img}" /bin/bash \
)
