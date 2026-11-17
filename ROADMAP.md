# EraLife: what the game needs next

Updated **2026-11-17**. The goal is a life worth continuing: recurring people,
meaningful choices and consequences that survive into the next generation.
Finish and prove the existing game before adding more systems or story catalogs.

Shared gameplay develops on desktop `main` first, then receives a tested port to
`portrait`. Browser play also lives on `main`, with separate storage and usability
checks. Read [AGENTS.md](AGENTS.md), [the handoff](docs/AGENT-HANDOFF.md) and
[branch workflow](docs/BRANCHES.md) before starting. Historical IDs and evidence
are preserved in [the previous roadmap](docs/ROADMAP-HISTORY.md).

## What already exists

- Desktop has 18 authored stories, recurring cast, family businesses, inherited
  memories, connected recollections, a family chronicle and data-only story packs.
  Portrait has the earlier 14-story catalog. See [Connected Lives](docs/CONNECTED-LIVES-LOOP.md).
- Save/Continue, business balances and shorter multi-year routes have regression
  and cold-process evidence. This does not establish complete lifetime playability.
- The November 2 Portrait candidate has preview and cold-restore evidence; its
  exact APK still needs phone acceptance. Web reflow and keyboard changes have
  partial evidence, with actual mobile-browser acceptance still open.

**Source boundary:** this task starts from committed `main` at `a4b8d0a`.
The original checkout also contains uncommitted Connected Lives corrections and
local records reporting a later 30-test suite and unanimous council approval.
Those corrections and records are not part of this PR. Preserve them and land
that existing task separately before treating its approval as committed-source
or release evidence. Do not redo its implemented stories.

## Essential queue

Take one bounded change at a time. Each row needs its own evidence; an earlier
fixture, export or review does not certify a newer build. Independent platform
work can proceed without holding desktop fixes for unavailable devices.

| Order / ID | Needed outcome | Status and next action | Dependency |
| --- | --- | --- | --- |
| 1 / R16 | A failed replacement save keeps the previous life | Linux verified on `codex/essential-roadmap`, awaiting integration; platform limits remain below | None |
| 2 / R17 | A complete life and a playable next generation | Queued: run ordinary full-catalog play, then fix the first reproduced progression, pacing or persistence blocker | R16 and separately integrated Connected Lives corrections |
| 3 / R06 | The same supported experience on Portrait | Queued: compare missing shared fixes/content, port a bounded slice, then test the exact APK | Reviewed desktop slice; phone access for device acceptance |
| 4 / R09 | Browser play that survives reload and works by touch | Queued: reproduce static-host startup stalls and run real phone save/Continue | Current Web export; Android/iOS access for each acceptance result |
| 5 / R04 | A clearly scoped build someone else can reliably play | Queued: package the tested source and publish only when requested | R16 and R17 for desktop; R06 or R09 for those targets |

### R16: Preserve the last save when its replacement fails

**Why needed:** the normal serializer truncates the destination before writing
and does not check write completion. A failed or interrupted write can destroy
the previous life and can incorrectly report success.

**Done when:** binary and JSON replacements are written beside the destination,
checked and closed before replacement. Open/write/rename failures report failure
without publishing new summary or continuity metadata. The old save survives an
interrupted write byte for byte. Successful replacement remains loadable by the
existing readers with unchanged save schema. Run real file-failure regressions
and the full shared-state suite. Preserve the observed failure and passing logs.

This slice covers `GameStateSerializationRuntime.serialize_to_path`, used by
normal `GameState.save_game`. Windows final replacement (Godot removes the old path before moving the new
one), rewind snapshot storage, power-loss durability and
browser persistence to disk across page termination need separate evidence;
this change does not certify them. A failed final rename retains the complete
new file and reports its recovery path; native Windows replacement/recovery must
be verified before its R04 release gate can pass. Port and verify on Portrait under R06.

### R17: Prove the core life loop from beginning to inheritance

**Why needed:** complete authored arcs and deterministic fixtures exist, but a
natural birth-to-death life and playable succession have not been established.

**First step:** record the build, starting mode and full enabled catalog. Play a
new Narrative life through childhood, adult relationships/work, later life and
death without forcing story eligibility. Continue as an heir, make a meaningful
choice, advance a year, save, fully exit, then Continue in a new process.

**Done when:** the route is complete and its evidence shows:

- Ordinary choices can reach existing stories and finish their follow-ups without
  impossible costs, expired age windows or required dead/missing participants.
  Refusal and affordable alternatives remain usable. Fix demonstrated gaps only.
