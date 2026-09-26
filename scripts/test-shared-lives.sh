#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
mode="${1:-household}"
case "$mode" in
    household|restore|cycle) ;;
    *) echo "Usage: $0 [household|restore|cycle] [test-profile-directory]" >&2; exit 2 ;;
esac
if [[ "$mode" == restore && -z "${2:-}" ]]; then
    echo "Restore requires the profile printed by a previous Shared Lives run." >&2
    exit 2
fi
profile_dir="${2:-$(mktemp -d /tmp/eralife-shared-XXXXXX)}"
if [[ "$mode" != restore && -d "$profile_dir/data" ]]; then
    echo "Creation requires a fresh profile; use restore to continue its saved life." >&2
    exit 2
fi
mkdir -p "$profile_dir"
profile_dir="$(cd -- "$profile_dir" && pwd)"
if [[ "$mode" == cycle ]]; then
    ERA_RUN_LABEL=household bash "$0" household "$profile_dir"
    ERA_RUN_LABEL=restore bash "$0" restore "$profile_dir"
    ERA_YEARS=0 ERA_RUN_LABEL=restore-again bash "$0" restore "$profile_dir"
    exit 0
fi
run_label="${ERA_RUN_LABEL:-$mode}"
if [[ ! "$run_label" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "ERA_RUN_LABEL must contain only letters, digits, underscores or hyphens." >&2
    exit 2
fi
godot_bin="${GODOT_BIN:-$repo_root/build/tools/godot-4.4.1/Godot_v4.4.1-stable_linux.x86_64}"
if [[ "$("$godot_bin" --version)" != 4.4.1.stable.* ]]; then
    echo "Godot 4.4.1 stable is required." >&2
    exit 1
fi
mkdir -p "$profile_dir/data" "$profile_dir/config" "$profile_dir/cache" "$profile_dir/screens"
export XDG_DATA_HOME="$profile_dir/data" XDG_CONFIG_HOME="$profile_dir/config" XDG_CACHE_HOME="$profile_dir/cache"
export ERA_MODE="$mode" ERA_HOUSEHOLD_START_INDEX=0 ERA_PREVIEW_DIR="$profile_dir/screens/$run_label"
mkdir -p "$ERA_PREVIEW_DIR"
extra_args=()
if [[ "${ERA_PORTRAIT:-0}" == 1 ]]; then
    extra_args=(-- --mobile-preview)
fi
echo "Shared Lives graphical profile: $profile_dir"
echo "Log: $profile_dir/$run_label.log"
timeout -k 5s 900s "$godot_bin" --path "$repo_root/project" --rendering-method gl_compatibility \
    --script "$repo_root/tests/smoke_shared_lives.gd" "${extra_args[@]}" > "$profile_dir/$run_label.log" 2>&1
rg '^SHARED LIVES GRAPHICAL:|^DESKTOP (MODES|BUSINESS RESTORED|SAVED|RESTORED):' "$profile_dir/$run_label.log"
if [[ "$mode" == household ]]; then
    rg -q '^SHARED LIVES GRAPHICAL: choice PASS' "$profile_dir/$run_label.log"
    rg -q '^SHARED LIVES GRAPHICAL: save PASS' "$profile_dir/$run_label.log"
else
    rg -q '^DESKTOP BUSINESS RESTORED:' "$profile_dir/$run_label.log"
fi
rg -q "^DESKTOP MODES: $mode PASS$" "$profile_dir/$run_label.log"
if rg -q '^SCRIPT ERROR:|Parse Error:|Failed to load script' "$profile_dir/$run_label.log" || \
    rg '^ERROR:' "$profile_dir/$run_label.log" | rg -v '^ERROR: [0-9]+ resources still in use at exit'; then
    echo "Godot reported an error; inspect $profile_dir/$run_label.log" >&2
    exit 1
fi
