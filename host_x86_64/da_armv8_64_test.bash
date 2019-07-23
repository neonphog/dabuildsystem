#!/bin/bash

set -Eeuxo pipefail

docker build -t "da_armv8_64_p1" -f "./da_armv8_64_p1.Dockerfile" .
docker build -t "da_armv8_64_p2" -f "./da_armv8_64_p2.Dockerfile" .
docker build -t "da_armv8_64" -f "./da_armv8_64.Dockerfile" .
