#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
engine="${GODOT_BIN:-godot}"
audio_run="$(mktemp -d)"
trap 'rm -rf "$audio_run"' EXIT
export XDG_DATA_HOME="$audio_run/data" XDG_CONFIG_HOME="$audio_run/config" XDG_CACHE_HOME="$audio_run/cache"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
timeout 60 "$engine" --path godot --rendering-method gl_compatibility --audio-driver Dummy \
  --script "$PWD/tools/validate_engine_audio.gd" 2>&1 | tee "$audio_run/audio.log"
rg -q '^PASS: [0-9]+ spatial engine audio assertions' "$audio_run/audio.log"
if rg -q '^SCRIPT ERROR:|^ERROR:' "$audio_run/audio.log"; then exit 1; fi
