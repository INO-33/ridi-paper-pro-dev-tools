#!/usr/bin/env bash
set -euo pipefail
support="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
workspace="${RIDI_WORKSPACE:?Source the restored workspace/env.sh first}"
source_tree="${ANDROID_BUILD_TOP:?Source the restored workspace/env.sh first}"
mode="${1:-check}"
product="${2:-e70q10_reference-eng}"
[[ "$mode" == check || "$mode" == build ]] || { echo 'Usage: build.sh check|build [product-eng] [make targets]'; exit 2; }
export JAVA_HOME="$support/host-tools/jdk8-local/usr/lib/jvm/java-8-openjdk-amd64"
export RIDI_ANDROID8_TOOL_BIN="$support/host-tools/android8-bin"
export E70Q10_LUNCH="$product"
export E70Q10_OUT_DIR="${E70Q10_OUT_DIR:-$workspace/android-out/${product%-*}}"
export ANDROID_DATA="${ANDROID_DATA:-$E70Q10_OUT_DIR/.android-data}"
mkdir -p "$workspace/.orchestrator/logs" "$workspace/android-out" "$ANDROID_DATA"
log="$workspace/.orchestrator/logs/build-${product}-$(date +%Y%m%d-%H%M%S).log"
shift "$(( $# > 0 ? 1 : 0 ))"
(( $# == 0 )) || shift
if [[ "$mode" == build && $# == 0 ]]; then set -- droid; fi
if "$source_tree/device/ridi/e70q10/tools/build_android8.sh" "$mode" "$@" >"$log" 2>&1; then
    echo "${mode} completed for ${product}; log: ${log}"
else
    echo "${mode} failed for ${product}; log: ${log}" >&2
    tail -15 "$log" >&2
    exit 1
fi
