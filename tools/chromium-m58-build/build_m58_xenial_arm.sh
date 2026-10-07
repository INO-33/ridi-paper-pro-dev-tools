#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
context_dir="$root_dir/tools/chromium-m58-build"
image="${M58_DOCKER_IMAGE:-chromium-m58-build:xenial-bison304-jdk8-py2}"
source_root="${CHROMIUM_SRC_ROOT:-/media/juwon/build/chromium-m58/src}"
depot_tools_root="${DEPOT_TOOLS_ROOT:-/media/juwon/build/depot_tools}"
out_dir="${M58_OUT_DIR:-$source_root/out/m58_xenial_arm}"
log_dir="$root_dir/.orchestrator/logs"

mkdir -p "$log_dir"
stamp="$(date +%Y%m%d-%H%M%S)"
build_log="$log_dir/chromium-m58-docker-build-arm-${stamp}.log"
run_log="$log_dir/chromium-m58-docker-run-arm-${stamp}.log"

if [[ ! -d "$source_root/.git" ]]; then
  echo "CHROMIUM_M58_DOCKER_FAIL source_checkout_missing=$source_root" >&2
  exit 2
fi
if [[ ! -d "$depot_tools_root" ]]; then
  echo "CHROMIUM_M58_DOCKER_FAIL depot_tools_missing=$depot_tools_root" >&2
  exit 2
fi

if [[ "${M58_DOCKER_REBUILD:-0}" == "1" ]] || ! docker image inspect "$image" >/dev/null 2>&1; then
  echo "CHROMIUM_M58_DOCKER_IMAGE_BUILD image=$image"
  docker build --tag "$image" "$context_dir" >"$build_log" 2>&1
  echo "CHROMIUM_M58_DOCKER_IMAGE_READY image=$image"
else
  echo "CHROMIUM_M58_DOCKER_IMAGE_REUSE image=$image"
fi

echo "CHROMIUM_M58_DOCKER_BUILD_START target_cpu=arm out=$out_dir"
docker run --rm --init \
  --user "$(id -u):$(id -g)" \
  --env CHROMIUM_SRC_ROOT=/work/src \
  --env DEPOT_TOOLS_ROOT=/work/depot_tools \
  --env M58_TARGET_CPU=arm \
  --env M58_OUT_DIR=/work/src/out/m58_xenial_arm \
  --env M58_LOG_DIR=/work/logs \
  --env HOME=/tmp/m58-home \
  --env M58_ALLOW_DIRTY_SOURCE="${M58_ALLOW_DIRTY_SOURCE:-0}" \
  --mount "type=bind,src=$source_root,dst=/work/src" \
  --mount "type=bind,src=$depot_tools_root,dst=/work/depot_tools,readonly" \
  --mount "type=bind,src=$log_dir,dst=/work/logs" \
  --workdir /work/src \
  "$image" >"$run_log" 2>&1

echo "CHROMIUM_M58_DOCKER_BUILD_OK target_cpu=arm out=$out_dir"
