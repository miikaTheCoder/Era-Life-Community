# EraLife roadmap

Updated **2026-09-27**. This is the shared plan for desktop EraLife and EraLife
Portrait. Use [the agent handoff](docs/AGENT-HANDOFF.md) to find the active
branches, worktrees, commands, and evidence; use [AGENTS.md](AGENTS.md) for code
ownership and repository rules.

## Direction

Build lives worth continuing: recurring people with their own decisions, work and
family choices that affect each other, and consequences that survive into the
next generation. Ship bounded, playable additions. Develop shared gameplay on
**desktop first**, then adapt and verify it in **Portrait**.

A roadmap helps the project stay active when each task leaves a tested result and
a clear next step. This file is a priority queue, not a calendar promise or an
unattended job. Dates and release numbers are assigned when there is evidence to
support them. Proposed content below can change with playtesting and user input.

## Starting point

| Area | Current state |
| --- | --- |
| Life Stories & Legacies | Six implemented stories with recurring cast, delayed consequences, and saved history |
| Shared Lives | Two more stories, 16 chapters, 46 responses, real business reserves, ownership, and succession; implemented on desktop and ported to Portrait |
| Living Households | Desktop first slice verified: recurring care/work arc plus inherited memory, 11 chapters and 30 responses; Portrait port open |
| Desktop validation | 22 regressions passed; consecutive Age Up input repaired; Shared Lives full-catalog readiness and Living Households cold-Continue checks passed; R04 and R05 Linux packages verified |
| Portrait validation | 23 headless regressions plus final focused checks passed; content flow inspected at 420×900; signed APK built, not retested on the Honor phone |
| Agent continuity | Shared handoff guide and entry links available on both active branches |
| Release status | Current work is on the Shared Lives branches. A push or an APK export does not mean it is merged, published, or fully device-verified |

These are dated results, not certification of future commits. The exact evidence
and limitations live in [Shared Lives](docs/SHARED-LIVES.md) and the
[agent handoff](docs/AGENT-HANDOFF.md). In particular, the focused Portrait content
smoke skips general drawer navigation; it does not clear the Menu/Back issue.

## Work queue

R01 is **verified** on desktop and in Portrait preview, with evidence below.
R04 desktop functional readiness is **verified and packaged** for local Linux
playtesting. R05 is **verified** on desktop, with full routes and cold-Continue
evidence in [Living Households](docs/LIVING-HOUSEHOLDS.md).
R07's **desktop consecutive-click repair is verified**; its wider profiling and
live-display follow-ups remain open. Other items remain **unclaimed**. When starting one, replace its status with
`In progress`, record the task/branch in the work log, and keep the change small
enough to review.
`Queued` means prioritized; `Proposed` means the product direction needs refinement
before implementation. `Verified` requires the evidence in its completion criteria.

| ID | Item | Target | Status | Depends on |
| --- | --- | --- | --- | --- |
| R01 | Reliable save → cold restart → continue | Desktop, then Portrait | Verified: desktop + Portrait preview | None |
| R02 | Character / Back / Explore navigation | Portrait | Queued | None; can be an independent fix |
| R03 | God Mode → Begin Life phone crash | Portrait | Queued; device access needed for final verification | None; keep separate from R02 |
| R04 | Playtest and package the Shared Lives milestone | Desktop first; Portrait separately | Desktop verified and packaged; Portrait open | Desktop: R01 desktop checks. Portrait: R01 Portrait checks, R02, R03 |
| R05 | Living Households: one complete family arc | Desktop | Verified: first family arc and inherited memory | Desktop R04 release-ready checks |
| R06 | Port Living Households and test it on a phone | Portrait | Queued | R05 and Portrait R04 |
| R07 | Measured startup and lifetime performance | Desktop + Portrait | Age Up input fixed; profiling and live display open | Use stable routes from R01–R03 |
| R08 | Community story-pack authoring path | Shared | Proposed | R05 supplies a second ensemble use case |

Record shared items' verification separately for desktop and Portrait. A
Portrait-only blocker need not stop desktop R04 or R05, and public release
publication is not a prerequisite for starting the next content slice. Fixes, content, and
platform work can progress independently when they touch different owners and
have separate branches. Recheck the work log and Git before claiming work.

## Now: finish a dependable Shared Lives milestone

### R01: Continue the same life after closing the game

**First step:** reproduce the documented cold-restore failure in a fresh desktop
test profile. Retain the save, log, selected actor, and last completed hydration
stage before editing persistence code. Start with the existing serialization,
hydration, and residency owners; see [Architecture](docs/ARCHITECTURE.md).

**Done when:** a generated life with a family business can save, fully exit,
restart in a new process, Continue, age, and save again. Compare actor identity,
diary/history, relationships, shares, and exact personal/company balances before
and after; no duplicate settlement is allowed. Cover both a newly created save
and an existing supported fixture. Run the relevant regressions and full suite
for shared persistence changes. Port the fix and repeat the cold-restore route
in Portrait; a same-process hydration test alone does not close this item.

