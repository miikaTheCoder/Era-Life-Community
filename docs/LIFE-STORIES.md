# Life Stories & Legacies — first content release

Six persistent stories connect ordinary life decisions to later consequences:

| Story | Starts when | Recurring cast |
| --- | --- | --- |
| The Promise at the Gate | Age 8–15, with an existing friend within five years of your age | That childhood friend |
| The Family Loan | Age 16–28, with an adult relative able to offer the loan | A parent or sibling |
| The Door Someone Opened | Employed, age 18–55, with an older employed coworker | That mentor |
| When Roles Change | Adult, with a living parent aged 55+ | That parent |
| Someone from Before | Adult, with completed Crime World work and a known organization contact | That accomplice |
| The Name You Inherited | Adult, with a parent's recorded story and a surviving participant | Someone who remembers the parent |

The catalog has **27 chapters, 82 responses, and 125 complete choice routes**.
These are authored routes, not a claim of 125 different simulation outcomes.
Each story has context for Ancient, Medieval, Industrial, Modern, and Future eras.

## Playing

Start or continue an ordinary life. Eligible chapters appear in **Pending
Situations**, labelled **Life Stories**. Choose a response, then continue living.
Follow-ups arrive one to six game years later and recall the earlier decision.
The original participant stays attached to the story. Stories do not invent a
friend, relative, colleague, or criminal connection to meet their requirements.

There are at most two active stories per controlled person and at least two years
between new story starts. A person encounters each story at most once. A chapter
stays open through the displayed response window; after that, its authored free
default takes effect. Closing the popup does not make a choice. Waiting in real
time does not advance the deadline.

Responses can transfer money between participants, change their relationship,
affect health, mental health, smarts, or work performance, and leave a remembered
family legacy. An unaffordable transfer leaves the chapter open. Loan amounts are
fixed using the era at the story's start, including after an era transition.
These are narrative family promises, not additional formal Bank/Debt contracts.

Story choices enter the existing diary and memory authorities. When a participant
dies, the story closes with a remembered unfinished conversation. A temporarily
unloaded participant is not replaced. Switching to a descendant can reveal a
parent's recorded choices through The Name You Inherited; the earlier story's
original surviving participant and legacy are retained.

## Ownership and persistence

- `project/systems/narrative/LifeStoryEngine.gd` owns story eligibility, casting,
  chapter transitions, deadlines, effects, and history.
- `project/data/life_stories.json` contains the writing, choices, era context,
  prerequisites, delays, and effects. No scene paths or executable scripts belong
  in content definitions.
- `ScenarioRuntimeContractEngine` loads the story owner lazily after a playable
  life is ready. `PendingSituationsEngine` services it during normal simulation
  maintenance and uses the existing popup, choice, and result routes.
- `scenario_state.life_stories` is versioned authoritative state. String actor
  keys and explicit integer conversion tolerate JSON save round trips. Runtime
  popup contracts are projections and can be rebuilt from saved story state.
- Compact checkpoints explicitly retain story state and recurring cast outside
  the family graph, subject to the existing 256-person checkpoint limit.
- Story servicing pauses during age-up work, loading, and background hydration.
  It processes the controlled person's small story set once per actor/year/age.
  Casting uses indexed people from existing relationship or organization lists.
- Monetary transfers use BankEngine. Its opt-in legacy import seeds only a newly
  created participant account; an existing empty account is never refilled.

Desktop and Portrait use the same content and gameplay files. Portrait keeps its
mobile shell and lazy startup path. The expansion does not depend on the separate
Begin Adventure entry. Export presets include raw `data/*.json` files.
Portrait's pending viewer allocates the available height to the story and keeps
responses in a bounded scrolling area. Calendar deadlines remain accurate when
an open chapter is carried into a later year.

## Authoring another story

Give the story a stable `id`, `title`, `category`, `cast`, `eligibility`, `start`,
and `nodes` dictionary. Each node has a `title`, `text`, `deadline`, `default`, and
`choices`. Each response has an `id`, `label`, and `result`; optional `next` and
positive `delay` lead to another node. Omitting `next` finishes the story.

`{person}` is replaced by the fixed participant's saved name. `transfer` is an
amount in Modern-era units: positive means the participant pays the player;
negative means the player pays the participant. `relationship` changes the pair
through RelationshipEngine. `stats` supports `smarts`, `mental_health`, `health`,
and `job_performance`. `legacy` is a saved family-history tag; `outcome` names a
completed story. Each chapter must have a free default. Cycles, unreachable
chapters, duplicate IDs, missing destinations, and unknown stats are rejected.

Keep IDs stable when revising a released pack. Removing a story leaves its saved
state untouched so a compatible catalog can restore it later. Breaking changes
to node IDs or state structure require a migration; this release uses version 1.

