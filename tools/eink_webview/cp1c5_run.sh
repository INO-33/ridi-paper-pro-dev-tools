#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
serial="${ANDROID_SERIAL:-emulator-5554}"
adb="${ADB:-$root_dir/host-tools/android-platform-tools/platform-tools/adb}"
activity_package="${CP1C5_ACTIVITY_PACKAGE:-org.chromium.webview_shell}"
activity="${CP1C5_ACTIVITY:-$activity_package/org.chromium.webview_shell.WebViewBrowserActivity}"
url="${CP1C5_URL:-http://127.0.0.1:8765/nav_minimal.html}"
mode="${1:-baseline}"
software_view="${CP1C5_SOFTWARE_VIEW:-0}"
log_dir="$root_dir/.orchestrator/logs"
evidence_dir="$root_dir/.orchestrator/evidence"
mkdir -p "$log_dir" "$evidence_dir"
stamp="$(date +%Y%m%d-%H%M%S)"
log_file="$log_dir/cp1c5-${mode}-${stamp}.log"
shot_file="$evidence_dir/cp1c5-${mode}-${stamp}.png"
command_line_file="/data/local/tmp/webview-command-line"

case "$mode" in
  baseline)
    switches=""
    ;;
  default)
    switches="--eink-c5-resource-default-runner"
    ;;
  main)
    switches="--eink-c5-resource-main-runner"
    ;;
  raw)
    switches="--eink-c6-resource-raw-thread"
    ;;
  bind)
    switches="--eink-c6-inproc-scheduler-bind"
    ;;
  trace)
    switches="--eink-c6-inproc-queue-trace"
    ;;
  twin)
    switches="--eink-c7-twin-resource-post"
    ;;
  lineage)
    switches="--eink-c7-resource-task-lineage"
    ;;
  kick)
    switches="--eink-c7-main-thread-kick"
    ;;
  cross-thread)
    switches="--eink-c7-cross-thread-enqueue-trace"
    ;;
  c8)
    switches="--eink-c7-resource-task-lineage --eink-c8-dedup-state --eink-c8-current-task"
    ;;
  c8-blocking)
    switches="--eink-c7-resource-task-lineage --eink-c8-dedup-state --eink-c8-current-task --eink-c8-blocking-task-trace"
    ;;
  c8-posted)
    switches="--eink-c7-resource-task-lineage --eink-c8-dedup-state --eink-c8-current-task --eink-c8-posted-generation"
    ;;
  c9)
    switches="--eink-c7-resource-task-lineage --eink-c8-dedup-state --eink-c8-current-task --eink-c8-blocking-task-trace --eink-c9-frame-sink-boundary --eink-c9-sync-owner"
    ;;
  c9-control)
    switches="--eink-c7-resource-task-lineage --eink-c8-dedup-state --eink-c8-current-task --eink-c8-blocking-task-trace --eink-c9-frame-sink-boundary --eink-c9-sync-owner"
    ;;
  c9-blocked|c9-blocked-control)
    switches="--eink-c7-resource-task-lineage --eink-c8-dedup-state --eink-c8-current-task --eink-c8-blocking-task-trace --eink-c9-frame-sink-boundary --eink-c9-sync-owner --eink-c9-blocked-call"
    ;;
  c10|c10-control)
    switches="--eink-c7-resource-task-lineage --eink-c8-dedup-state --eink-c8-current-task --eink-c8-blocking-task-trace --eink-c9-frame-sink-boundary --eink-c9-sync-owner --eink-c9-blocked-call --eink-c10-bind-ladder --eink-c10-gpu-sync"
    ;;
  c10-blocked-op|c10-fix-proof)
    switches="--eink-c7-resource-task-lineage --eink-c8-dedup-state --eink-c8-current-task --eink-c8-blocking-task-trace --eink-c9-frame-sink-boundary --eink-c9-sync-owner --eink-c9-blocked-call --eink-c10-bind-ladder --eink-c10-gpu-sync --eink-c10-blocked-op --eink-c10-fix-proof"
    ;;
  c11-probe)
    switches="--eink-c7-resource-task-lineage --eink-c8-dedup-state --eink-c8-current-task --eink-c8-blocking-task-trace --eink-c9-frame-sink-boundary --eink-c9-sync-owner --eink-c9-blocked-call --eink-c10-bind-ladder --eink-c10-gpu-sync --eink-c10-blocked-op --eink-c10-fix-proof --eink-c11-gles-limit-probe"
    ;;
  c11-sanitize)
    switches="--eink-c7-resource-task-lineage --eink-c8-dedup-state --eink-c8-current-task --eink-c8-blocking-task-trace --eink-c9-frame-sink-boundary --eink-c9-sync-owner --eink-c9-blocked-call --eink-c10-bind-ladder --eink-c10-gpu-sync --eink-c10-blocked-op --eink-c10-fix-proof --eink-c11-sanitize-attachment-limits"
    ;;
  cp2a-a)
    switches="--disable-gpu-compositing --eink-c7-resource-task-lineage --eink-c8-dedup-state --eink-c8-current-task --eink-c9-frame-sink-boundary --eink-c9-sync-owner --eink-c9-blocked-call --eink-c10-bind-ladder --eink-c10-gpu-sync --eink-c10-blocked-op"
    ;;
  cp2a-b)
    switches="--disable-gpu-compositing --disable-gpu-rasterization --disable-accelerated-2d-canvas --eink-c7-resource-task-lineage --eink-c8-dedup-state --eink-c8-current-task --eink-c9-frame-sink-boundary --eink-c9-sync-owner --eink-c9-blocked-call --eink-c10-bind-ladder --eink-c10-gpu-sync --eink-c10-blocked-op"
    ;;
  cp2a-c)
    switches="--disable-gpu --eink-c7-resource-task-lineage --eink-c8-dedup-state --eink-c8-current-task --eink-c9-frame-sink-boundary --eink-c9-sync-owner --eink-c9-blocked-call --eink-c10-bind-ladder --eink-c10-gpu-sync --eink-c10-blocked-op"
    ;;
  cp2a-d)
    switches="--disable-gpu-compositing --disable-3d-apis --eink-c7-resource-task-lineage --eink-c8-dedup-state --eink-c8-current-task --eink-c9-frame-sink-boundary --eink-c9-sync-owner --eink-c9-blocked-call --eink-c10-bind-ladder --eink-c10-gpu-sync --eink-c10-blocked-op"
    ;;
  cp2a-g)
    switches="--disable-gpu-compositing --eink-cp2a-creation-trace"
    ;;
  cp2a-h)
    switches="--disable-gpu-compositing --eink-cp2a-creation-trace --eink-cp2a-existing-software-sink"
    ;;
  cp2a-e)
    switches="--eink-cp2a-software-first --eink-cp2a-disable-auto-software --eink-cp2a-creation-trace"
    ;;
  cp2a-f1)
    switches="--eink-cp2a-creation-trace"
    ;;
  cp2a-f0)
    switches="--eink-cp2a-disable-auto-software --eink-cp2a-creation-trace"
    ;;
  *)
    echo "CP1C5_FAIL unknown_mode=$mode" >&2
    exit 2
    ;;