**Verified 2026-09-27:** desktop `e2424ff`; Portrait shared port `e538708` plus
mobile Continue update `74e8b07`. All 19 desktop and 23 Portrait regressions passed.
Fresh desktop creation and repeated cold Continue passed, as did older fixtures.
Portrait passed cold Continue, age/save, and another cold Continue at 420×900,
using its existing fixture; it also continued and saved the newly generated
desktop fixture. Exact balances, cast, ownership, relationships, diary/history,
and duplicate settlement checks passed. See [retained evidence](docs/COLD-RESTORE.md).
This verifies R01's persistence route on Linux desktop and in Portrait preview.
It does not certify a phone build or the unsuccessful fresh Portrait creation runs recorded under R04.

### R02: Back closes the current surface exactly once

**First step:** reproduce Character → Android Back → Menu at an actual 420×900
viewport with the general mode harness, retaining the unexpected exit dialog.
Trace the current shell/panel close routes and entry timing before changing them.

**Done when:** Character, Explore, Assets, and pending choices open and close
through their existing controls; Back does not fall through to Exit while closing
a surface. The original failing sequence passes repeatedly from fresh entry,
including while background initialization completes. Retain the regression in the
general harness and verify the route on the phone when available. Do not close
this item using the focused content smoke that skips drawer checks.

### R03: Enter a generated life on the Honor phone

**First step:** obtain a fresh authorized debugging connection and reproduce on
the current APK while preserving app data. Record APK hash, version, architecture,
logs, and native crash information. The previous trace did not establish the exact
GDScript cause; do not assume a loading or memory hypothesis is confirmed.

**Done when:** the cause is supported by evidence, a bounded fix is implemented,
and the exact rebuilt APK completes repeated cold launch → God Mode → Begin Life
runs without the reported crash. Verify one age/save/navigation cycle as well.
Desktop preview success, switching architecture, or hiding the route is not proof
of a fix. If a device is unavailable, leave the final verification open and record
the missing access rather than claiming the crash is resolved.

### R04: A playable milestone someone else can try

**First step:** play Shared Lives through ordinary eligibility with the full
catalog enabled. The deterministic fixture proves mechanics but forces the
business story; establish whether a normal player can discover it and continue it.

The 2026-09-27 Portrait creation checks also need follow-up: one run's world
preparation tap did not activate; a repeat showed blank, narrow household member
buttons and exited without completing entry. Retain these failures separately
from the passing cold-Continue checks in [R01 evidence](docs/COLD-RESTORE.md).

**Done when:** a founder route and an inherited continuation are exercised with
readable costs, understandable deadlines, reachable company details, and saved
consequences. Include an unavailable/declined choice and a failed payment. Record
any balancing or discovery fixes and repeat the affected checks. Build from the
intended committed source, check packaged content/checksums, and write concise
release notes with known limitations and a reproduction path for feedback.

Prepare desktop and Portrait artifacts independently. Mark them `Release-ready`
only when their applicable checks pass; mark `Released` only after actual
publication. Follow [RELEASING.md](docs/RELEASING.md) and the current publication
request. A roadmap entry by itself does not publish a build or merge a branch.

## Living Households: desktop verified, Portrait next

### R05: Make the people at home affect the life you are building

**Implemented first slice:** one recurring family arc about dividing time between
work, a relationship, and caring for a relative. Existing household members should
initiate requests or disagree according to their relationships and earlier choices.
The company can provide context when present; players without a business must
still have a complete route.

**Done when:** the arc is reachable through normal play, spans multiple years,
and has meaningfully different outcomes. Choices affect authoritative relationships,
wellbeing, time or money where existing systems support them; they are remembered
in the diary and saved state. Each required choice has a viable fallback. Missing
or deceased participants have explicit behavior, and a later life can encounter
the family legacy. Verify complete routes and cold restore before calling the
slice complete. Extend the current narrative/simulation owners and data format;
keep household processing bounded rather than scanning the world for each choice.

**Verified 2026-09-27:** *The Time We Owe* and *A Place at the Table*,
11 chapters and 30 responses. All 21 desktop regressions passed, including three
complete routes, later-life memory, payments, free alternatives, cast loss and
binary hydration. A full-catalog graphical run discovered the arc in 2004,
continued it in 2005 and passed repeated cold Continue with exact saved state.
See [R05 evidence and limitations](docs/LIVING-HOUSEHOLDS.md). The initial second
consecutive Age Up failure was repaired in the [R07 input follow-up](docs/AGE-UP-INPUT.md);
longer lifetime and live-display checks remain open.
Portrait is not included in this verification.

Deeper content is the aim, not a fixed chapter quota. Use playtesting to decide
whether the next addition should be caregiving, sibling conflict, a partnership,
or another household situation before committing a larger batch of stories.

### R06: Carry that same family arc into Portrait

**Done when:** the shared gameplay port preserves saves, cast, actions, and lazy
startup dependencies; choices and history remain readable and reachable at
420×900 and 360×640. Check touch scrolling, Android Back, interrupted/resumed play,
and the exact APK on a phone. Record desktop-preview and device results separately.

