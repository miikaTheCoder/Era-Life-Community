# Desktop alpha release, step by step

Nothing in the build scripts pushes code or publishes a GitHub release.
Keep Android out of the desktop release assets; it remains a separate workstream.

For this checkout, the fork is now confirmed as
[`miikaTheCoder/Era-Life-Community`](https://github.com/miikaTheCoder/Era-Life-Community).
`origin` points to that fork and `upstream` points to the community repository.
The Android/checkpoint foundation is preserved in the local `mobile` branch;
desktop alpha work is on `codex/desktop-alpha`. Do not repeat the fork, branch
creation, or remote-renaming commands below in this already-configured checkout.
They are retained as instructions for setting up another checkout.

## 1. Choose and fork the upstream repository

Open the community repository you want to build on, click **Fork**, select your
GitHub account, and create the fork. Forking an existing fork is supported; keep
the community history and credit its contributors. See [GitHub's fork guide](https://docs.github.com/en/pull-requests/how-tos/work-with-forks/fork-a-repo).

On 2026-08-31 this checkout's `origin` was
`https://github.com/Browleytheboi/Era-Life-Community.git`. GitHub's public API
reported `fork: false` and default branch `main`. That tells us its GitHub fork
status, not the provenance of all its contents or who owns your account.

If that is the community repository, fork it. If you mean a different community
repository, use its exact URL and compare the histories before transferring our
changes. If the current remote already belongs to you, do not try to fork it into
the same account. We still need the intended upstream URL to establish the right
relationship. Do not delete or overwrite this local checkout.

## 2. Preserve the local work and connect your fork

This checkout originally had staged Android work and unstaged desktop repairs.
Those layers are now being preserved in separate commits. Changing the remote
does not upload commits. Preserve the working files, review both sets of changes,
and keep required shared code together.

Start a desktop branch from this checkout (example name):

```sh
git switch -c codex/desktop-alpha
git status --short
git diff
git diff --cached
```

Do not use a hard reset, force push, or overwrite the source with a different
clone. If a selected upstream has unrelated history, preserve the current work in
a local commit and port the relevant fixes into a fresh clone of the correct fork;
do not merge unrelated histories just to make the push succeed.

**Only if you forked the current `Browleytheboi/Era-Life-Community` repository**, and
there is no existing `upstream` remote, the usual remote setup is:

```sh
git remote rename origin upstream
git remote add origin https://github.com/YOUR-USERNAME/YOUR-FORK.git
git remote -v
```

Replace the placeholder with the URL GitHub gave you. `origin` should be your
fork; `upstream` should be the community repository. This setup is already applied
in the current checkout. [GitHub remote guidance](https://docs.github.com/en/pull-requests/how-tos/work-with-forks/configuring-a-remote-repository-for-a-fork).

## 3. Review source, credits, and the version

- Preserve the existing `LICENSE` and author notices. This repository contains GPL
  v2 license text. Make the matching source and build scripts available with the
  binary release; verify any additional obligations for your distribution.
- Verify permission and attribution for the recovered music, sounds, and artwork.
  No asset provenance manifest was found here. Files such as
  `project/audio/music/BlackMirrorOpening.ogg` need their source/license checked;
  a filename alone does not establish the rights. Replace media you cannot clear.
- Godot engine notices are packaged automatically from `third_party/godot/`.
  They do not cover the game's media. [Godot's license guidance](https://docs.godotengine.org/en/stable/about/complying_with_licenses.html).
- Review both staged and unstaged changes for secrets, personal saves, and unrelated
  work. Keep `build/`, SDKs, signing keys, local settings, and private credentials out
  of Git. The release verification `.pub` key is intentionally public.
- Choose an unused alpha tag, for example **`v0.1.3-alpha.1`**. This is a suggestion,
  not a tag already created. Check your fork's existing tags first.
- Set `application/config/version` in `project/project.godot` to the corresponding
  numeric version, e.g. `0.1.3`. The macOS preset inherits it and needs a numeric
  dotted version. Keep `-alpha.1` in the Git tag/release title. Do not change Android's
  separate version codes for this desktop release.

## 4. Commit and publish the source to your fork

Stage the reviewed files explicitly, including new scripts, docs, tests, and engine
notices. Review `git diff --cached` before committing; there were already staged
changes before this release preparation, so a blanket `git add .` is inappropriate.

After the staged result is the intended source:

```sh
git commit -m "Connect desktop life modes and package desktop builds"
git push -u origin codex/desktop-alpha
```

This publishes source on your fork's desktop branch. A merge into your own default
branch can follow review. If you open a pull request for that, explicitly choose
**your fork** as the base repository; GitHub may otherwise suggest the community
repository. A contribution back upstream is a separate, optional pull request.

## 5. Build from the exact release commit

Use a clean checkout of the final commit you intend to tag. If unrelated Android
edits remain locally, keep them safe in the original checkout and build the committed
desktop branch in a separate checkout. Do not discard them to obtain a clean status.

On Linux x86_64:

```sh
git status --short
./scripts/setup-godot.sh desktop   # Only if the pinned toolchain/templates are missing.
./scripts/build.sh all
```

The first command must be empty for a final release build. Setup downloads about
1.2 GiB and verifies the official pinned Godot 4.4.1 checksums. It installs Linux,
Windows, and macOS templates locally. An older toolchain setup may need to be rerun
once to add `macos.zip`. Subsequent builds work offline.

The build produces:

| Release attachment | Contents |
| --- | --- |
| `build/EraLife-linux-x86_64.tar.gz` | Linux executable and matching PCK |
| `build/EraLife-windows-x86_64.zip` | Windows executable and matching PCK |
| `build/EraLife-macos-universal.zip` | macOS app for Intel and Apple Silicon |
| `build/SHA256SUMS.txt` | Checksums of those three archives |

Each archive includes launch instructions, the repository license, Godot notices,
and `BUILD_INFO.txt`. Check that build info names the intended commit and says
`Source state: clean`. Rebuild after committing before attaching final release
artifacts. Individual `linux`, `windows`,
and `macos` builds have their own checksum files; `all` regenerates the combined one.

## 6. Test the actual downloads on each supported system

Extract each archive into a new folder. Test Narrative, Household, and God Mode;
age several years, save, quit the process completely, reopen, and continue. Check
relationships, selected household member, diary/history, and continued aging.
Also check mouse/keyboard input, readable layout at 1080p, audio, and window resizing.
Back up existing saves before testing.

Linux gameplay and save/reload checks are documented in
[DESKTOP-GAMEPLAY.md](DESKTOP-GAMEPLAY.md). Windows and macOS still need native
playtests. A successful export is not a successful native playtest. Do not claim
macOS universal support is tested until both Intel and Apple Silicon have evidence.

Windows builds are unsigned and may show download/launch warnings. The current
macOS preset uses built-in **ad-hoc signing**, with **no Apple notarization**.
Downloaded Mac builds may be blocked by Gatekeeper. For normal public distribution,
configure Developer ID signing, notarize, staple the ticket, then package and test
again. Keep credentials out of the preset and Git. ZIP exports can be produced on
Linux; DMG creation requires macOS. Follow the [pinned Godot macOS export guide](https://docs.godotengine.org/en/4.4/tutorials/export/exporting_for_macos.html).

Do not tell users to disable security protections globally. Test the file downloaded
from GitHub as well as the local build, since quarantine/signing behavior differs.
If Mac testing or signing is pending, omit that asset from the initial public release
or label it explicitly as an experimental tester build.

## 7. Tag the tested commit

When all intended source changes are committed, the native test results are recorded,
and the archives have been rebuilt from that final source, tag that same commit:

```sh
git tag -a v0.1.3-alpha.1 -m "Desktop alpha 1"
git push origin v0.1.3-alpha.1
```

Replace the example tag if a different version was chosen. Do not move an already
published tag. If code changes after building, commit it, rebuild, and retest before
tagging. Publish a new version to correct a released build.

## 8. Draft, review, and publish the GitHub release

1. Open **your fork → Releases → Draft a new release**.
2. Select the tag pushed in step 7. Do not accidentally target an older `main` commit.
3. Give it a title such as `Era Life Community — Desktop Alpha 1`.
4. Describe working modes, save/aging repairs, tested systems, and remaining limits.
   Use [RELEASE-NOTES-DRAFT.md](RELEASE-NOTES-DRAFT.md) as a starting point, replacing
   its placeholders and updating platform results before publication.
5. Attach the platform archives and the checksum file. GitHub's automatic source
   ZIP/TAR downloads are source code, not playable game downloads. Keep builds out
   of the source repository's normal file history.
6. Tick **This is a pre-release**. Save as a draft and review source tag, attachments,
   license/credits, install instructions, and test claims.
7. Click **Publish release** only when those checks are complete.
8. Download the published assets, verify checksums, and run one final smoke test.

If you omit a platform, regenerate the uploaded checksum file to list only the
archives actually attached. Preserve the matching source and notices. See
[GitHub's release instructions](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository).
