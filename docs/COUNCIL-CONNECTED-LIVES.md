# Council: Connected Lives

Consultation `eralife-connected-lives-20261104-r1`.

Round-one artifact: desktop `main`, implementation commit `a4b8d0a` against base `7d90ed3`,
plus final documentation edits, identified by
`build/connected-lives-evidence/review-manifest.json`. The shared checkout was
frozen during that review. The authoring sample, validation command, new tests and
feature documentation are part of the scope.

The owner requested a finite loop for child ambitions, connections between
stories, a family chronicle, adult friendships and community story packs,
followed by council consultation. The [feature loop](CONNECTED-LIVES-LOOP.md)
records all tests, actual rendered checks, failures and limits.

Required members: Security, GPT-6 Astra; UI/UX/Design, GPT-6.1 Sol; The Nerd,
GPT-6 Astra. All use Codex with maximum reasoning and priority service.

## Round 1: REWORK REQUIRED: Back to the workshop.

All three members reviewed the frozen manifest and matched all 27 file hashes.
All returned `CHANGES_REQUESTED`. Their source findings are independent reviews;
the initial test logs and screenshots were supplied evidence, not tests rerun by
the reviewers.

- Security, GPT-6 Astra: authored text could enter BBCode parsers (P1), whitespace
  IDs could become unresolvable (P2), and replaced packs could charge a different
  price from a retained pending offer (P2).
- UI/UX/Design, GPT-6.1 Sol: an unanswered adult-friendship opening accepted
  reconciliation and increased affection without a player choice (P2).
- The Nerd, GPT-6 Astra: reinstated packs could exceed two active stories (P2),
  unavailable content consumed pending deadlines and waiting delays (P2), and
  noncanonical IDs could strand stories (P2).

The coordinator has repaired all six distinct defects and completed validation
before a fresh review. The
two wording/placement suggestions are also addressed: the original friend's
continuation says "Your earlier story", and pack-loading errors precede the
chronicle entries. Actual keyboard and wheel events pass after repairing the
dialog's focus traversal and its reading-area collapse on reopening.

New regressions reproduced all six defects before production changes in
`build/tests/headless-60amde7e`. Earlier test-authoring failures are retained at
`headless-_j2lt2y2` (type inference) and `headless-w_mb0jt0` (ineligible fixture).
The new test uses fresh Godot processes, binary checkpoints, actual hydration,
and retained popup projections through the runtime export/import API.

Repairs keep story state version 1. Optional suspension timing preserves cast,
history and remaining time. Existing active stories retain their slots before
paused stories resume. Pending contract revisions bind the validated definition,
saved price scale and deadline; changed or legacy offers are replaced, making
old buttons inert. Authored IDs are rejected rather than normalized. Story and
diary text render literally while owned headers and semantic colors remain.

All six required repairs pass `test_story_pack_safety`, including nine fresh
Godot-process restores. Final graphical verification exposed a shared Crime panel
conversion of opaque story contract IDs to numeric items. The actual pending
summary regression reproduces it in `build/tests/headless-vrvp31ga`; the panel now
preserves source contract IDs as text. The fresh full suite afterward passes
**30/30** in `build/tests/headless-zz6zvnch`. Earlier fixture failures and graphical
failures are retained and explained in the feature-loop evidence.

## Round 2: REWORK REQUIRED: Back to the workshop.

Consultation `eralife-connected-lives-20261104-r2` reviews the corrected source,
updated evidence and `build/connected-lives-evidence/r2/review-manifest.json`.
All three members checked all 32 reviewed-file hashes and 63 evidence hashes at
the start and end. Their votes are current for that frozen artifact:

- Security, GPT-6 Astra: `CHANGES_REQUESTED`. Two profile-switch diary consumers
  still assigned unescaped, precomposed diary text to BBCode-enabled labels.
  The ordinary diary repair did not cover these consumers. This is the remaining
  P1 text-boundary defect, requiring a real pointer-packet and cold-restore check.
- UI/UX/Design, GPT-6.1 Sol: `PASS`, no required changes. Player agency, pricing,
  attribution, visible error placement and supplied input evidence were accepted.
- The Nerd, GPT-6 Astra: `PASS`, no required changes. Capacity, suspension timing,
  canonical IDs, revision checks and persistence behavior were accepted.

The coordinator reproduced and repaired the remaining Security finding in the
round-three artifact below. The two passing votes did not override it. Fresh
affected reviews in round three resolved the objection.

