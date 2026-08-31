#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
mode="${1:-household}"
case "$mode" in
    household|narrative-family|narrative-continue|god|restore) ;;
    *) echo "Usage: $0 [household|narrative-family|narrative-continue|god|restore] [test-profile-directory]" >&2; exit 2 ;;
esac
if [[ "$mode" == restore && -z "${2:-}" ]]; then
    echo "Restore requires the test-profile directory printed by a previous run." >&2
    exit 2
fi
profile_dir="${2:-$(mktemp -d /tmp/eralife-desktop-XXXXXX)}"
mkdir -p -- "$profile_dir"
profile_dir="$(cd -- "$profile_dir" && pwd)"
godot_bin="${GODOT_BIN:-$repo_root/build/tools/godot-4.4.1/Godot_v4.4.1-stable_linux.x86_64}"
if [[ "$("$godot_bin" --version)" != 4.4.1.stable.* ]]; then
    echo "This test requires Godot 4.4.1 stable." >&2
    exit 1
fi
mkdir -p -- "$profile_dir/data" "$profile_dir/config" "$profile_dir/cache" "$profile_dir/screens"
export XDG_DATA_HOME="$profile_dir/data"
export XDG_CONFIG_HOME="$profile_dir/config"
export XDG_CACHE_HOME="$profile_dir/cache"
export ERA_PREVIEW_DIR="$profile_dir/screens"
export ERA_MODE="$mode"
echo "Test profile: $profile_dir"
echo "Log: $profile_dir/$mode.log"
echo "Use a graphical desktop; the test requests a 1440×900 window. Existing game saves are not used."
timeout -k 5s 300s "$godot_bin" --path "$repo_root/project" \
    --rendering-method gl_compatibility \
    --script "$repo_root/tests/smoke_desktop_modes.gd" > "$profile_dir/$mode.log" 2>&1
rg 'DESKTOP (MODES|SAVED|RESTORED):' "$profile_dir/$mode.log"
