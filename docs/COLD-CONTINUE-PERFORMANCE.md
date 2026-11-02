# Cold Continue performance

Investigation started 2026-11-02 from desktop `main` `5423b0c`, isolated branch
`t3/cold-continue-save-reliability`. No Portrait port or main integration is included.

## Reproduction boundary

The retained sibling fixture has completed sixteen simulation years, four sibling
choices, seventeen diary years, $9,750 personal funds and 1,348 world-feed entries.
Read-only source evidence is in the primary checkout's
`build/sibling-evidence/desktop` and `build/sibling-evidence/portrait`.
The historical desktop `restore-final.log` advances its world-feed cursor from
102 at 41.431 s to 1,240 at 101.622 s, with engine construction already complete.
It then fails the ordinary 90-second hydration gate. Portrait failures and its
240-second diagnostic results remain historical evidence, not desktop certification.

The new runner copies only the fixture's `data` tree into each isolated profile.
Each sample launches and exits a separate Godot process. Default samples start
from the same fixture; `--continue-profile` instead copies the preceding sample's
new save. Source profiles are never run in place. Logs and failed profiles remain
under this worktree's ignored `build/cold-continue/` directory.

The production service pump awaits `RenderingServer.frame_post_draw`, which the
headless renderer does not supply. The initial headless Continue attempt therefore
stopped at checkpoint resolution and was terminated. No production workaround was
added for this unsupported route. Regression scripts still run headlessly.
For real Continue and yearly simulation, `--offscreen` uses `xvfb-run -a` with a
private 1440x900 display, TCP disabled, and `LIBGL_ALWAYS_SOFTWARE=1`. It never
connects to the owner's desktop. This is automated offscreen evidence, not
interactive visual playtesting or phone certification.

Host: AMD Ryzen 5 5600X, Linux x86_64. Pinned executable:
`/home/nextg/opencode-sandbox/Era-Life-Community/build/tools/godot-4.4.1/Godot_v4.4.1-stable_linux.x86_64`,
version `4.4.1.stable.official.49a5bc7b6`.
Timing runs are sequential with no concurrent regression suite. This is process
coldness with normal OS file caching, not a dropped-cache or reboot benchmark.

The profiling script measures from entry into the test's `_restore` method,
including decoding the expected checkpoint and awaiting title availability, to
completed background hydration. It separately records first playable frame to
hydration completion, corresponding to the unchanged 90-second gate. Stage times
are sampled by the existing 100 ms polling loop and are approximate. Python also
records process wall time, including startup, verification and shutdown.

## Verification commands

```sh
export GODOT_BIN=/home/nextg/opencode-sandbox/Era-Life-Community/build/tools/godot-4.4.1/Godot_v4.4.1-stable_linux.x86_64
python3 scripts/profile-cold-continue.py /path/to/retained/profile build/cold-continue/new-samples --samples 3 --offscreen
python3 scripts/profile-cold-continue.py /path/to/retained/profile build/cold-continue/new-years --samples 2 --years 6 --continue-profile --offscreen
python3 scripts/test-headless.py
python3 scripts/check-structure.py
python3 scripts/code_map.py --write
python3 scripts/code_map.py --check
git diff --check
```

Use a new output directory each time. The runner refuses existing destinations.
The initial restricted import failed with sandbox socket errors. Its retained log
is `build/tests/headless-cr1rn520/import/output.log`; the permitted isolated import
and original progress test passed in `build/tests/headless-1wji7xs1/`.

## Baseline and defect regression

Three sequential original-code samples, in seconds:

| Sample | Process wall | Restore entry to complete | First frame to complete | History stage |
| --- | --- | --- | --- | --- |
| 1 | 114.666 | 92.087 | 88.491 | 69.182 |
| 2 | 113.570 | 91.807 | 88.071 | 68.841 |
| 3 | 113.569 | 91.229 | 87.594 | 68.552 |

All three narrowly met the normal hydration timing gate on this host. This
reproduces the slow stage, not the historical intermittent timeout on demand.
Samples 1 and 2 failed new test-only relationship comparisons because JSON
numeric IDs were compared as strings (`1.0` versus `1`). The harness now compares
JSON-normalized values. Sample 3 passes the complete fidelity checks. Those two
failed checks and their measured timings remain retained, not silently relabeled
as successful verification. Logs: `build/cold-continue/before-offscreen/`.

The focused regression fails on original code with 258 slices for 257 history
entries (`feed-before/output.log`), then passes with nine slices after the fix
(`feed-after/output.log`). Both are under `build/cold-continue/`.


