#!/usr/bin/env python3
"""Read-only validation of preserved producer assets and Java/Python inputs."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parent
for line in (root / 'EXPORTED_SHA256SUMS').read_text().splitlines():
    digest, relative = line.split('  ', 1)
    file = root / relative
    if hashlib.sha256(file.read_bytes()).hexdigest() != digest:
        raise SystemExit('Asset mismatch: ' + relative)
sys.path.insert(0, str(root / 'porting/e70q10/emmc-updater'))
from runtime_assets import verify_assets
verify_assets(root / 'porting/e70q10/emmc-updater/assets')
jdk = root / 'host-tools/jdk8-local/usr/lib/jvm/java-8-openjdk-amd64'
for executable in ['java', 'javac']:
    result = subprocess.run([str(jdk / 'bin' / executable), '-version'],
                            capture_output=True, text=True)
    if result.returncode:
        raise SystemExit('Preserved Java runtime requires host libraries: ' + result.stderr)
print('Preserved support assets, updater hashes, and Java executables verified')
