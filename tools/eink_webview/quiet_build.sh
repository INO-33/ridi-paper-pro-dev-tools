#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
out_dir="${PAPER_EMULATOR_OUT_DIR:-/media/juwon/build/paper-emulator-x86}"
source_tree="${ANDROID_BUILD_TOP:-$root_dir/android-sources/nxp-o8.0.0_1.0.0-ga}"
target="${1:-webview-target}"
java_home="${JAVA_HOME:-/usr/lib/jvm/java-11-openjdk-amd64}"
log_dir="$root_dir/.orchestrator/logs"
mkdir -p "$log_dir"
stamp="$(date +%Y%m%d-%H%M%S)"
log_file="$log_dir/build-${stamp}.log"

set +e
(cd "$source_tree" && JAVA_HOME="$java_home" PATH="$java_home/bin:$root_dir/host-tools/android8-bin:$PATH" "$out_dir/ninja-e70q10_emulator.sh" "$target") >"$log_file" 2>&1
status=$?
set -e

if [[ $status -eq 0 ]]; then
    echo "BUILD_OK $target"
    exit 0
fi

echo "BUILD_FAIL $target"
rg -n -i -m 20 'FAILED:|error:|fatal error:|ninja: build stopped|Traceback|undefined reference' "$log_file" || true
echo "full_log=$log_file"
exit "$status"
