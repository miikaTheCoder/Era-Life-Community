# Portrait reliability and partner stories

Port completed and unanimously council-approved on 2026-11-02. Evidence paths
in this report refer to the Portrait checkout below, including when this report
is read from the desktop branch.
Base: `b47a973cd171e225e491fb0c15c35c79e8522d70`, branch `portrait`, existing
checkout `/home/nextg/.codex/worktrees/mobile-portrait/Era-Life-Community`.
Approved source: main `137e148de85c5b44e19468c2989d2f7b0e9a4d8c`, reliability
`018efd976441178e652f608e374dd70991f34128`, corrected story
`954645ba8ee027d58929400c75e332a2e3c98b11` against story base `57c626a`.
All three members passed exact `a25cda87ac6c84d9b9c4d12ebcf96c4b7d3067c0`.
See [the platform council record](COUNCIL-PLATFORMS.md). No push or release.

## Scope and preservation

The three shared production scripts and partner JSON exactly match committed
main. World history uses batches of at most 32 rows with a separate cooperative
1 ms deadline, preserving every row and the surrounding actor guards. The two
partner stories add nine chapters and 26 responses, with version 1 save
compatibility, cast-side pre-effect trust, authoritative separation, loading,
original-cast and death guards, and authored-only choice projections with cache
invalidation. Personal payments do not buy agreement or spend company reserves.
See [Partner Stories](PARTNER-STORIES.md) for the shared behavior.

Portrait retains its lazy startup, early menu, MainScene, serialization, mobile
shell, touch adapter, project settings, export presets and headless runner. The
story smoke merges the approved desktop assertions with existing touch handling;
it also checks the separate options scroller and rendered authored-button count.
The timing runner adds only the existing `--mobile-preview` argument when
`ERA_PORTRAIT=1`. The normal 90-second post-shell hydration gate is unchanged.

One reproduced Portrait defect needed a bounded fix: a freed popup can remain
in a host property, and `EraMobilePanels._control` cast it before validating it.
The first graphical payment run completed state assertions but failed on repeated
freed-object script errors. A new mobile-panel regression reproduced the error
before the fix and passed afterward. The owner now checks validity before casting;
a live replacement still resolves. No layout or routing redesign was added.

All local evidence is under `build/portrait-port-20261102/` in this checkout.
`before/` preserves the initial dirty files, patch, protected platform hashes and
previous APK. Existing `.gitignore`, roadmap, handoff and untracked Web audit
content is preserved; only this task's appended roadmap/handoff entries are
staged as separate blobs. Main and original fixture profiles were not modified.

## Verification

- Initial focused suite: **6/6 PASS**, `build/tests/headless-avqriblb/`.
- Initial full suite: **30/30 PASS**, `build/tests/headless-0532dnwi/`.
- Reproduced freed-control regression: **FAIL**, `build/tests/headless-b543a7fs/`.
- Fixed regression: **1/1 PASS**, `build/tests/headless-3r1pdsrg/`.
- Final full suite after the popup fix: **30/30 PASS**, `build/tests/headless-x0trdyz_/`.
  Includes startup dependencies, checkpoint feed, all mobile and all story suites.
- Structure, regenerated code map/check, whitespace and added-text punctuation
  checks pass. All five regression directories are also copied under the evidence
  directory's `headless/` subtree; original failed runs remain intact.

The initial graphical failure remains in `cycle/payment.log`. It is not a pass
merely because its state assertions passed. `cycle-fixed/` repeats from the
unmodified 2006 desktop checkpoint seed and passes four sequential processes:
visible $150 materials payment plus one real year, cold restore and one more
year, cold restore and five years through both remaining choices, then an exact
completed-save restore. The original-cast partner is Cora (ID 3). The route ends
in 2013 with three decisions, $9,775 player funds, $10,225 partner funds, fourteen
diary entries and 839 world-feed entries. Both partner links, both directed
affection maps, full story/deadline/history state, diary and bank accounts are
compared at restore. This route has no company; company isolation is regression
evidence. Seven years are additional Portrait simulation, not a fresh discovery
or a full lifetime. Seeds retain the full catalog and prior desktop discovery.

`small/payment-small.log` repeats the pre-payment seed at an actual 360x640
window and saves 2007 after a visible touch payment. Portrait uses a 420x747
logical viewport at that window size; screenshots are 360x640 pixels. The large
window and logical viewport are both 420x900. The options checks inject touch
drags when content overflows, ensure swipes do not commit choices or move the
body, and tap a reachable response. Screenshots retain readable names, prices,
deadlines, independent outcomes and authored-only choices.

