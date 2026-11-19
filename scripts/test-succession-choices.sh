#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
godot_bin="${GODOT_BIN:-$repo_root/build/tools/godot-4.4.1/Godot_v4.4.1-stable_linux.x86_64}"
case "$("$godot_bin" --version)" in
    4.4.1.stable.*) ;;
    *) echo "Godot 4.4.1 stable is required." >&2; exit 1 ;;
esac
case "${1:-all}" in
    all) routes=(family contacts) ;;
    family|contacts) routes=("$1") ;;
    *) echo "Usage: $0 [family|contacts|all]" >&2; exit 2 ;;
esac
mkdir -p "$repo_root/build/succession-review"
run_dir="$(mktemp -d "$repo_root/build/succession-review/playtest-XXXXXX")"
echo "Evidence: $run_dir"
for route in "${routes[@]}"; do
    profile="$run_dir/$route"
    mkdir -p "$profile"/{data,config,cache,screens}
    export XDG_DATA_HOME="$profile/data" XDG_CONFIG_HOME="$profile/config" XDG_CACHE_HOME="$profile/cache"
    export ERA_PREVIEW_DIR="$profile/screens" ERA_MODE=household ERA_HOUSEHOLD_START_INDEX=0 ERA_SUCCESSION_ROUTE="$route"
    export XDG_SESSION_TYPE=x11 WAYLAND_DISPLAY=
    timeout -k 5s 300s xvfb-run -a -s '-screen 0 1600x1000x24' "$godot_bin" \
        --path "$repo_root/project" --rendering-method gl_compatibility \
        --script "$repo_root/tests/smoke_succession_choices.gd" > "$profile/game.log" 2>&1 || {
        tail -25 "$profile/game.log" >&2
        exit 1
    }
    rg '^SUCCESSION GRAPHICAL: PASS' "$profile/game.log"
    rg -q '^DESKTOP MODES: household PASS$' "$profile/game.log"
    if rg -q '^SCRIPT ERROR:|Parse Error:|Failed to load script' "$profile/game.log" || \
        rg '^ERROR:' "$profile/game.log" | rg -v '^ERROR: [0-9]+ resources still in use at exit'; then
        echo "Unexpected Godot error in $profile/game.log" >&2
        exit 1
    fi
done
