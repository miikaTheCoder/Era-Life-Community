#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
profile_dir="$(mktemp -d /tmp/eralife-shared-XXXXXX)"
godot_bin="${GODOT_BIN:-$repo_root/build/tools/godot-4.4.1/Godot_v4.4.1-stable_linux.x86_64}"
if [[ "$("$godot_bin" --version)" != 4.4.1.stable.* ]]; then
    echo "Godot 4.4.1 stable is required." >&2
    exit 1
fi
mkdir -p "$profile_dir/data" "$profile_dir/config" "$profile_dir/cache" "$profile_dir/screens"
export XDG_DATA_HOME="$profile_dir/data" XDG_CONFIG_HOME="$profile_dir/config" XDG_CACHE_HOME="$profile_dir/cache"
export ERA_MODE=household ERA_HOUSEHOLD_START_INDEX=0 ERA_PREVIEW_DIR="$profile_dir/screens"
extra_args=()
if [[ "${ERA_PORTRAIT:-0}" == 1 ]]; then
    extra_args=(-- --mobile-preview)
fi
echo "Shared Lives graphical profile: $profile_dir"
timeout -k 5s 900s "$godot_bin" --path "$repo_root/project" --rendering-method gl_compatibility \
    --script "$repo_root/tests/smoke_shared_lives.gd" "${extra_args[@]}" > "$profile_dir/output.log" 2>&1
rg '^SHARED LIVES GRAPHICAL:|^DESKTOP MODES:' "$profile_dir/output.log"
rg -q '^SHARED LIVES GRAPHICAL: choice PASS' "$profile_dir/output.log"
rg -q '^DESKTOP MODES: household PASS' "$profile_dir/output.log"
if rg -q '^SCRIPT ERROR:|Parse Error:|Failed to load script' "$profile_dir/output.log"; then
    echo "Godot reported a script error; inspect $profile_dir/output.log" >&2
    exit 1
fi
