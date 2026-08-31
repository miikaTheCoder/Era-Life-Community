#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
target="${1:-all}"
if [[ $# -gt 1 || ! "$target" =~ ^(linux|windows|macos|android|all)$ ]]; then
    echo "Usage: $0 [linux|windows|macos|android|all] (all = Linux, Windows, macOS)" >&2
    exit 2
fi

bundled_editor="$repo_root/build/tools/godot-4.4.1/Godot_v4.4.1-stable_linux.x86_64"
if [[ -n "${GODOT_BIN:-}" ]]; then
    godot_bin="$GODOT_BIN"
elif [[ -x "$bundled_editor" ]]; then
    godot_bin="$bundled_editor"
    export XDG_DATA_HOME="$repo_root/build/tools/data"
    export XDG_CONFIG_HOME="$repo_root/build/tools/config"
    export XDG_CACHE_HOME="$repo_root/build/tools/cache"
    mkdir -p -- "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
else
    godot_bin="godot"
fi

if ! command -v "$godot_bin" >/dev/null; then
    echo "Godot not found. Run ./scripts/setup-godot.sh or set GODOT_BIN to a Godot 4.4.1 editor." >&2
    exit 1
fi
actual_version="$("$godot_bin" --version)"
if [[ "$actual_version" != 4.4.1.stable.* ]]; then
    echo "Godot 4.4.1 stable is required; found $actual_version. Run ./scripts/setup-godot.sh or set GODOT_BIN." >&2
    exit 1
fi
for dependency in tar zip sha256sum; do
    command -v "$dependency" >/dev/null || { echo "Missing dependency: $dependency" >&2; exit 1; }
done

mkdir -p -- "$repo_root/build/logs"
run_godot() {
    local stage="$1"
    shift
    local log="$repo_root/build/logs/$stage.log"
    echo "$stage (Godot $actual_version)..."
    if ! "$godot_bin" --headless --path "$repo_root/project" "$@" >"$log" 2>&1; then
        cat "$log" >&2
        return 1
    fi
    # Godot can report script/import errors while still returning exit code zero.
    if grep -Eq '(^|[[:space:]])(SCRIPT ERROR|ERROR):' "$log"; then
        cat "$log" >&2
        return 1
    fi
    echo "Completed; log: $log"
}

run_godot import --import
if [[ "$target" == android ]]; then
    if [[ -z "${JAVA_HOME:-}" ]]; then
        export JAVA_HOME="$(dirname -- "$(dirname -- "$(readlink -f -- "$(command -v javac)")")")"
    fi
    if [[ ! -x "$JAVA_HOME/bin/keytool" ]]; then
        echo "Set JAVA_HOME to an OpenJDK 17 installation." >&2
        exit 1
    fi
    export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
    if [[ ! -x "$ANDROID_SDK_ROOT/build-tools/34.0.0/apksigner" || ! -x "$ANDROID_SDK_ROOT/platform-tools/adb" ]]; then
        for sdk in "$repo_root/build/tools/android-sdk" "$HOME/Android/Sdk" "$HOME/Android/LocalSdk" /opt/android-sdk; do
            if [[ -x "$sdk/build-tools/34.0.0/apksigner" && -x "$sdk/platform-tools/adb" ]]; then
                export ANDROID_SDK_ROOT="$sdk"
                break
            fi
        done
    fi
    apksigner="$ANDROID_SDK_ROOT/build-tools/34.0.0/apksigner"
    if [[ ! -x "$apksigner" || ! -x "$ANDROID_SDK_ROOT/platform-tools/adb" ]]; then
        echo "Set ANDROID_SDK_ROOT to an SDK with platform-tools and build-tools;34.0.0 installed. See docs/ANDROID.md." >&2
        exit 1
    fi
    mkdir -p -- "$repo_root/build/android" "$repo_root/build/keys"
    export GODOT_ANDROID_KEYSTORE_DEBUG_PATH="$repo_root/build/keys/android-debug.keystore"
    export GODOT_ANDROID_KEYSTORE_DEBUG_USER=androiddebugkey
    export GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD=android
    if [[ ! -f "$GODOT_ANDROID_KEYSTORE_DEBUG_PATH" ]]; then
        (umask 077; "$JAVA_HOME/bin/keytool" -genkeypair -noprompt \
            -keystore "$GODOT_ANDROID_KEYSTORE_DEBUG_PATH" -storepass android \
            -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 \
            -validity 10000 -dname "CN=Android Debug,O=Android,C=US")
    fi
    python3 "$repo_root/scripts/configure-android.py" > "$repo_root/build/logs/configure-android.log"
    run_godot export-android --export-debug Android "$repo_root/build/android/EraLife-android-debug.apk"
    # Godot can return success after an unsigned export. Independently require
    # a valid signature before reporting an installable APK.
    "$apksigner" verify --verbose "$repo_root/build/android/EraLife-android-debug.apk" > "$repo_root/build/logs/verify-android.log"
    "$ANDROID_SDK_ROOT/build-tools/34.0.0/aapt" dump badging \
        "$repo_root/build/android/EraLife-android-debug.apk" > "$repo_root/build/logs/android-manifest.log"
    (cd -- "$repo_root/build/android" && sha256sum EraLife-android-debug.apk > SHA256SUMS.txt)
    echo "Signed test APK ready: $repo_root/build/android/EraLife-android-debug.apk"
    exit 0
fi

# Keep notices outside the macOS .app so packaging cannot invalidate its signature.
notice_dir="$repo_root/build/package-notices"
mkdir -p -- "$notice_dir"
cp -- "$repo_root/LICENSE" "$notice_dir/LICENSE"
cp -- "$repo_root/docs/DESKTOP-README.txt" "$notice_dir/README.txt"
cp -- "$repo_root/third_party/godot/GODOT_LICENSE.txt" "$notice_dir/GODOT_LICENSE.txt"
cp -- "$repo_root/third_party/godot/GODOT_COPYRIGHT.txt" "$notice_dir/GODOT_COPYRIGHT.txt"
revision="unavailable (source archive)"
source_state="unknown (no Git metadata)"
if [[ -e "$repo_root/.git" ]] && command -v git >/dev/null; then
    revision="$(git -C "$repo_root" rev-parse HEAD)"
    source_status="$(git -C "$repo_root" status --porcelain)"
    source_state=clean
    if [[ -n "$source_status" ]]; then
        source_state="dirty (contains local changes not represented by the commit)"
    fi
fi
printf 'Godot: %s\nSource commit: %s\nSource state: %s\nBuilt (UTC): %s\n' \
    "$actual_version" "$revision" "$source_state" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$notice_dir/BUILD_INFO.txt"
notices=(LICENSE README.txt GODOT_LICENSE.txt GODOT_COPYRIGHT.txt BUILD_INFO.txt)
archives=()
# Invalidate before replacing any archive, including when a later export fails.
rm -f -- "$repo_root/build/SHA256SUMS.txt" "$repo_root/build/SHA256SUMS-$target.txt"

if [[ "$target" == linux || "$target" == all ]]; then
    mkdir -p -- "$repo_root/build/linux"
    run_godot export-linux --export-release Linux "$repo_root/build/linux/EraLife.x86_64"
    for notice in "${notices[@]}"; do cp -- "$notice_dir/$notice" "$repo_root/build/linux/$notice"; done
    tar -czf "$repo_root/build/EraLife-linux-x86_64.tar.gz" -C "$repo_root/build/linux" EraLife.x86_64 EraLife.pck "${notices[@]}"
    archives+=(EraLife-linux-x86_64.tar.gz)
fi
if [[ "$target" == windows || "$target" == all ]]; then
    mkdir -p -- "$repo_root/build/windows"
    run_godot export-windows --export-release "Windows Desktop" "$repo_root/build/windows/EraLife.exe"
    for notice in "${notices[@]}"; do cp -- "$notice_dir/$notice" "$repo_root/build/windows/$notice"; done
    # Recreate the archive so old members never survive a new export.
    rm -f -- "$repo_root/build/EraLife-windows-x86_64.zip"
    (cd -- "$repo_root/build/windows" && zip -q "$repo_root/build/EraLife-windows-x86_64.zip" EraLife.exe EraLife.pck "${notices[@]}")
    archives+=(EraLife-windows-x86_64.zip)
fi
if [[ "$target" == macos || "$target" == all ]]; then
    mkdir -p -- "$repo_root/build/macos"
    rm -f -- "$repo_root/build/macos/EraLife.zip"
    run_godot export-macos --export-release macOS "$repo_root/build/macos/EraLife.zip"
    cp -- "$repo_root/build/macos/EraLife.zip" "$repo_root/build/EraLife-macos-universal.zip"
    (cd -- "$notice_dir" && zip -q "$repo_root/build/EraLife-macos-universal.zip" "${notices[@]}")
    archives+=(EraLife-macos-universal.zip)
    echo "macOS is ad-hoc signed for testing; it is not Developer ID signed or notarized."
fi

checksum_file="SHA256SUMS-$target.txt"
if [[ "$target" == all ]]; then checksum_file=SHA256SUMS.txt; fi
(cd -- "$repo_root/build" && sha256sum "${archives[@]}" > "$checksum_file")
echo "Builds ready in $repo_root/build; checksums: $checksum_file."
echo "Keep Linux/Windows executables beside their matching EraLife.pck; extract the complete macOS .app."
