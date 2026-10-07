#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source_root="${CHROMIUM_SRC_ROOT:-/media/juwon/build/chromium-m58/src}"
tag="58.0.3029.125"
commit="c254b52f7661657df3d56ff997030fc36988c9cd"
log_dir="$root_dir/.orchestrator/logs"
mkdir -p "$log_dir"
stamp="$(date +%Y%m%d-%H%M%S)"
log_file="$log_dir/chromium-bootstrap-${stamp}.log"

set +e
{
    echo "source_root=$source_root"
    echo "tag=$tag"
    echo "commit=$commit"
    if [[ -f "$source_root/DEPS" && -f "$source_root/BUILD.gn" ]]; then
        echo "source_checkout=present"
        echo "source_checkout=not_bootstrapped"
        false
    else
        echo "source_checkout=missing"
        if command -v gclient >/dev/null 2>&1; then
            echo "depot_tools=present"
        else
            echo "depot_tools=missing"
        fi
        echo "network_probe=git ls-remote refs/tags/$tag"
        timeout 15s git ls-remote https://chromium.googlesource.com/chromium/src.git \
            "refs/tags/$tag"
        probe_status=$?
        echo "network_probe_status=$probe_status"
        if [[ $probe_status -ne 0 ]]; then
            false
        fi
    fi
} >"$log_file" 2>&1
status=$?
set -e

if [[ $status -ne 0 ]]; then
    echo "CHROMIUM_BUILD_FAIL"
    echo "stage=source_bootstrap"
    rg -n -i -m 20 'missing|fatal|error|timed out|Could not resolve|network_probe_status' "$log_file" || true
    echo "full_log=$log_file"
    exit "$status"
fi

echo "CHROMIUM_SOURCE_PROBE_OK tag=$tag"
echo "full_log=$log_file"