- The player can understand the immediate cost, later consequence and unresolved
  choice, and find the saved history through the journal/chronicle.
- Cold restarts at childhood, adulthood and succession retain actor identity,
  relationships, choices, history, inheritance and exact personal/company balances.
  Existing supported saves also load. Ownership transfer cannot pay income twice.
- Repeated years remain responsive. Record startup, Continue and age-up timings
  plus memory across the same long session; investigate stalls/growth with traces
  under R07. Keep the existing 90-second cold-load test gate, not a relaxed one.
- Household and God Mode still enter, age, navigate, save and Continue. Record any
  mode/platform not exercised. A short smoke is not a lifetime pass.

Start with [architecture owners](docs/ARCHITECTURE.md),
[cold-restore evidence](docs/COLD-RESTORE.md) and
[performance evidence](docs/COLD-CONTINUE-PERFORMANCE.md). Keep R01 save fidelity
and R07 performance as acceptance obligations inside this work, not new systems.

### R06: Close the native phone gaps

Audit the desktop input/display fixes and Connected Lives port against Portrait's
actual source, preserving its startup, touch, identity and save adaptations.
Port shared gameplay only after desktop verification, with separate target tests.

**Done when:** choices, chronicle, scrolling and Back routes work at 420x900 and
360x640, and the exact signed APK passes repeated cold launch, God Mode Begin
Life, Household entry, choices, age/save, process restart and Continue on Honor.
Check the same saved family members and balances, background/resume, and repeated
Character/Back/Menu/Explore cycles. Record APK hash, device and logs. R02's older
five-cycle pass does not close R03's repeat-entry or R06's current-build acceptance.

Use [Portrait port evidence](docs/PORTRAIT-PARTNER-PORT.md). Device unavailability
blocks only device acceptance. Desktop previews and APK builds are separate facts.

### R09: Make the existing Web target dependable

**Done when:** repeated first visits and reloads on a plain static host reach the
game without a manual refresh workaround. On a real Android browser and iOS
Safari, readable entry, keyboard input, touch scrolling, choices, navigation,
age/save, reload and Continue work on the same origin. Confirm saved identity,
choices and balances after reload and record browser/OS/build. Test the intended
HTTPS host when deployment is authorized; local preview alone does not certify it.

Keep unavailable targets explicitly unverified. Use [Web evidence](docs/WEB.md),
[mobile audit](docs/MOBILE-WEB-AUDIT.md) and [keyboard evidence](docs/WEB-KEYBOARD.md).
This is separate from native Portrait acceptance.

### R04: Package only the experience that was verified

Build from clean, committed, tested source. Check packaged content and checksums,
include known limitations and concise reproduction/reporting instructions, and
follow [the release checklist](docs/RELEASING.md). Verify the exported Linux game,
including save and cold Continue. Windows and macOS need their own native runtime
checks before being described as verified; an export is not a platform pass.

Mark targets independently: `Release-ready` needs their applicable evidence;
`Released` needs actual authorized publication. A roadmap, council vote or PR
never authorizes a merge, deployment or release by itself.

## Deliberately outside this queue

More story packs, new career/economy systems, a visual story editor, marketplace
expansion and broad engine rewrites are deferred until playtesting demonstrates
a missing part of the core experience. Preserve existing features and mod support.
Refactor only where a reproduced defect or measurement requires it.

R05 and R10-R15 are implemented content, not an invitation to rebuild it.
R08's implemented authoring path shares the outstanding source-integration gate
above. R01/R07 remain regression obligations; R02/R03 are tracked in R06. Original
criteria and dated failures remain in [roadmap history](docs/ROADMAP-HISTORY.md).

## Handoff and verification

For every task record status, branch/commit, checks actually run, retained evidence
and the smallest next action. Follow [repository checks](AGENTS.md#verify-changes)
with Godot 4.4.1. Keep gameplay, device and release statuses separate. Preserve
failures and unconfirmed observations instead of silently replacing them with a pass.

This is the shared desktop/Portrait plan. The occupied Portrait checkout has
uncommitted roadmap/handoff work; reconcile this plan there during the next
coordinated documentation port without overwriting that work. No Portrait source
or device verification is included in this task.

| Date | Item / task | Verification and next action |
| --- | --- | --- |
| 2026-11-17 | Essential roadmap + R16, `codex/essential-roadmap` | Roadmap focused and history preserved. R16: 30 regressions, four real write-failure cases and graphical save/cold Continue pass; see [evidence](docs/SAVE-WRITE-SAFETY.md), including one interrupted display run. Next: council/PR gate, then R17 after separate story corrections land. No merge or release. |
