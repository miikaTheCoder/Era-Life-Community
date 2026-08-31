#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
target="${1:-all}"
if [[ $# -gt 1 || ! "$target" =~ ^(linux|windows|android|all)$ ]]; then
    echo "Usage: $0 [linux|windows|android|all] (all = desktop builds)" >&2
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
for dependency in tar zip; do
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
if [[ "$target" == linux || "$target" == all ]]; then
    mkdir -p -- "$repo_root/build/linux"
    run_godot export-linux --export-release Linux "$repo_root/build/linux/EraLife.x86_64"
    cp -- "$repo_root/LICENSE" "$repo_root/build/linux/LICENSE"
    tar -czf "$repo_root/build/EraLife-linux-x86_64.tar.gz" -C "$repo_root/build/linux" EraLife.x86_64 EraLife.pck LICENSE
fi
if [[ "$target" == windows || "$target" == all ]]; then
    mkdir -p -- "$repo_root/build/windows"
    run_godot export-windows --export-release "Windows Desktop" "$repo_root/build/windows/EraLife.exe"
    cp -- "$repo_root/LICENSE" "$repo_root/build/windows/LICENSE"
    # Recreate the archive so old members never survive a new export.
    rm -f -- "$repo_root/build/EraLife-windows-x86_64.zip"
    (cd -- "$repo_root/build/windows" && zip -q "$repo_root/build/EraLife-windows-x86_64.zip" EraLife.exe EraLife.pck LICENSE)
fi
echo "Builds ready in $repo_root/build. Keep each executable beside its matching EraLife.pck."
