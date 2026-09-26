#!/usr/bin/env bash
# Wright — builds the software plane in place. Never seals the book.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
AEGIS="$ROOT/bin/aegis"
cmd="${1:-status}"

status() {
  echo "root=$ROOT"
  echo -n "wrappers="
  w=""
  [[ -e $ROOT/bin/cite.sh ]] && w="${w}cite"
  [[ -e $ROOT/bin/eval.sh ]] && w="${w}+eval"
  [[ -L /root/aegis.sh ]] && w="${w}+aegis.sh"
  [[ -L /root/smith.sh ]] && w="${w}+smith.sh"
  echo "${w:-none}"
  echo -n "verbs="; grep -E 'intent|draw|eval|read|seal|verify|status' "$AEGIS" | grep -E '^\s+\w+\)' | tr -d ' )' | xargs
  echo "forge_class=$(grep -E '^forge_class=' "$ROOT/var/book/book.txt" | tail -1 | cut -d= -f2)"
}

strip() {
  rm -f "$ROOT/bin/cite.sh" "$ROOT/bin/eval.sh" /root/aegis.sh /root/smith.sh
  echo "stripped wrappers"
}

ensure_verbs() {
  python3 - "$AEGIS" << 'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
t = p.read_text()
if "read_cmd()" in t and "verify_cmd()" in t:
    print("verbs present")
    raise SystemExit(0)
read_fn = r'''
read_cmd() {
  local ipath id dir n
  ipath="$(latest_intent "$ROOT")"
  [[ -n "$ipath" ]] || { echo "no intent" >&2; exit 2; }
  id="$(intent_id_from_path "$ipath")"
  dir="$ROOT/var/draft/${id}"
  n=""
  shopt -s nullglob
  files=("$dir"/*.txt)
  shopt -u nullglob
  for f in "${files[@]}"; do [[ -f "$f" ]] || continue; n="$(basename "$f" .txt)"; done
  [[ -n "$n" ]] || { echo "no draft" >&2; exit 2; }
  echo "=== draft $id#$n ==="
  cat "$dir/${n}.txt"
  echo "=== receipt ==="
  cat "$dir/${n}.receipt"
  if [[ -f "$ROOT/var/eval/${id}/${n}.score" ]]; then
    echo "=== score ==="
    cat "$ROOT/var/eval/${id}/${n}.score"
  fi
}

verify_cmd() {
  local ipath id n out draft sc d s od os
  ipath="$(latest_intent "$ROOT")"
  [[ -n "$ipath" ]] || { echo "no intent" >&2; exit 2; }
  id="$(intent_id_from_path "$ipath")"
  out="$ROOT/var/out/${id}"
  [[ -f "$out" ]] || { echo "no out receipt — not sealed" >&2; exit 2; }
  n="$(awk -F= '/^n=/{print $2}' "$out")"
  draft="$ROOT/var/draft/${id}/${n}.txt"
  sc="$ROOT/var/eval/${id}/${n}.score"
  d="$(sha < "$draft")"
  s="$(sha < "$sc")"
  od="$(awk -F= '/^draft_sha256=/{print $2}' "$out")"
  os="$(awk -F= '/^score_sha256=/{print $2}' "$out")"
  if [[ "$d" == "$od" && "$s" == "$os" ]]; then
    echo "verify ok intent=$id n=$n"
  else
    echo "verify FAIL intent=$id" >&2
    exit 3
  fi
}

'''
if "status_cmd()" not in t:
    raise SystemExit("bin/aegis unexpected")
t = t.replace("status_cmd()", read_fn + "status_cmd()", 1)
t = t.replace(
    'status) status_cmd "$@" ;;',
    'read) read_cmd "$@" ;;\n  verify) verify_cmd "$@" ;;\n  status) status_cmd "$@" ;;',
    1,
)
t = t.replace(
    'echo "usage: aegis intent|draw|eval|seal|status"',
    'echo "usage: aegis intent|draw|eval|read|seal|verify|status"',
    1,
)
old = '''    body="$(ollama run "$model" "Draft a short, reversible change proposal for: $(tail -n +2 "$ipath")" 2>/dev/null || true)"'''
new = '''    if [[ "${AEGIS_SAMPLER:-ollama}" == sim ]]; then
      body="$(python3 "$ROOT/smith/sim/pbit_sim.py" 16 "$id" 2>/dev/null || true)"
      model="software:sim"
    else
      body="$(ollama run "$model" "Draft a short, reversible change proposal for: $(tail -n +2 "$ipath")" 2>/dev/null || true)"
    fi'''
if old in t:
    t = t.replace(old, new, 1)
p.write_text(t)
print("patched verbs read verify + optional AEGIS_SAMPLER=sim")
PY
}

case "$cmd" in
  status) status ;;
  strip)  strip ;;
  next)   strip; ensure_verbs; status ;;
  *) echo "usage: wright status|strip|next" >&2; exit 2 ;;
esac