## Cause and bounded change

The `checkpoint_entity_state` stage 4 normalizes just one world-feed row each
service quantum, even though normalization is cheap. Each quantum repeats the
controlled-actor snapshot/verification and waits for another renderer frame.
Long histories therefore pay thousands of guard and scheduling costs. The retained
failure and new offscreen measurements both isolate this stage.

The bounded unit is a batch of at most 32 history rows, with a 1 ms
work deadline checked after every row and guaranteed progress of one row. The
work clock starts after the actor guard: using the already-exhausted outer clock
would retain one-row progress and the original bottleneck. The outer report still
includes the full guard, batch and verification cost. This grants at most 1 ms of
normalization work plus an indivisible row, rather than raising a loader timeout.
The guard still surrounds every batch and observes legitimate changes between
quanta. It does not skip a phase, reduce population or content, change save format,
or bypass the existing normalizer. Other hydration stages are unchanged.

`test_checkpoint_feed` uses the real normalizer with a deliberately expensive
actor guard, mixed legacy entries, chronology repair and custom metadata. It
checks ordered complete results, bounded batches, per-row deadline enforcement,
empty histories and interleaved relationship changes. The cold harness extends
the existing smoke fixture's identity, diary, account, cast, ownership and
same-year no-duplicate-settlement checks with exact normalized history and all
saved actors' relationship arrays and scores.

## Post-fix timings

Same fixture and sequential private-display setup, no dropped caches:

| Sample | Process wall | Restore entry to complete | First frame to complete | History stage |
| --- | --- | --- | --- | --- |
| 1 | 68.533 | 45.096 | 41.493 | 3.095 |
| 2 | 48.849 | 25.507 | 22.014 | 2.987 |
| 3 | 47.904 | 25.797 | 22.169 | 3.117 |

All three pass the normal 90-second gate and complete state comparisons.
Logs: `build/cold-continue/after-offscreen/`, including `results.json`.
Median first-frame-to-complete time falls from 88.071 to 22.169 seconds,
about 75%. Median history-stage time falls from 68.841 to 3.095 seconds,
about 95.5%. The first post-fix engine-graph stage took 31.913 seconds, compared
with 12.430 and 12.609 seconds in the other samples. Its cause is not established;
retain the variation rather than attributing all wall-time differences to batching.
These results establish the history bottleneck improvement, not a universal
startup SLA or a fix for every Portrait timing failure.

## Real-year save fidelity

The sibling fixture ran two six-year sessions through the existing Age Up input
and simulation owners, with a separate-process cold restore between them. Each
year checks that health, school/career and diary processing completed. The first
save reached age 57/year 2022 with 23 diary years; the second reached age 63/year
2028 with 29 diary years and all four sibling decisions. A third process restored
that final save exactly. No year was advanced by editing a dictionary or calendar.
The earlier retained fixture had already completed sixteen real years, so this
continues that life through 28 simulated years without claiming a birth-to-death
playthrough or natural-player pacing validation.

Evidence: `build/cold-continue/sibling-years/sample-{1,2}/output.log` and
`build/cold-continue/sibling-final/sample-1/output.log`. Both six-year runs and
the final zero-year restore passed. The profile data and newly written binary
saves are retained alongside the logs. Original source fixture hashes and checkpoint summaries
are identified in `build/cold-continue/fixtures.json`.

The older R01 business fixture separately ran two six-year sessions and a final
zero-year cold restore. Its initial age 36/year 2001 save restored $8,800 personal
funds and $1,470 company reserves. The 2007 cold restore retained $3,124 reserves;
the final 2013 restore retained $4,658 reserves, $8,800 personal funds, age 48,
fourteen diary years and 293 world-feed entries. Each restore compares the full
saved venture record, including ownership stakes, cast and settlement history,
and calls same-year servicing twice to prove neither balances nor history change.
All three processes passed. Evidence: `business-years/` and `business-final/`
under `build/cold-continue/`. These are real simulation and authored-default
outcomes, not a formula substituted for the economy owners.

The exact cycle commands after the three-sample comparison were:

