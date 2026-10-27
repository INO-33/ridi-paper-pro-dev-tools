# RIDI PAPER PRO · 개발 보조 도구

Android 8과 Chromium M58의 호스트 환경·빌드 래퍼를 관리합니다.
**[메인 manifest 저장소](https://github.com/INO-33/ridi-paper-pro)**가 전체 소스
조합을 고정합니다. SD/eMMC CLI·GUI와 Windows 배포 빌더는 별도
**[SD 도구 저장소](https://github.com/INO-33/ridi-paper-pro-sd-tools)**에서 관리합니다.

## 구성

| 경로 | 역할 |
|---|---|
| `build-wifi.py` | 빌드한 제품 커널에 대응하는 GPL Wi-Fi 모듈 생성 |
| `build.sh` | Android 환경 검사와 제품 빌드, 로그 저장 |
| `host-tools/` | Java 8 JDK/JRE, Python 2 래퍼, 플랫폼 도구 |
| `tools/chromium-m58-build/` | ARM/x86 WebView 빌드 스크립트와 Dockerfile |
| `tools/eink_webview/` | 기존 WebView 진단·빌드 보조 스크립트 |
| `host-environment.json` | 호스트 OS·depot_tools 버전 기록 (전체 PC 패키지 목록 제외) |
| `EXPORTED_SHA256SUMS`, `verify_assets.py` | 보존 파일 해시와 Java 실행 검사 |

## 사용

처음 구성할 때에는 메인 저장소의 [DEVELOPMENT.md](https://github.com/INO-33/ridi-paper-pro/blob/checkpoint-20261016/DEVELOPMENT.md)를
따라 `setup-host.py`로 호스트 패키지를 설치하고 `check-host.py`로 검사합니다.
전체 PC 패키지 기록을 설치 목록으로 사용하지 않습니다.

메인 저장소의 `prepare.sh`로 소스를 받은 뒤:

```sh
source /absolute/path/to/ridi-workspace/env.sh
"$ANDROID_BUILD_TOP/ridi-build-support/build.sh" check e70q10_reference-eng
"$ANDROID_BUILD_TOP/ridi-build-support/build.sh" build e70q10_reference-eng kernelimage
python3 "$ANDROID_BUILD_TOP/ridi-build-support/build-wifi.py" --check
python3 "$ANDROID_BUILD_TOP/ridi-build-support/build-wifi.py"
export E70Q10_WIFI_MODULE="${E70Q10_OUT_DIR:-$RIDI_WORKSPACE/android-out/e70q10_reference}/wifi/8189fs.ko"
"$ANDROID_BUILD_TOP/ridi-build-support/build.sh" build e70q10_reference-eng bootimage systemimage vendorimage
python3 "$ANDROID_BUILD_TOP/ridi-build-support/verify_assets.py"
```

`RIDI_WORKSPACE`, `ANDROID_BUILD_TOP`으로 작업 경로를 전달합니다.
`E70Q10_OUT_DIR`은 출력 경로, `E70Q10_BUILD_JOBS`는 병렬 빌드 수입니다.
Java 8 런타임은 원래 PC의 외부 JRE 링크에 의존하지 않도록 파일 자체를
보존했습니다. 호스트 기본 패키지는 메인 저장소의 `host-packages.json`과 설치기로 준비합니다.

WebView 소스 준비와 빌드는
[Chromium README](https://github.com/INO-33/ridi-paper-pro-webview)를 따릅니다.
로그는 작업 폴더의 `.orchestrator/logs/`에 저장합니다. 일부 과거 진단 스크립트는
원래 빌드 출력 경로를 기본값으로 사용하므로 환경 변수/인자를 확인합니다.
주 개발 경로인 Android 및 M58 ARM/x86 빌더는 복원된 작업 폴더 경로를 사용합니다.

체크포인트: **2026-10-27**. 소스·필수 호스트 자산을 보존하는 체크포인트이며,
새 환경의 전체 Android/Chromium 빌드 검증은 별도입니다. 전체 제품 상태와
기기별 검증 범위는 메인 README를 확인하세요.


## 사용 대상과 라이선스

기존 **리디 페이퍼 프로 사용자**를 위한 프로젝트입니다. 새 자체 앱·보조 코드는
Apache 2.0이며 기존 파일은 원래 라이선스를 유지합니다. 기기 유래 파일에는 재사용
허락을 부여하지 않으며 타 기기 포팅에서는 해당 자료를 제외합니다.
[LICENSING.md](LICENSING.md), [DEVICE_ASSETS.md](DEVICE_ASSETS.md)를 확인하세요.
