#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
tool_root="$repo_root/build/tools"
version="4.4.1"
target="${1:-desktop}"
if [[ $# -gt 1 || ! "$target" =~ ^(desktop|android|all)$ ]]; then
    echo "Usage: $0 [desktop|android|all]" >&2
    exit 2
fi

if [[ "$(uname -s)" != Linux || "$(uname -m)" != x86_64 ]]; then
    echo "Automatic setup supports Linux x86_64. Install Godot $version and its export templates manually on other hosts." >&2
    exit 1
fi
for dependency in curl unzip sha512sum; do
    command -v "$dependency" >/dev/null || { echo "Missing dependency: $dependency" >&2; exit 1; }
done

download_dir="$(mktemp -d)"
trap 'rm -rf -- "$download_dir"' EXIT
release_url="https://github.com/godotengine/godot-builds/releases/download/$version-stable"
editor_archive="Godot_v$version-stable_linux.x86_64.zip"
templates_archive="Godot_v$version-stable_export_templates.tpz"

echo "Downloading Godot $version and export templates (about 1.2 GiB total)..."
for archive in "$editor_archive" "$templates_archive"; do
    curl --fail --location --retry 3 --connect-timeout 20 \
        --output "$download_dir/$archive" "$release_url/$archive"
done

# Pinned to the official 4.4.1-stable SHA512-SUMS.txt release manifest.
(
    cd -- "$download_dir"
    sha512sum --check <<'SUMS'
ef4e76880a514257175544952c61191106fdef3095b909bafed9fcbeb230c3e5533920a0f3012882dd4bbde83028a67549825794e2d2c3cf76eba7918b71370e  Godot_v4.4.1-stable_linux.x86_64.zip
8f461c7d6e91a0fbabfc95b1e4ca70ff1732c6f2920956a16b086ec2a85b5f7e238baf4dbce60dcc5630fae3bcb9a1fa2ae2027b92cb495c02d082705715e441  Godot_v4.4.1-stable_export_templates.tpz
SUMS
)

editor_dir="$tool_root/godot-$version"
template_dir="$tool_root/data/godot/export_templates/$version.stable"
mkdir -p -- "$editor_dir" "$template_dir"
unzip -q -o "$download_dir/$editor_archive" -d "$editor_dir"
unzip -q -j -o "$download_dir/$templates_archive" \
    'templates/linux_debug.x86_64' 'templates/linux_release.x86_64' \
    'templates/windows_debug_x86_64.exe' 'templates/windows_release_x86_64.exe' \
    'templates/macos.zip' \
    'templates/version.txt' -d "$template_dir"
if [[ "$target" == android || "$target" == all ]]; then
    unzip -q -j -o "$download_dir/$templates_archive" \
        'templates/android_debug.apk' 'templates/android_release.apk' -d "$template_dir"
fi
chmod +x "$editor_dir/Godot_v$version-stable_linux.x86_64"
echo "Toolchain ready in $tool_root. Run ./scripts/build.sh all for desktop or ./scripts/build.sh android for Android."
