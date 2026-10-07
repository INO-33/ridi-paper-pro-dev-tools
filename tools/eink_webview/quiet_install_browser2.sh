#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
serial="${ANDROID_SERIAL:-emulator-5554}"
adb="${ADB:-$root_dir/host-tools/android-platform-tools/platform-tools/adb}"
apk="${PAPER_BROWSER2_APK:-/media/juwon/build/paper-emulator-x86/target/product/e70q10_emulator/system/app/Browser2/Browser2.apk}"
log_dir="$root_dir/.orchestrator/logs"
mkdir -p "$log_dir"
stamp="$(date +%Y%m%d-%H%M%S)"
log_file="$log_dir/install-browser2-${stamp}.log"

set +e
{
    echo "serial=$serial"
    echo "apk=$apk"
    sha256sum "$apk"
    "$adb" -s "$serial" install -r -d "$apk"
    install_status=$?
    if [[ $install_status -ne 0 ]]; then
        echo "install_command_failed=$install_status"
        false
    else
        "$adb" -s "$serial" shell dumpsys package org.chromium.webview_shell \
            | rg -n -m 4 'versionName|versionCode|codePath|enabled=' || true
    fi
} >"$log_file" 2>&1
status=$?
set -e

if [[ $status -ne 0 ]]; then
    echo "INSTALL_FAIL Browser2"
    rg -n -i -m 20 'Failure|error|failed|not found|exception' "$log_file" || true
    echo "full_log=$log_file"
    exit "$status"
fi

echo "INSTALL_OK Browser2"
echo "full_log=$log_file"
