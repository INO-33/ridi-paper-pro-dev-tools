#!/usr/bin/env bash
set -euo pipefail

source_root="${CHROMIUM_SRC_ROOT:-/work/src}"
depot_tools_root="${DEPOT_TOOLS_ROOT:-/work/depot_tools}"
out_dir="${M58_OUT_DIR:-$source_root/out/m58_xenial_x86}"
log_dir="${M58_LOG_DIR:-/work/logs}"
expected_commit="c254b52f7661657df3d56ff997030fc36988c9cd"

mkdir -p "$log_dir"
stamp="$(date +%Y%m%d-%H%M%S)"
log_file="$log_dir/chromium-m58-xenial-${stamp}.log"
exec > >(tee "$log_file") 2>&1

echo "container=chromium-m58-build"
echo "source_root=$source_root"
echo "depot_tools_root=$depot_tools_root"
echo "out_dir=$out_dir"

test -d "$source_root/.git"
test -d "$depot_tools_root"
test -x "$source_root/buildtools/linux64/gn"
test -x "$(command -v ninja)"

actual_commit="$(git -C "$source_root" rev-parse HEAD)"
if [[ "$actual_commit" != "$expected_commit" ]]; then
  echo "ERROR: source commit mismatch: expected=$expected_commit actual=$actual_commit" >&2
  exit 2
fi

if [[ -n "$(git -C "$source_root" status --porcelain)" ]]; then
  if [[ "${M58_ALLOW_DIRTY_SOURCE:-0}" != "1" ]]; then
    echo "ERROR: source checkout is not clean" >&2
    git -C "$source_root" status --short >&2
    exit 2
  fi
  echo "source_status=dirty_allowed_for_checkpoint"
  git -C "$source_root" status --short
else
  echo "source_status=clean"
fi

echo "python=$(python --version 2>&1)"
echo "java=$(java -version 2>&1 | head -1)"
echo "javac=$(javac -version 2>&1)"
echo "bison=$(bison --version | head -1)"

# Re-run the exact M58 dependency script in check-only mode against the
# bind-mounted checkout. This validates the image package set without apt or
# source/dependency downloads at container runtime.
set +e
deps_check_output="$("$source_root/build/install-build-deps.sh" \
  --quick-check --no-syms --lib32 --no-arm --no-nacl --no-chromeos-fonts 2>&1)"
deps_check_status=$?
set -e
printf '%s\n' "$deps_check_output"
if [[ "$deps_check_status" -ne 0 ]]; then
  optional_missing="$(printf '%s\n' "$deps_check_output" | sed -n '/^  /p' | sed 's/^  //' | grep -v '^appmenu-gtk$' || true)"
  if [[ -n "$optional_missing" ]]; then
    echo "ERROR: M58 dependency check has unexpected missing packages" >&2
    exit 2
  fi
  echo "dependency_check=PASS optional_unavailable=appmenu-gtk"
fi

for package in ant bsdiff lighttpd libncurses5:i386 libstdc++6:i386 python-pexpect xvfb x11-utils; do
  dpkg-query -W -f='${Status}\n' "$package" | grep -F 'install ok installed' >/dev/null
done

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export PATH="$JAVA_HOME/bin:/usr/bin:/bin"

android_version_code="${M58_ANDROID_VERSION_CODE:-303012510}"
android_version_name="${M58_ANDROID_VERSION_NAME:-58.0.3029.125}"
target_cpu="${M58_TARGET_CPU:-x86}"
args="target_os=\"android\" target_cpu=\"$target_cpu\" is_debug=false is_component_build=false android_default_version_code=\"$android_version_code\" android_default_version_name=\"$android_version_name\""
gn="$source_root/buildtools/linux64/gn"

echo "target_cpu=$target_cpu"
echo "gn gen: $args"
"$gn" gen "$out_dir" --args="$args"
echo "ninja target=system_webview_apk"
ninja -C "$out_dir" system_webview_apk

apk="$(find "$out_dir" -type f -name '*.apk' -print | sort | head -1)"
if [[ -z "$apk" ]]; then
  echo "ERROR: build completed without an APK" >&2
  exit 3
fi

echo "BUILD_OK target=system_webview_apk apk=$apk"
sha256sum "$apk"
