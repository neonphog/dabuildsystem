#!/bin/bash

set -Eeuxo pipefail

docker build -t "neonphog/dabuildsystem:da_x86_64_p1" -f "./da_x86_64_p1.Dockerfile" .
docker build -t "neonphog/dabuildsystem:da_x86_64_p2" -f "./da_x86_64_p2.Dockerfile" .
docker build -t "neonphog/dabuildsystem:da_x86_64_p3" -f "./da_x86_64_p3.Dockerfile" .
docker build -t "neonphog/dabuildsystem:da_x86_64" -f "./da_x86_64.Dockerfile" .
