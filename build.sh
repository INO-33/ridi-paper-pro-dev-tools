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
export RIDI_HOST_COMPAT="${RIDI_HOST_COMPAT:-$workspace/host-compat}"
export LD_LIBRARY_PATH="$RIDI_HOST_COMPAT/lib/x86_64-linux-gnu:$RIDI_HOST_COMPAT/usr/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export E70Q10_LUNCH="$product"
export E70Q10_OUT_DIR="${E70Q10_OUT_DIR:-$workspace/android-out/${product%-*}}"
export ANDROID_DATA="${ANDROID_DATA:-$E70Q10_OUT_DIR/.android-data}"
mkdir -p "$workspace/.orchestrator/logs" "$workspace/android-out" "$ANDROID_DATA"
log="$workspace/.orchestrator/logs/build-${product}-$(date +%Y%m%d-%H%M%S).log"
shift "$(( $# > 0 ? 1 : 0 ))"
(( $# == 0 )) || shift
if [[ "$mode" == build && $# == 0 ]]; then set -- droid; fi
if [[ "$mode" == build && ( "$product" == e70q10_reference-eng || "$product" == e70q10_minimal-eng ) ]]; then
    for target in "$@"; do
        case "$target" in
            bootimage|systemimage|vendorimage|droid)
                if [[ -z "${E70Q10_WIFI_MODULE:-}" || ! -f "$E70Q10_WIFI_MODULE" ]]; then
                    echo 'Build kernelimage first, run build-wifi.py, then export E70Q10_WIFI_MODULE to the generated .ko; see DEVELOPMENT.md' >&2
                    exit 2
                fi
                release_file="$E70Q10_OUT_DIR/target/product/e70q10/obj/KERNEL_OBJ/include/config/kernel.release"
                if [[ -f "$release_file" ]]; then
                    release="$(cat "$release_file")"
                    strings "$E70Q10_WIFI_MODULE" | grep -F "vermagic=$release " >/dev/null || {
                        echo 'Wi-Fi module does not match the selected kernel output; rebuild it with build-wifi.py' >&2
                        exit 2
                    }
                fi
                ;;
        esac
    done
fi
manifest_tools="${RIDI_MANIFEST_DIR:-$source_tree/.repo/manifests}"
if (
    python3 "$manifest_tools/check-host.py" android "$workspace" \
        --min-free-gb "${E70Q10_MIN_FREE_GB:-25}" \
        --json "$workspace/.orchestrator/logs/host-android.json" || exit $?
    "$source_tree/device/ridi/e70q10/tools/build_android8.sh" "$mode" "$@"
) >"$log" 2>&1; then
    echo "${mode} completed for ${product}; log: ${log}"
else
    echo "${mode} failed for ${product}; log: ${log}" >&2
    tail -15 "$log" >&2
    exit 1
fi
