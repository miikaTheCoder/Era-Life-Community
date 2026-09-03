#!/usr/bin/env bash
set -euo pipefail

# Five five-year sessions, each followed by a completely fresh Godot process.
# The last restart verifies the final checkpoint without advancing another year.
repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
mode="${1:-household}"
case "$mode" in
    household|narrative-family|narrative-continue|god) ;;
    *) echo "Usage: $0 [household|narrative-family|narrative-continue|god] [new-profile-directory]" >&2; exit 2 ;;
esac
profile_dir="${2:-$(mktemp -d /tmp/eralife-long-XXXXXX)}"
if [[ -d "$profile_dir/data" ]]; then
    echo "Use a new profile directory, so this run cannot replace an existing test life." >&2
    exit 2
fi
for checkpoint in 1 2 3 4 5; do
    run_mode=restore
    if [[ "$checkpoint" == 1 ]]; then run_mode="$mode"; fi
    ERA_YEARS=5 ERA_RUN_LABEL="checkpoint-$checkpoint" \
        bash "$repo_root/scripts/test-desktop-modes.sh" "$run_mode" "$profile_dir"
done
ERA_YEARS=0 ERA_RUN_LABEL=final-restore \
    bash "$repo_root/scripts/test-desktop-modes.sh" restore "$profile_dir"
echo "LONG DESKTOP: $mode passed 25 years and 5 cold restores. Evidence: $profile_dir"