The longer `small-sequel/sequel-small.log` route cold-restores the 2008 delayed
seed, swipes the first-attempt body to its deadline, resolves the visible $75
practical-help choice, reaches the independent ending and saves 2012 after four
real years. These years overlap the 420x900 timeline; do not add them to seven
as a contiguous lifetime. The inspected `restore-care-first_attempt-deadline.png`
and `restore-care-first_attempt-options.png` show the separate body scroller,
visible deadline, unchanged options and reachable priced response. All six final
story processes pass the normal hydration gate. The older-save timing samples
below are separate from these story processes.

## Older Portrait timing and fidelity

Three sequential private-Xvfb samples use copies of the pre-existing Portrait
2016 sibling fixture (1,351 history entries). Source save SHA-256:
`8a50afef0e44b7c66d85cbd90d84387dc0d600df7ddc53a5d0c7fc46b7ecd769`.
All pass the unchanged gate and exact normalized history/order, original actors,
relationships, story state, diary and bank checks. Retained stage data:
`timing-portrait/results.json` and `sample-{1,2,3}/output.log` beneath it.

First playable frame to completed hydration: 26.838, 26.979 and 26.879 seconds.
Observed history stage: 5.196, 5.279 and 5.349 seconds. The three samples show
small variation on this host; they do not establish phone timing or a universal
SLA. These are post-port samples without a new matched Portrait baseline. Keep
the historical normal-gate failures in [Sibling Stories](SIBLING-STORIES.md).
The separate `continue_to_complete_ms` clock starts at restore-method entry,
before expectation decoding and title readiness, not at the visible Continue tap.

Reproduce timing sequentially after regressions:

```sh
ERA_PORTRAIT=1 python3 scripts/profile-cold-continue.py COPIED_PORTRAIT_PROFILE NEW_OUTPUT --samples 3 --offscreen
```

## Local Android package

The local ARM64 performance APK was built after final verification with Godot
4.4.1 stable and existing Android tooling. Package identity is unchanged:
`org.eralife.community.portrait`, version code 4, version `0.1.0-portrait.4`.
Signature verification passes; its public SHA-256 certificate digest equals the
previous retained APK's digest. All five packaged story JSON files exactly match
source. No signing keys or secrets are copied into the evidence directory.

Artifact: `build/portrait-port-20261102/package/EraLife-portrait-android-performance.apk`.
APK SHA-256:
`3fd5aa14b792ccee287921a0c566f29936d3b6d682beee279a82775e9c77006d`.
`package/BUILD_INFO.json` records source-file hashes, base, Godot version,
catalog hashes and the final commit after source equality verification.
Build/export, signature and manifest logs are alongside it. The export occurred
before the task commit; every packaged project-source input is checked against
that commit afterward. The unrelated dirty files are documentation/ignore files,
not packaged gameplay. This exact APK has not been installed or tested on a phone.

The evidence directory has `SHA256-MANIFEST.json`, covering retained logs,
screenshots, copied fixture profiles, regression evidence, backups and package.
`shared-source-hashes.json` records equality with approved desktop production;
`preservation.json` records the preserved local/platform state. Review the
source diff from `b47a973` to this task commit and the retained evidence together.

## Limits and next action

Private Xvfb uses software rendering with `WAYLAND_DISPLAY` removed and isolated
XDG profiles. No owner display, browser or phone was accessed. No simulation
phase, history row, population or timing gate was removed to obtain a pass.
Existing snapshot/projection/watchdog diagnostics and resource-exit warnings
remain in logs; script errors were treated as failures. Exact Honor APK checks,
interactive natural discovery/pacing, interrupted Android sessions and a full
birth-to-death lifetime remain unverified. General Menu/Back coverage is separate
from the focused story route. The parent completed all three council reviews, each returning PASS. Test the
exact APK on Honor when available. The implementation delegate did not consult
council itself; the parent did so afterward. No PR, push or deployment occurred.


## Council follow-up

All three reviewers found no blocking defect. The low-priority notebook-heading
clip at 360x640 remains visible, and touch helpers programmatically position the
deadline/response after proving drag movement. Do not claim entirely manual
reachability or real-device touch latency from those helpers. Profiling-tool
containment and cancellation cleanup remain optional follow-ups. See
[the full verdict and limits](COUNCIL-PLATFORMS.md).
