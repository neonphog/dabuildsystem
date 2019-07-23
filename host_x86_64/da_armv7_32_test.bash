#!/bin/bash

set -Eeuxo pipefail

docker build -t "da_armv7_32_p1" -f "./da_armv7_32_p1.Dockerfile" .
docker build -t "da_armv7_32_p2" -f "./da_armv7_32_p2.Dockerfile" .
docker build -t "da_armv7_32" -f "./da_armv7_32.Dockerfile" .