```sh
python3 scripts/profile-cold-continue.py /home/nextg/opencode-sandbox/Era-Life-Community/build/sibling-evidence/desktop build/cold-continue/sibling-years --samples 2 --years 6 --continue-profile --offscreen
python3 scripts/profile-cold-continue.py build/cold-continue/sibling-years/sample-2 build/cold-continue/sibling-final --samples 1 --offscreen
python3 scripts/profile-cold-continue.py /home/nextg/opencode-sandbox/Era-Life-Community/build/r01/desktop-business-existing-fixture build/cold-continue/business-years --samples 2 --years 6 --continue-profile --offscreen
python3 scripts/profile-cold-continue.py build/cold-continue/business-years/sample-2 build/cold-continue/business-final --samples 1 --offscreen
python3 scripts/profile-cold-continue.py /home/nextg/opencode-sandbox/Era-Life-Community/build/sibling-evidence/portrait build/cold-continue/portrait-fixture-on-desktop --samples 1 --offscreen
```

The copied Portrait 2016 fixture also passed on desktop, restoring age 51,
seventeen diary years, 1,351 history entries, $9,750 and the exact saved cast,
relationships and story state. Its log is
`build/cold-continue/portrait-fixture-on-desktop/sample-1/output.log`.
This is a desktop compatibility test, not a Portrait runtime or phone test.
All three original source fixture save hashes were rechecked unchanged.

## Final verification

All 25 headless regressions pass, including the new feed regression, with the
pinned Godot 4.4.1 import. Full retained logs:
`build/tests/headless-q1r24r0s/`; runner summary:
`build/cold-continue/full-suite.log`. Structure passes (374 scripts, 365 classes,
21 direct resource links). The generated code map was regenerated and checked;
`git diff --check` passes. Static check logs are `structure.log`, `code-map.log`
and `diff-check.log` under `build/cold-continue/`.

The focused regression's intentional pre-fix failure, restricted import failure,
unsupported headless Continue attempts and two initial harness comparison failures
are preserved above. No final regression or cold-cycle check remains failing.
Keep both `build/cold-continue/` and `build/tests/headless-q1r24r0s/` when freezing
or retiring the isolated worktree, because these local evidence files are ignored
by Git. Source, tests, runner and this report are committed together for review.

## Limits and review handoff

- This work fixes the demonstrated desktop history bottleneck. It does not
  establish an under-ten-second startup target or eliminate constructor variance.
- Historical timeouts remain preserved. New baseline samples narrowly passed the
  timing gate; do not describe them as fresh timeout reproductions.
- The unsupported headless Continue attempts (`baseline-1/` and `before/`) were
  terminated at the renderer-frame wait. They are not performance samples.
- The owner desktop stayed locked and unused. Offscreen UI/input and text checks
  are automated evidence only. No screenshots were visually certified, no phone
  was accessed, and no interactive whole-life playtest was performed.
- Portrait source was not modified. Loading a copied Portrait save on desktop
  is compatibility evidence only, not a Portrait performance or device result.
- Existing `snapshot_not_found` diagnostics, Xvfb input-method warnings and
  resource-at-shutdown warnings remain. The runners reject other engine/script
  errors and retain unsuccessful logs.
- No package, push, PR, integration or deployment is included. The parent must
  freeze this isolated commit for council review, address blocking findings, and
  then integrate intentionally. Shared roadmap synchronization and a separately
  verified Portrait port remain follow-up work.


## Council and integration, 2026-11-02

All three independent council members passed exact commit `018efd9`; see
[the council record](COUNCIL-COLD-CONTINUE.md). The parent fast-forwarded this
unchanged production commit into `main`, merged local documentation, and verified
that unrelated Web source hashes remained unchanged. A new combined full suite
passed all 26 regressions, including the pre-existing Web presentation test.
Logs: primary `build/tests/headless-bzdntd2o/`. Structure, regenerated code map,
code-map check and whitespace checks pass.

A further separate-process private-Xvfb sample on the combined main tree passed
the unchanged hydration timing gate and exact save comparisons. Its output is in
primary `build/reliability-evidence-20261102/integration-cold-restore/`. This is an
integration check, not another controlled before/after benchmark. The reviewed
25-test isolated suite and original failures remain distinct from this new result.

Before retiring the isolated checkout, the parent copied and hash-verified all
1,475 retained evidence files into primary `build/reliability-evidence-20261102/`.
The original `build/cold-continue/` and `build/tests/headless-q1r24r0s/` relative
paths are preserved below that archive, with `SHA256-MANIFEST.json` beside them.
Local-change backups are in `build/recovery/reliability-integration-20261102-wpgqxkk_/`.

Portrait receives documentation only in this step. No native Portrait performance,
phone, interactive visual, public release or deployment result is claimed. The
next content task starts from the integrated fix. Optional council suggestions
remain recorded as follow-ups; they were not blocking conditions for this commit.
