#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"

C_HELPER="${C_HELPER:-$SCRIPT_DIR/json_helper}"
VARIANT_HELPER="${VARIANT_HELPER:-$SCRIPT_DIR/json_helper.sh}"
VARIANT="${VARIANT:-}"
CACHE_DIR="${CACHE_DIR:-/tmp/opkg-manager}"
ITERATIONS="${ITERATIONS:-500}"
OUT_BASE="${OUT_BASE:-$CACHE_DIR/benchmarks}"
RUN_ID="$(date +%Y%m%d-%H%M%S)"
OUT_DIR="$OUT_BASE/$RUN_ID"

usage() {
  cat <<EOF
Usage: $(basename "$0") [iterations]

Environment overrides:
  C_HELPER     Path to C helper binary (default: ./json_helper)
  VARIANT_HELPER  Path to the helper script (default: ./json_helper.sh)
  VARIANT      The exe to run (bash, python) (default: bash)
  CACHE_DIR    Cache directory (default: /tmp/opkg-manager)
  OUT_BASE     Output base directory (default: /tmp/opkg-manager/benchmarks)
  ITERATIONS   Benchmark loop count (default: 500)

Outputs:
  $OUT_BASE/<timestamp>/feeds.c.json
  $OUT_BASE/<timestamp>/feeds.$VARIANT.json
  $OUT_BASE/<timestamp>/packages.c.json
  $OUT_BASE/<timestamp>/packages.$VARIANT.json
  $OUT_BASE/<timestamp>/summary.txt
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ -n "${1:-}" ]]; then
  ITERATIONS="$1"
fi

if ! [[ "$ITERATIONS" =~ ^[0-9]+$ ]] || [[ "$ITERATIONS" -lt 1 ]]; then
  echo "ITERATIONS must be a positive integer" >&2
  exit 1
fi

if [[ ! -x "$C_HELPER" ]]; then
  echo "C helper not executable: $C_HELPER" >&2
  exit 1
fi

if [[ ! -f "$VARIANT_HELPER" ]]; then
  echo "Variant helper not found: $VARIANT_HELPER" >&2
  exit 1
fi

mkdir -p "$CACHE_DIR" "$OUT_DIR"

supports_ns=1
if [[ "$(date +%s%N 2>/dev/null || true)" == *N ]]; then
  supports_ns=0
fi

now_ns() {
  if (( supports_ns )); then
    date +%s%N
  else
    echo "$(( $(date +%s) * 1000000000 ))"
  fi
}

fmt_ns() {
  local ns="$1"
  local sec=$(( ns / 1000000000 ))
  local ms=$(( (ns % 1000000000) / 1000000 ))
  printf '%d.%03ds' "$sec" "$ms"
}

bench_cmd() {
  local iterations="$1"
  shift

  local start end elapsed i
  start="$(now_ns)"
  for (( i=0; i<iterations; i++ )); do
    "$@" >/dev/null 2>&1
  done
  end="$(now_ns)"
  elapsed=$(( end - start ))
  echo "$elapsed"
}

copy_cache_json() {
  local src_name="$1"
  local dst_name="$2"
  local src="$CACHE_DIR/$src_name"
  local dst="$OUT_DIR/$dst_name"

  if [[ -f "$src" ]]; then
    cp "$src" "$dst"
  else
    echo "Missing expected cache file: $src" >&2
    exit 1
  fi
}

run_and_capture() {
  local variant="$1"
  local family="$2"
  shift 2

  "$@" "$family" list >/dev/null 2>&1
  copy_cache_json "${family}s.json" "${family}s.${variant}.json"
}

echo "Running feed list and capturing JSON outputs..."
run_and_capture c feed "$C_HELPER"
run_and_capture $VARIANT feed $VARIANT "$VARIANT_HELPER"

echo "Running package list and capturing JSON outputs..."
run_and_capture c package "$C_HELPER"
run_and_capture $VARIANT package $VARIANT "$VARIANT_HELPER"

echo "Benchmarking package list for $ITERATIONS iterations..."
c_ns="$(bench_cmd "$ITERATIONS" "$C_HELPER" package list)"
variant_ns="$(bench_cmd "$ITERATIONS" $VARIANT "$VARIANT_HELPER" package list)"

c_avg_ns=$(( c_ns / ITERATIONS ))
variant_avg_ns=$(( variant_ns / ITERATIONS ))

ratio_x1000=0
if [[ "$c_avg_ns" -gt 0 ]]; then
  ratio_x1000=$(( (variant_avg_ns * 1000) / c_avg_ns ))
fi

ratio_int=$(( ratio_x1000 / 1000 ))
ratio_frac=$(( ratio_x1000 % 1000 ))

feeds_same=0
packages_same=0
if cmp -s "$OUT_DIR/feeds.c.json" "$OUT_DIR/feeds.$VARIANT.json"; then
  feeds_same=1
fi
if cmp -s "$OUT_DIR/packages.c.json" "$OUT_DIR/packages.$VARIANT.json"; then
  packages_same=1
fi

summary="$OUT_DIR/summary.txt"
{
  echo "json_helper benchmark"
  echo "run_id: $RUN_ID"
  echo "Variant: $VARIANT"
  echo "script_dir: $SCRIPT_DIR"
  echo "cache_dir: $CACHE_DIR"
  echo "iterations: $ITERATIONS"
  echo
  echo "outputs:"
  echo "  $OUT_DIR/feeds.c.json"
  echo "  $OUT_DIR/feeds.$VARIANT.json"
  echo "  $OUT_DIR/packages.c.json"
  echo "  $OUT_DIR/packages.$VARIANT.json"
  echo
  echo "package list timing:"
  echo "  C total:    $(fmt_ns "$c_ns")"
  echo "  $VARIANT total: $(fmt_ns "$variant_ns")"
  echo "  C avg:      $(fmt_ns "$c_avg_ns")"
  echo "  $VARIANT avg:   $(fmt_ns "$variant_avg_ns")"
  printf '  ratio:      %d.%03dx ($VARIANT/C)\n' "$ratio_int" "$ratio_frac"
  echo
  echo "json equality:"
  echo "  feeds:    $([[ "$feeds_same" -eq 1 ]] && echo same || echo different)"
  echo "  packages: $([[ "$packages_same" -eq 1 ]] && echo same || echo different)"
} >"$summary"

echo
echo "Done."
echo "Summary: $summary"
echo "Output directory: $OUT_DIR"
