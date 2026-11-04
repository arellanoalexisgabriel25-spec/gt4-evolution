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
timeout 60 "$engine" --path godot --rendering-method gl_compatibility --audio-driver Dummy \
  --script "$PWD/tools/capture_presentation.gd" -- "$output" 2>&1 | tee "$capture_data/render.log"
if rg -q '^SCRIPT ERROR:|^ERROR:' "$capture_data/render.log"; then exit 1; fi
for shot in 01-home 02-dealer 03-garage 04-settings 05-camera-0 06-camera-1 07-camera-2 08-camera-3 09-look-back 10-race-grid 11-drag-staging 12-drag-tree 13-drag-driving 14-drag-close 15-drag-ticket 16-drag-red-light 17-controller-pause 18-147-showroom 19-uno-showroom 20-gol-showroom 21-tire-workshop 22-gol-staging 23-impact-damage 24-gol-driving 25-duel-staging 26-duel-driving 27-duel-result; do
  rg -q "^Captured $shot " "$capture_data/render.log"
  test -s "$output/$shot.png"
done
