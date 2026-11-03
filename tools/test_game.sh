#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
engine="${GODOT_BIN:-godot}"
log_dir="$(mktemp -d)"
trap 'rm -rf "$log_dir"' EXIT
# Tests never read or overwrite a player's real user:// save directory.
export XDG_DATA_HOME="$log_dir/data"
export XDG_CONFIG_HOME="$log_dir/config"
export XDG_CACHE_HOME="$log_dir/cache"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
timeout 90 "$engine" --headless --path godot --editor --import 2>&1 | tee "$log_dir/import.log"
if rg -q '^SCRIPT ERROR:|^ERROR:' "$log_dir/import.log"; then exit 1; fi
timeout 30 "$engine" --headless --path godot --script "$PWD/tools/validate_scripts.gd" 2>&1 | tee "$log_dir/parse.log"
if rg -q '^SCRIPT ERROR:|^ERROR:' "$log_dir/parse.log"; then exit 1; fi
for test in godot/tests/test_*.gd; do
    log_file="$log_dir/${test##*/}.log"
    timeout 60 "$engine" --headless --fixed-fps 60 --path godot --script "res://tests/${test##*/}" 2>&1 | tee "$log_file"
    rg -q '^PASS:' "$log_file"
    if rg -q '^SCRIPT ERROR:|^ERROR:' "$log_file"; then exit 1; fi
done
timeout 30 "$engine" --headless --fixed-fps 60 --path godot --quit-after 120 2>&1 | tee "$log_dir/startup.log"
if rg -q '^SCRIPT ERROR:|^ERROR:' "$log_dir/startup.log"; then exit 1; fi
