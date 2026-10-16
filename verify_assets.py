#!/usr/bin/env python3
"""Read-only verification of the preserved Android/WebView build inputs."""
import hashlib
from pathlib import Path
import subprocess
root = Path(__file__).resolve().parent
for line in (root / 'EXPORTED_SHA256SUMS').read_text().splitlines():
    digest, relative = line.split('  ', 1)
    if hashlib.sha256((root / relative).read_bytes()).hexdigest() != digest:
        raise SystemExit('Asset mismatch: ' + relative)
jdk = root / 'host-tools/jdk8-local/usr/lib/jvm/java-8-openjdk-amd64'
for name in ['java', 'javac']:
    result = subprocess.run([str(jdk / 'bin' / name), '-version'], capture_output=True, text=True)
    if result.returncode:
        raise SystemExit('Java runtime requires host libraries: ' + result.stderr)
print('Android/WebView build inputs and Java executables verified')
