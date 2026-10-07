# RIDI Android 8 build support

Private source checkpoint dated 2026-10-07. Pair this repository with
INO-33/RIDI_ANDROID8_MANIFEST; its lock file pins the exact support commit.

Contains Android host wrappers, a materialized Java 8 JDK/JRE, platform tools,
Chromium M58 build scripts and Dockerfile, and updater producer source/assets.
No build outputs, disk backups, user data, credentials or signing secrets are
intentionally included. Preserve individual upstream notices and licenses.

The manifest's prepare script creates the workspace layout and supplies
RIDI_WORKSPACE/ANDROID_BUILD_TOP. Use build.sh to select a product explicitly.
The producer scripts here are exported copies; the active BSP was not edited.
The historical initial installer still references the original backup and
deliverables and is retained for reference. Use the self-contained updater.

This is source preservation, not a certified clean-environment release.
Ubuntu 24.04 host package inventory is recorded in host-environment.json.
Java and Python are preserved, but host libraries/packages still need setup.
The Chromium Dockerfile's apt repositories/base image are not fully mirrored.
No fresh Android/Chromium build or physical validation was run for this export.
