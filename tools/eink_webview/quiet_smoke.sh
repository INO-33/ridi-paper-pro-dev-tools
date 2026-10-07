#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
serial="${ANDROID_SERIAL:-emulator-5554}"
adb="${ADB:-$root_dir/host-tools/android-platform-tools/platform-tools/adb}"
activity_package="${PAPER_SMOKE_ACTIVITY_PACKAGE:-org.chromium.webview_shell}"
activity="${PAPER_SMOKE_ACTIVITY:-$activity_package/.WebViewBrowserActivity}"
page="$root_dir/tools/eink_webview/test_page.html"
log_dir="$root_dir/.orchestrator/logs"
evidence_dir="$root_dir/.orchestrator/evidence"
mkdir -p "$log_dir" "$evidence_dir"
stamp="$(date +%Y%m%d-%H%M%S)"
log_file="$log_dir/smoke-${stamp}.log"
shot_initial="$evidence_dir/smoke-${stamp}-initial.png"
shot="$evidence_dir/smoke-${stamp}-final.png"
port="${PAPER_SMOKE_PORT:-8765}"
config="${PAPER_SMOKE_CONFIG:-baseline}"
switches="${PAPER_SMOKE_SWITCHES:-}"
software_view="${PAPER_SMOKE_SOFTWARE_VIEW:-1}"
command_line_file="/data/local/tmp/webview-command-line"
server_pid=""

cleanup() {
    if [[ -n "$server_pid" ]]; then
        kill "$server_pid" 2>/dev/null || true
    fi
    "$adb" -s "$serial" reverse --remove "tcp:$port" >/dev/null 2>&1 || true
    "$adb" -s "$serial" shell rm "$command_line_file" >/dev/null 2>&1 || true
    "$adb" -s "$serial" shell am clear-debug-app >/dev/null 2>&1 || true
}
trap cleanup EXIT

python3 -m http.server "$port" --bind 127.0.0.1 --directory "$(dirname "$page")" \
    >"$log_dir/smoke-http-${stamp}.log" 2>&1 &
server_pid=$!

set +e
{
    echo "serial=$serial"
    echo "config=$config"
    echo "switches=$switches"
    echo "software_view=$software_view"
    echo "activity=$activity"
    echo "url=http://127.0.0.1:$port/$(basename "$page")"
    "$adb" -s "$serial" reverse "tcp:$port" "tcp:$port"
    if [[ -n "$switches" ]]; then
        "$adb" -s "$serial" shell am set-debug-app --persistent "$activity_package"
        "$adb" -s "$serial" shell "echo 'webview $switches' > $command_line_file"
        "$adb" -s "$serial" shell chmod 0664 "$command_line_file"
    else
        "$adb" -s "$serial" shell rm "$command_line_file" >/dev/null 2>&1 || true
        "$adb" -s "$serial" shell am clear-debug-app >/dev/null 2>&1 || true
    fi
    echo "device_command_line=$($adb -s "$serial" shell cat "$command_line_file" 2>/dev/null || true)"
    echo "device_debug_app=$($adb -s "$serial" shell settings get global debug_app 2>/dev/null || true)"
    "$adb" -s "$serial" shell am force-stop "$activity_package"
    "$adb" -s "$serial" shell am start -W -n "$activity" \
        -d "http://127.0.0.1:$port/$(basename "$page")" \
        --ez cp05-software-view "$software_view"
    sleep 0.4
    "$adb" -s "$serial" exec-out screencap -p >"$shot_initial"
    sleep 1.4
    "$adb" -s "$serial" exec-out screencap -p >"$shot"
    validation_status=0
    python3 - "$shot_initial" "$shot" <<'PY'
from PIL import Image
import sys

before = Image.open(sys.argv[1]).convert("L")
after = Image.open(sys.argv[2]).convert("L")
width, height = after.size
content = (0, 80, width, height)
before_pixels = list(before.crop(content).getdata())
after_pixels = list(after.crop(content).getdata())
nonwhite = sum(pixel < 245 for pixel in after_pixels)
changed = sum(abs(left - right) > 25 for left, right in zip(before_pixels, after_pixels))
print("content_nonwhite=%d mutation_changed=%d" % (nonwhite, changed))
if nonwhite < 5000:
    raise SystemExit("rendered content is blank")
if changed < 3000:
    raise SystemExit("DOM mutation was not visible in the rendered content")
PY
    validation_status=$?
    if [[ $validation_status -ne 0 ]]; then
        echo "validation_status=$validation_status"
    fi
    echo "--- crash scan ---"
    "$adb" -s "$serial" logcat -d -v brief -t 240 | rg -n -i -m 40 'FATAL EXCEPTION|signal 11|crash|chromium|webview' || true
    if [[ $validation_status -ne 0 ]]; then
        false
    fi
} >"$log_file" 2>&1
status=$?
set -e

if [[ $status -ne 0 ]]; then
    echo "SMOKE_FAIL"
    rg -n -i -m 20 'Exception|Error|unable|not found|failed|crash' "$log_file" || true
    echo "full_log=$log_file"
    exit "$status"
fi

if [[ ! -s "$shot" ]]; then
    echo "SMOKE_FAIL"
    echo "error: empty screenshot"
    echo "full_log=$log_file"
    exit 1
fi

echo "SMOKE_OK screenshot=$shot"
echo "full_log=$log_file"
