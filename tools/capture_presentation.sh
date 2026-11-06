#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
engine="${GODOT_BIN:-godot}"
output="${1:?Provide an absolute screenshot output directory}"
if [[ "$output" != /* ]]; then
  echo 'Screenshot directory must be absolute.' >&2
  exit 1
fi
capture_data="$(mktemp -d)"
trap 'rm -rf "$capture_data"' EXIT
export XDG_DATA_HOME="$capture_data/data"
export XDG_CONFIG_HOME="$capture_data/config"
export XDG_CACHE_HOME="$capture_data/cache"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$output"
timeout 420 "$engine" --path godot --rendering-method gl_compatibility --audio-driver Dummy \
  --script "$PWD/tools/capture_presentation.gd" -- "$output" 2>&1 | tee "$capture_data/render.log"
if rg -q '^SCRIPT ERROR:|^ERROR:' "$capture_data/render.log"; then exit 1; fi
while IFS= read -r shot; do
  rg -q "^Captured $shot " "$capture_data/render.log"
  test -s "$output/$shot.png"
done < tools/presentation_shots.txt
