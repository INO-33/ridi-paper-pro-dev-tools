# RIDI PAPER PRO · 개발 보조 도구

Android 8과 Chromium M58의 호스트 환경·빌드 래퍼를 관리합니다.
**[메인 manifest 저장소](https://github.com/INO-33/ridi-paper-pro)**가 전체 소스
조합을 고정합니다. SD/eMMC CLI·GUI와 Windows 배포 빌더는 별도
**[SD 도구 저장소](https://github.com/INO-33/ridi-paper-pro-sd-tools)**에서 관리합니다.

## 구성

| 경로 | 역할 |
|---|---|
| `build.sh` | Android 환경 검사와 제품 빌드, 로그 저장 |
| `host-tools/` | Java 8 JDK/JRE, Python 2 래퍼, 플랫폼 도구 |
| `tools/chromium-m58-build/` | ARM/x86 WebView 빌드 스크립트와 Dockerfile |
| `tools/eink_webview/` | 기존 WebView 진단·빌드 보조 스크립트 |
| `host-environment.json` | 원래 호스트 OS·패키지·depot_tools 버전 기록 |
| `EXPORTED_SHA256SUMS`, `verify_assets.py` | 보존 파일 해시와 Java 실행 검사 |

## 사용

메인 저장소의 `prepare.sh`로 소스를 받은 뒤:

```sh
source /absolute/path/to/ridi-workspace/env.sh
"$ANDROID_BUILD_TOP/ridi-build-support/build.sh" check e70q10_reference-eng
"$ANDROID_BUILD_TOP/ridi-build-support/build.sh" build e70q10_reference-eng bootimage systemimage vendorimage
python3 "$ANDROID_BUILD_TOP/ridi-build-support/verify_assets.py"
```

`RIDI_WORKSPACE`, `ANDROID_BUILD_TOP`으로 작업 경로를 전달합니다.
`E70Q10_OUT_DIR`은 출력 경로, `E70Q10_BUILD_JOBS`는 병렬 빌드 수입니다.
Java 8 런타임은 원래 PC의 외부 JRE 링크에 의존하지 않도록 파일 자체를
보존했습니다. 호스트 기본 패키지는 별도 준비가 필요합니다.

WebView 소스 준비와 빌드는
[Chromium README](https://github.com/INO-33/ridi-paper-pro-webview)를 따릅니다.
로그는 작업 폴더의 `.orchestrator/logs/`에 저장합니다. 일부 과거 진단 스크립트는
원래 빌드 출력 경로를 기본값으로 사용하므로 환경 변수/인자를 확인합니다.

체크포인트: **2026-10-16**. 소스·필수 호스트 자산을 보존하는 체크포인트이며,
새 환경의 전체 Android/Chromium 빌드 검증은 별도입니다. 전체 제품 상태와
기기별 검증 범위는 메인 README를 확인하세요.