## Verification

Use Godot **4.4.1 stable**:

```sh
python3 scripts/test-headless.py
python3 scripts/check-structure.py
python3 scripts/code_map.py --write
python3 scripts/code_map.py --check
bash scripts/test-life-stories.sh
# In the Portrait checkout:
ERA_PORTRAIT=1 bash scripts/test-life-stories.sh
```

The focused regression follows all 125 authored routes through the real pending
and resolution owners. It checks bank transfers, invalid and repeated choices,
failed-payment atomicity, era-stable amounts, checkpoint serialization and
hydration, cast identity, delayed admission, deadlines, death, pacing, and an
actual switch from a parent with recorded choices to a descendant.

The graphical harness uses a disposable Household save, adds one known childhood
friend, opens the story through the normal pending viewer, clicks its response,
checks a single diary entry, then ages and saves. The same fixture runs through
Portrait's inherited touch/layout harness.

Existing project limitations still apply: these checks do not certify a full
birth-to-death playthrough or all cold-restore lifecycles. The scoped Android
hardware check is recorded below.

### Local validation, 2026-09-22

- Desktop: **18/18** headless checks passed, including all **125** authored routes
  (`build/tests/headless-x7ffjcxz`).
- Portrait: **22/22** headless checks passed (`build/tests/headless-b4e5bvbh`).
  After the final deadline and reading-space adjustments, the story, mobile
  panels, scrolling, and portrait checks passed again (**4/4**,
  `build/tests/headless-blj3goru`).
- Graphical story → response → Age Up → Save checks passed on desktop
  (`/tmp/eralife-stories-X1p14A`) and Portrait at **420×900**
  (`/tmp/eralife-stories-7obcHz`). Screenshots in each profile were inspected.
  Portrait's temporary test window was floated and resized; no desktop
  configuration was changed.
- Structure and regenerated code-map checks passed in both checkouts.
- Linux release archive: `build/EraLife-linux-x86_64.tar.gz`. The exported game
  successfully loaded the shipped runtime and all six story definitions.
- Portrait performance preview: `build/android/EraLife-portrait-android-performance.apk`
  in the Portrait checkout. Android signature verification passed; its catalog,
  story runtime, and mobile layout files match the verified source byte for byte.
  This APK uses the existing local test key. It was installed in place on the
  Honor 400 Lite for the hardware check below.

The graphical runs still emit the project's documented `snapshot_not_found`
diagnostic during successful checkpoint commit and resource-leak warnings at
shutdown. No GDScript failures occurred in the story checks. See
[existing desktop limitations](DESKTOP-GAMEPLAY.md) for the broader save/runtime
validation context.

### Honor 400 Lite hardware check, 2026-09-22

Tested the ARM64 performance APK over wireless ADB on HONOR ABR-NX1,
Android 16, at 1080×2412. Existing application data was retained. A disposable
Household character, Avery StoryTest, was used for the check.

- Household creation and native keyboard input completed.
- The Family Loan appeared through Me → Pending Situations, with generated
  relative Adrian StoryTest as its participant. The chapter and its choices
  were readable on the phone.
- Accepting the loan increased the main balance from $10,000 to $10,600 and
  produced one story diary entry. The situation closed after one choice.
- Age Up advanced the character from 25 to 26, to year 2001; Save completed.
- The backed-up binary save decoded successfully with balance $10,600, the
  original cast ID 2, one acceptance recorded in year 2000, and repayment
  scheduled for year 2003. This checks the saved payload, not a completed
  cold restore on Android.
- Phone testing exposed a narrow Household create button and a desktop-width
  save picker. Portrait now gives the create button available width and keeps
  the picker inside the safe viewport. Android Back respects CanvasLayer order
  and closes the picker above the underlying menu. The updated graphical story,
  age, save, picker-bounds and Back checks passed at 420×900
  (`/tmp/eralife-stories-O4t1oi`). The mobile-panel and scroll regressions also
  passed again (**2/2**, `build/tests/headless-k1o45eyi`).

Remaining observations: the guest account screen's Continue button was disabled,
so a direct cold restore was unavailable through that screen. A separate attempt
through God Mode → Prepare world → Begin life caused a native SIGSEGV in
`libgodot_android.so` on the GL thread; Android recorded a null pointer
dereference. Its cause is unresolved, and phone cold-restore validation remains
incomplete. The character drawer also displayed its previous bank balance
immediately after the choice, although the main HUD and saved payload were
correct. The log contains missing emoji-font and `can_process` diagnostics.

Local phone evidence, including screenshots, the test save, Android exit info,
and native crash trace, is retained under `/tmp/eralife-phone-stories/`.
