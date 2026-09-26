# EraLife roadmap

Updated **2026-09-26**. This is the shared plan for desktop EraLife and EraLife
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
| Desktop validation | 19 headless regressions and the focused funding → Assets → age → save flow passed; Linux build exported |
| Portrait validation | 23 headless regressions plus final focused checks passed; content flow inspected at 420×900; signed APK built, not retested on the Honor phone |
| Agent continuity | Shared handoff guide and entry links available on both active branches |
| Release status | Current work is on the Shared Lives branches. A push or an APK export does not mean it is merged, published, or fully device-verified |

These are dated results, not certification of future commits. The exact evidence
and limitations live in [Shared Lives](docs/SHARED-LIVES.md) and the
[agent handoff](docs/AGENT-HANDOFF.md). In particular, the focused Portrait content
smoke skips general drawer navigation; it does not clear the Menu/Back issue.

## Work queue

No implementation item is claimed by this roadmap-writing task. All items below
are **unclaimed**. When starting one, replace its status with `In progress`, record
the task/branch in the work log, and keep the change small enough to review.
`Queued` means prioritized; `Proposed` means the product direction needs refinement
before implementation. `Verified` requires the evidence in its completion criteria.

| ID | Item | Target | Status | Depends on |
| --- | --- | --- | --- | --- |
| R01 | Reliable save → cold restart → continue | Desktop, then Portrait | Queued: first shared task | None |
| R02 | Character / Back / Explore navigation | Portrait | Queued | None; can be an independent fix |
| R03 | God Mode → Begin Life phone crash | Portrait | Queued; device access needed for final verification | None; keep separate from R02 |
| R04 | Playtest and package the Shared Lives milestone | Desktop first; Portrait separately | Queued | Desktop: R01 desktop checks. Portrait: R01 Portrait checks, R02, R03 |
| R05 | Living Households: one complete family arc | Desktop | Proposed next content chapter | Desktop R04 release-ready checks |
| R06 | Port Living Households and test it on a phone | Portrait | Proposed | R05 and Portrait R04 |
| R07 | Measured startup and lifetime performance | Desktop + Portrait | Proposed | Use stable routes from R01–R03 |
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

## Next: Living Households (proposed)

### R05: Make the people at home affect the life you are building

**Proposed first slice:** one recurring family arc about dividing time between
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

For a new task, start with: **“Read AGENTS.md, docs/AGENT-HANDOFF.md, and ROADMAP.md;
inspect the target checkout; take R01 (or the user-selected item), reproduce it,
and leave a verified result or a precise handoff.”** The user's current task
always takes precedence over this suggested queue.
