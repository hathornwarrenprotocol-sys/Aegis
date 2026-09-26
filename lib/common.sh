now() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }
sha() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum | awk '{print $1}'
  else shasum -a 256 | awk '{print $1}'; fi
}
latest_intent() { ls -1t "$1/var/intent"/*.txt 2>/dev/null | head -1 || true; }
intent_id_from_path() { basename "$1" .txt; }
append_tsv() { printf "%s\t%s\t%s\t%s\n" "$(now)" "$2" "$3" "$4" >> "$1/var/book/state.tsv"; }

load_budgets() {
  local f="$1/etc/budgets"
  MAX_DRAFTS_PER_INTENT=5
  MAX_DRAFT_BYTES=200000
  ALLOW_SEAL_WITHOUT_DRAW=0
  [[ -f "$f" ]] || return 0
  source "$f"
}
latest_n() {
  local dir="$1" n="" f
  shopt -s nullglob
  local files=("$dir"/*.txt)
  shopt -u nullglob
  for f in "${files[@]}"; do
    [[ -f "$f" ]] || continue
    n="$(basename "$f" .txt)"
  done
  echo "$n"
}
intent_tokens() {
  tail -n +2 "$1" | tr -c 'A-Za-z0-9' ' ' | tr ' ' '\n' | awk 'length>3' | sort -u
}
