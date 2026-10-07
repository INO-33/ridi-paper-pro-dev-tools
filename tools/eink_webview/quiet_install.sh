#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
out_dir="${PAPER_EMULATOR_OUT_DIR:-/media/juwon/build/paper-emulator-x86}"
serial="${ANDROID_SERIAL:-emulator-5554}"
apk="${1:-$out_dir/target/product/e70q10_emulator/system/app/webview/webview.apk}"
adb="${ADB:-$root_dir/host-tools/android-platform-tools/platform-tools/adb}"
log_dir="$root_dir/.orchestrator/logs"
mkdir -p "$log_dir"
stamp="$(date +%Y%m%d-%H%M%S)"
log_file="$log_dir/install-${stamp}.log"

set +e
{
    echo "serial=$serial"
    echo "apk=$apk"
    sha256sum "$apk"
    "$adb" -s "$serial" install -r -d "$apk"
    install_status=$?
    echo "install_status=$install_status"
    echo "--- webviewupdate ---"
    "$adb" -s "$serial" shell dumpsys webviewupdate
    provider_status=$?
    if [[ $install_status -ne 0 || $provider_status -ne 0 ]]; then
        false
    else
        true
    fi
} >"$log_file" 2>&1
status=$?
set -e

if [[ $status -ne 0 ]]; then
    echo "INSTALL_FAIL"
    rg -n -i -m 20 'Failure|INSTALL_FAILED|error|Exception|Current WebView package' "$log_file" || true
    echo "full_log=$log_file"
    exit "$status"
fi

current="$(rg -m 1 'Current WebView package \(name, version\):' "$log_file" || true)"
if [[ "$current" != *"com.android.webview"* || "$current" != *"58.0.3029.125"* ]]; then
    echo "INSTALL_FAIL"
    echo "provider=${current:-missing}"
    echo "full_log=$log_file"
    exit 1
fi

echo "INSTALL_OK"
echo "PROVIDER_OK version=58.0.3029.125"