esac

{
  echo "mode=$mode"
  echo "serial=$serial"
  echo "activity=$activity"
  echo "url=$url"
  echo "switches=$switches"
  echo "software_view=$software_view"
  "$adb" -s "$serial" reverse tcp:8765 tcp:8765
  "$adb" -s "$serial" logcat -c
  if [[ -n "$switches" ]]; then
    "$adb" -s "$serial" shell am set-debug-app --persistent "$activity_package"
    "$adb" -s "$serial" shell "echo 'webview $switches' > $command_line_file"
    "$adb" -s "$serial" shell chmod 0664 "$command_line_file"
  else
    "$adb" -s "$serial" shell rm "$command_line_file" || true
    "$adb" -s "$serial" shell am clear-debug-app || true
  fi
  echo "device_command_line=$($adb -s "$serial" shell cat "$command_line_file" 2>/dev/null || true)"
  "$adb" -s "$serial" shell am force-stop "$activity_package"
  "$adb" -s "$serial" shell am start -W -n "$activity" -d "$url" \
      --ez cp05-software-view "$software_view"
  sleep 3
  "$adb" -s "$serial" exec-out screencap -p >"$shot_file"
  "$adb" -s "$serial" logcat -d -v threadtime
} >"$log_file" 2>&1

echo "CP1C5_RUN_OK mode=$mode log=$log_file screenshot=$shot_file"
for marker in \
  'C5_RESOURCE_RUNNER_SELECT' \
  'C5_RUNNER phase=init' \
  'C5_RUNNER_EXEC phase=init' \
  'C5_RUNNER phase=ready' \
  'C5_RUNNER_EXEC phase=ready' \
  'C6_RUNNER_IDENTITY' \
  'C6_RUNNER phase=init' \
  'C6_RUNNER_EXEC phase=init' \
  'C6_RUNNER phase=ready' \
  'C6_RUNNER_EXEC phase=ready' \
  'C6_SCHEDULER_BIND' \
  'C6_D ' \
  'IPC_RESOURCE_SCHED_POST type=1507605' \
  'IPC_RESOURCE_SCHED_EXECUTE type=1507605' \
  'C7_RESOURCE_POST' \
  'C7_TWIN_POST' \
  'C7_TWIN_EXECUTE' \
  'C7_LINEAGE_' \
  'C7_KICK_' \
  'C7_OFFTHREAD_' \
  'C7_ONTHREAD_' \
  'C8_' \
  'C9_' \
  'RD_MSG_ENTER' \
  'RD_ON_RESPONSE_ENTER' \
  'PAGE_FINISHED' \
  'JS_READY'; do
  count="$(rg -c "$marker" "$log_file" || true)"
  echo "marker=$(echo "$marker" | tr ' ' '_') count=$count"
done