## Later: make continued development easier

### R07: Improve performance against reproducible measurements

**Verified input repair, 2026-09-27:** navigation refreshes were cancelling a held
second click by removing focus. Visible navigation now retains focus. The new
regression failed before the fix and passes after it; all 22 desktop regressions
pass. A household completed three consecutive years, cold Continue, three more
years and another cold Continue. Narrative newborn entry completed two consecutive
years. See [input evidence](docs/AGE-UP-INPUT.md). Portrait has not received this fix.

**Next:** the continued household's live diary and balance labels lagged behind
its authoritative saved state. Verify those projections update after each year
and care payment without requiring a restart. Retain the original failed-input
fixture and the successful cold-restore evidence when fixing presentation.
Profile cold startup, entry into a life, repeated age-ups, and a longer session
before choosing the next bottleneck. Preserve the earlier under-10-second creation
menu goal as a target, not an achieved result; older phone measurements do not
certify the current build. Record device, build, route, multiple samples, memory,
and the timing boundary. A completed improvement must show a repeatable benefit
without dropping simulation phases, content, save fidelity, or readable feedback.

Use those measurements to choose a small dependency reduction or an extraction
from `MainScene.gd`/`GameState.gd`. Avoid turning this milestone into a broad rewrite.

### R08: Let another contributor add a story safely

Build on the existing authored JSON and mod/content owners. Provide a small sample
pack, supported schema/version notes, and validation for cast roles, missing nodes,
cycles, costs, and safe deadline choices. A new contributor should be able to add
one working arc using the guide without modifying core gameplay code. Verify old
saves and built-in stories still work. Defer a visual editor or marketplace expansion
until the basic authoring workflow has been used successfully.

## Keeping this roadmap alive

At the end of each roadmap task, update its status and the log below with a commit,
what was verified, and the smallest next action. Keep one bounded item active per
task. If blocked, name the concrete missing input and identify independent work
that can continue. Do not leave `In progress` after a task stops without a handoff.

Keep this file aligned on both active branches, including failures and reopened
items. Review priorities when a milestone completes or new evidence changes the
plan. Prefer one playable improvement or reproduced/fixed defect per change over
a growing list of unfinished systems. A documentation update does not require
rerunning gameplay; a gameplay change follows the checks in `AGENTS.md`.

| Date | Item | Task / branch / commit | Outcome and next action |
| --- | --- | --- | --- |
| 2026-09-26 | Baseline | Desktop `32ad0fb`; Portrait `ebaf71c` | Shared Lives implemented and ported, with the documented validation limits. Next shared implementation item: reproduce R01 on desktop. |
| 2026-09-26 | Planning | Shared roadmap on both Shared Lives branches | Priorities and completion criteria recorded. R01–R08 remain unclaimed; no new gameplay or crash fix is claimed here. |
| 2026-09-27 | R01 | Save/continue task; desktop `e2424ff`, Portrait `e538708` + `74e8b07` | Verified: hydration progress, projection scheduling, company banking, and mobile Continue update. 19 desktop and 23 Portrait regressions pass. New and existing saves passed separate-process Continue, age/save, and repeated restore checks. See [cold-restore evidence](docs/COLD-RESTORE.md). Next: desktop R04 readiness and R05 content; Portrait creation gaps, R02, and R03 remain open. |

| 2026-09-27 | R04 | Desktop readiness and Living Households task, `codex/shared-lives-desktop` | Desktop functional readiness complete at `8ccfd37`: 20 regressions, full-catalog founder/heir routes, declined/failed payments, graphical discovery and repeated cold Continue, clean Linux package and content hashes. See [readiness evidence](docs/SHARED-LIVES-READINESS.md). Portrait and public publication remain open. |

| 2026-09-27 | R05 | Living Households task, desktop `c02f528` | Verified desktop first slice: 11 chapters, 30 responses, three complete routes and a later life; all 21 regressions pass. Full-catalog graphical discovery, paid choice, next-year follow-up and repeated cold Continue preserve cast, money and history. Clean Linux package and all three content hashes verified. See [R05 evidence](docs/LIVING-HOUSEHOLDS.md). Next: R06 after Portrait readiness; investigate uninterrupted second Age Up under R07. |

| 2026-09-27 | R07 | Push and continue task, `codex/shared-lives-desktop` | Verified the bounded desktop input repair after pushing both development branches. UI focus removal cancelled held mouse/keyboard input; visible navigation retains focus. All 22 regressions pass; Household 3 years + cold Continue + 3 years + cold Continue and Narrative 2 years pass. Next: live diary/balance refresh during continued play, then broader profiling. See [R07 evidence](docs/AGE-UP-INPUT.md). |

For a new task, start with: **“Read AGENTS.md, docs/AGENT-HANDOFF.md, and ROADMAP.md;
inspect the target checkout; take an open item selected with the user, reproduce it,
and leave a verified result or a precise handoff.”** The user's current task
always takes precedence over this suggested queue.