Optional future coverage: combine capacity competition with cold restoration.
Generic `legacy` casting without an explicit `origin_story` also retains older
semantics that deserve clarification. Neither suggestion is a new required fix
or an expansion of this finite implementation loop.

Round-two desktop evidence: 30/30 full regressions; final chronicle fixture rerun;
child and original-friend five-year routes with two cold restores each; standard
Household smoke; 1440x900, 420x900 and 360x640 chronicle renders; actual keyboard,
wheel, Escape and focus return; and the standalone sample validator. The final
loading-error screenshot follows a fixture repair: after switching people it
must reopen through the shell's owner guard. Production code did not change
after the full-suite pass. Logs, screenshots and failed attempts are indexed in
[the feature-loop evidence](CONNECTED-LIVES-LOOP.md#council-corrections).

No native Portrait port, phone/browser runtime certification, push or release
is included in this desktop review. Existing Portrait edits are preserved, with
an appended status note in its roadmap and handoff.

## Round 3: APPROVED: The council gives its blessing.

Consultation `eralife-connected-lives-20261104-r3` reviews the full base-to-working-
tree change identified by `build/connected-lives-evidence/r3/review-manifest.json`.
The original implementation HEAD remains `a4b8d0a`; corrections are local.
All three members returned PASS for this exact artifact on 2026-11-04, with no
required findings. Each independently matched all 33 reviewed-file hashes and
131 evidence hashes at both start and end.

- Security, GPT-6 Astra: `PASS`. Literal diary rendering closes the remaining
  authored-text parser boundary; no new blocking security or data-integrity issue
  was found. Review: <t3-thread://v2/738566b5-10b3-4799-959f-324fd6c62621/thread:delegated-task:command%3Amcp%3A0cee0953-be63-4328-b45b-a72a9c73fde2%3Adelegate-task%3Aeralife-connected-lives-20261104-r3-A>
- UI/UX/Design, GPT-6.1 Sol: `PASS`. Literal text, meaningful choices, prices,
  restored history, readable chronicle and contributor guidance passed the
  finite desktop review. Review: <t3-thread://v2/738566b5-10b3-4799-959f-324fd6c62621/thread:delegated-task:command%3Amcp%3A0cee0953-be63-4328-b45b-a72a9c73fde2%3Adelegate-task%3Aeralife-connected-lives-20261104-r3-B>
- The Nerd, GPT-6 Astra: `PASS`. Diary ownership, fallbacks, suspension/capacity,
  offer revisions, payment ordering, cast retention and inheritance privacy
  support the verdict. Review: <t3-thread://v2/738566b5-10b3-4799-959f-324fd6c62621/thread:delegated-task:command%3Amcp%3A0cee0953-be63-4328-b45b-a72a9c73fde2%3Adelegate-task%3Aeralife-connected-lives-20261104-r3-C>

The remaining P1 was reproduced through real `prepare_profile_pointer_packet()`
output in live and cold-hydrated states. Both MainScene consumers now render
literal lines through the owned formatter, including cached and fallback text.
The local packet producer stores plain text consistently, and the adjacent
generation-switch fallback uses the same literal path. No history rebuild or
new authority is introduced.

Fresh validation passes: 30/30 full regressions with all nine cold safety cases,
four inspected profile-diary fixture images, standard desktop Household smoke,
and another real friendship year/save followed by cold Continue. Final state is
year 2006, age 41, $9,900 and three decisions. The focused rendered fixture uses
in-process hydration; the separate safety regression establishes cold processes.
All earlier source-confirmed findings, reproductions and finite-scope limits
remain recorded in [the feature-loop evidence](CONNECTED-LIVES-LOOP.md).

The reviewers inspected source, retained execution evidence and selected images;
they did not run Godot or change files. This is a scoped desktop verdict, not a
guarantee or phone/browser/performance certification. Runtime diagnostics and
shutdown warnings remain recorded. Optional future coverage is a full-scene
authored-text profile switch after cold Continue, and capacity competition across
a fresh-process restore. Neither is required to close this loop.

After all reviews completed, the coordinator rechecked every frozen hash and
updated only the roadmap, handoff, feature-loop and council documentation with
the outcome. Production code, tests and evidence remain exactly as reviewed.
The original round-three manifest is retained unchanged; its documentation
hashes describe the pre-verdict snapshot. The finite implementation loop is
complete. No push, release or Portrait gameplay port is included.
