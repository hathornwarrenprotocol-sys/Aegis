#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/lib/common.sh"
cmd="${1:-status}"; shift || true
PHYS="$ROOT/var/smith"; mkdir -p "$PHYS" "$ROOT/smith/sim" "$ROOT/smith/probe" "$ROOT/smith/mcu"
stage_file="$PHYS/stage"; [[ -f "$stage_file" ]] || echo 0 > "$stage_file"
stage="$(tr -d ' \n' < "$stage_file")"
status() { echo "smith.stage=$stage"; echo "forge_class=$(cat "$PHYS/forge_class" 2>/dev/null || echo none)"; echo "device=$(cat "$PHYS/device" 2>/dev/null || echo none)"; }
probe() {
  local dev=none class=none
  for cand in /dev/ttyACM0 /dev/ttyUSB0; do [[ -e "$cand" ]] && { dev="$cand"; class=mcu; break; }; done
  echo "$dev" > "$PHYS/device"; echo "$class" > "$PHYS/forge_class"
  printf 'forge_class=%s\ndevice=%s\nhost=%s\nnote=rented-disk-is-not-a-puf\nts=%s\n' "$class" "$dev" "$(hostname)" "$(now)" > "$PHYS/probe.receipt"
  echo "forge_class=${class} device=${dev}"
}
next() {
  case "$stage" in
    0) cat > "$ROOT/smith/sim/pbit_sim.py" << 'PY'
#!/usr/bin/env python3
import hashlib, json, random, sys
n = int(sys.argv[1]) if len(sys.argv) > 1 else 16
seed = sys.argv[2] if len(sys.argv) > 2 else "aegis"
rng = random.Random(int(hashlib.sha256(seed.encode()).hexdigest()[:8], 16))
print(json.dumps({"n": n, "seed": seed, "state": [rng.choice([0,1]) for _ in range(n)], "forge_class": "software"}))
PY
      echo 1 > "$stage_file"; echo "stage 0->1: software sampler sim written" ;;
    1) cat > "$ROOT/smith/probe/detect.sh" << 'SH'
#!/usr/bin/env bash
set -euo pipefail
for cand in /dev/ttyACM0 /dev/ttyUSB0; do [[ -e "$cand" ]] && { echo present "$cand"; exit 0; }; done
echo absent; exit 0
SH
      chmod +x "$ROOT/smith/probe/detect.sh"; echo 2 > "$stage_file"; echo "stage 1->2: device probe written" ;;
    2) echo "MCU sidecar: sign receipts on metal beside this box. Do not invent a PUF on DigitalOcean." > "$ROOT/smith/mcu/README.md"
      echo 3 > "$stage_file"; echo "stage 2->3: MCU sidecar notes written" ;;
    *) echo "stage=$stage — further physics needs metal." ;;
  esac
}
case "$cmd" in status) status ;; probe) probe ;; next) next ;; *) echo "usage: smith status|probe|next" >&2; exit 2 ;; esac
