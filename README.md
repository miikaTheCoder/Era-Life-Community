# ERA-LIFE Community

A development fork of [Browleytheboi/Era-Life-Community](https://github.com/Browleytheboi/Era-Life-Community), a reconstructed Godot project. Original and community contributor history is preserved. See [the reconstruction notes](project/README-RECONSTRUCTION.md) for its history and known gameplay issues.

Packaged desktop builds belong under [this fork's Releases](https://github.com/miikaTheCoder/Era-Life-Community/releases). The first desktop version is an alpha; Windows and macOS packages still need native playtesting.

Desktop Narrative and Household entry flows are now connected to the simulation.
See [desktop gameplay and validation](docs/DESKTOP-GAMEPLAY.md) for how to play,
the entry/save repairs, repeatable checks, and remaining limitations.

To publish from your own fork, follow the [desktop release checklist](docs/RELEASING.md).
It covers preserving this checkout, connecting the correct upstream, publishing source,
testing each platform, and drafting a GitHub prerelease.

The source also retains an experimental [Android port and build instructions](docs/ANDROID.md), preserved separately in the local `mobile` branch. Build its signed test APK with `./scripts/build.sh android` after installing the Android templates and SDK tools. The current compatibility build requires 32-bit ARM app support; the ARM64 build still fails during startup on the tested phone. Android APKs are not part of the desktop alpha release.

## Build

Use **Godot 4.4.1 stable**, including matching export templates. The system Godot may be newer; the build script rejects other versions to avoid silently migrating this reconstructed project.

On Linux x86_64, install an isolated, checksum-verified toolchain and export all three desktop builds:

```sh
./scripts/setup-godot.sh   # One-time setup; downloads about 1.2 GiB.
./scripts/build.sh all
```

Setup requires Bash, curl, unzip, and sha512sum. Packaging requires tar, zip, and sha256sum. Tools, builds, and logs stay in the ignored `build/` folder; setup does not replace your system Godot. After setup, builds work offline. Use `linux`, `windows`, or `macos` instead of `all` to export one platform. If you ran setup before macOS support was added, rerun it once to install the missing `macos.zip` template.

If you already have Godot 4.4.1 and its export templates installed, skip setup:

```sh
GODOT_BIN=/absolute/path/to/godot-4.4.1 ./scripts/build.sh all
```

`GODOT_BIN` uses that editor's normal template locations (or the XDG directories you set). On other hosts, install [the official Godot 4.4.1 editor and templates](https://github.com/godotengine/godot-builds/releases/tag/4.4.1-stable), import `project/project.godot`, and use the included **Linux**, **Windows Desktop**, or **macOS** export preset. Create the output directory before exporting. When exporting manually, include the repository license and the notices in `third_party/godot/` with the result.

## Run

| Platform | Ready-to-copy archive | Executable after extraction |
| --- | --- | --- |
| Linux x86_64 | `build/EraLife-linux-x86_64.tar.gz` | `./EraLife.x86_64` |
| Windows x86_64 | `build/EraLife-windows-x86_64.zip` | `EraLife.exe` |
| macOS Intel / Apple Silicon | `build/EraLife-macos-universal.zip` | The included `.app` bundle |

Extract the complete archive. Linux and Windows executables need the adjacent `EraLife.pck` from the **same build**. macOS keeps its game data inside the app bundle. Godot does not need to be installed to play. The original Mobile/Vulkan renderer is unchanged; if a machine cannot run it, try launching with `--rendering-method gl_compatibility`.

Each archive includes launch instructions, license notices, and `BUILD_INFO.txt` with the source commit and whether local edits were present. `./scripts/build.sh all` also creates `build/SHA256SUMS.txt`. Final release packages should be rebuilt from a clean, committed source tree.

The Windows build is unsigned. Windows executable icon/version customization is disabled so Linux exports do not require rcedit/Wine; the game's own window icon remains included. To customize the executable later, configure rcedit in Godot and enable **Application → Modify Resources** in the Windows export preset.

The macOS ZIP contains a universal Intel/Apple Silicon app with an ad-hoc testing signature. It is **not Developer ID signed or notarized**, and downloaded builds may be blocked by Gatekeeper. Native Mac playtesting and distribution signing remain pending. See the [release checklist](docs/RELEASING.md) and [Godot macOS export guide](https://docs.godotengine.org/en/4.4/tutorials/export/exporting_for_macos.html).

The presets explicitly include the release verification public key and exclude the old Discord gateway dependency tree. No online release is published by these scripts.

Desktop builds disable the inherited upstream runtime update channel through
`community/updates/allow_upstream_runtime=false`. Update this fork manually from
its GitHub Releases. The existing signature verification code and public key are
unchanged; Android retains its prior update policy.

## Verification

Build logs are saved in `build/logs/`. The build script checks both Godot's exit status and reported script/import/export errors. Its commands follow [Godot's command-line export workflow](https://docs.godotengine.org/en/4.4/tutorials/editor/command_line_tutorial.html#exporting).

Initial desktop verification on 2026-08-30, before the Android adaptations: all 338 scripts imported and both original desktop exports completed without errors; both archives passed integrity checks. The Linux executable booted headless, rendered the startup cinematic through Vulkan, initialized its game state, and loaded the packaged release public key. Godot reports resources still in use during shutdown in both the original source and the exported game. Those pre-existing cleanup issues remain.

On 2026-08-31, Linux graphical creation, aging, and save/reload checks passed for the repaired desktop modes. See [desktop validation](docs/DESKTOP-GAMEPLAY.md) for coverage and limits. Windows and macOS runtime behavior and full birth-to-death gameplay are still unverified. See [Android validation](docs/ANDROID.md#validation-and-remaining-checks) for the mobile branch's separate checks and limitations.

For a Linux startup smoke test with separate save/config data:

```sh
mkdir -p build/smoke-data
XDG_DATA_HOME="$PWD/build/smoke-data" \
  ./build/linux/EraLife.x86_64 --headless --quit-after 300
```

This only checks startup. It does not validate graphics, audio output, Windows runtime compatibility, or complete gameplay. The reconstruction notes describe the pending-situation flow that still needs manual gameplay testing.
