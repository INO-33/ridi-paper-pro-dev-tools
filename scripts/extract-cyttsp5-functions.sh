#!/bin/sh
set -eu

ROOT=${1:-$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)}
KALLSYMS=${KALLSYMS:-$ROOT/ridi-paper-pro-stock-4.4.2-20260721/runtime-hardware/proc-kallsyms-addresses.txt}
IMAGE=${IMAGE:-$ROOT/ridi-paper-pro-stock-4.4.2-20260721/kernel-analysis/Image}
OUTDIR=${OUTDIR:-$ROOT/analysis/extracted-cyttsp5}

BASE=0xc0008000

pick_objdump() {
    if [ -x "$ROOT/host-tools/arm-linux-androideabi-4.9-bin/arm-linux-androideabi-objdump" ]; then
        printf '%s\n' "$ROOT/host-tools/arm-linux-androideabi-4.9-bin/arm-linux-androideabi-objdump"
        return 0
    fi
    if command -v arm-linux-androideabi-objdump >/dev/null 2>&1; then
        command -v arm-linux-androideabi-objdump
        return 0
    fi
    command -v objdump
}

OBJDUMP=$(pick_objdump)
mkdir -p "$OUTDIR"

symbols=${*:-cyttsp5_read_input cyttsp5_get_hid_descriptor_ cyttsp5_hid_send_output_and_wait_ cyttsp5_parse_input cyttsp5_irq cyttsp5_startup cyttsp5_watchdog_work cyttsp5_xres cyttsp5_i2c_read_default_nosize cyttsp5_i2c_read_default cyttsp5_i2c_write_read_specific cyttsp5_hid_output_start_bootloader_ cyttsp5_hid_output_bl_launch_app_ cyttsp5_hid_output_bl_get_panel_id_ cyttsp5_hid_output_get_sysinfo_}

printf 'symbol,address,file_offset,size,mode,objdump_path,strings_path\n' > "$OUTDIR/address-map.csv"

for sym in $symbols; do
    meta=$(python3 - "$KALLSYMS" "$sym" "$BASE" <<'PY'
import sys

kallsyms_path = sys.argv[1]
symbol = sys.argv[2]
base = int(sys.argv[3], 16)

entries = []
with open(kallsyms_path, 'r', encoding='utf-8') as handle:
    for line in handle:
        parts = line.strip().split()
        if len(parts) < 3:
            continue
        addr_text, kind, name = parts[0], parts[1], parts[2]
        if kind not in {'t', 'T'}:
            continue
        try:
            addr = int(addr_text, 16)
        except ValueError:
            continue
        entries.append((addr, name))

entries.sort()
for index, (addr, name) in enumerate(entries):
    if name != symbol:
        continue
    next_addr = entries[index + 1][0] if index + 1 < len(entries) else None
    size = next_addr - addr if next_addr is not None else None
    offset = addr - base
    print(f"{addr:#x} {offset:#x} {size if size is not None else 'unknown'}")
    break
PY
)
    [ -n "$meta" ] || continue

    set -- $meta
    addr=$1
    offset=$2
    size=$3

    binfile="$OUTDIR/$sym.bin"
    dumpfile="$OUTDIR/$sym.objdump.txt"
    strfile="$OUTDIR/$sym.strings.txt"

    if [ "$size" != unknown ]; then
        dd if="$IMAGE" of="$binfile" bs=1 skip=$((addr - BASE)) count=$size status=none
    fi

    if [ -f "$binfile" ]; then
        "$OBJDUMP" -D -b binary -m arm --adjust-vma=$((addr - BASE)) "$binfile" > "$dumpfile" 2>/dev/null || true
        strings -a -t x "$binfile" > "$strfile" 2>/dev/null || true
    fi

    printf '%s,%s,%s,%s,ARM,%s,%s\n' "$sym" "$addr" "$offset" "$size" "$dumpfile" "$strfile" >> "$OUTDIR/address-map.csv"
done

echo "wrote $OUTDIR/address-map.csv"
