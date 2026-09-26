# R01: save, cold restart, Continue

Work started **2026-09-27** on `codex/shared-lives-desktop`. R01 remains in
progress until the desktop and Portrait checks below are complete. Follow
[ROADMAP.md](../ROADMAP.md) for its current status.

## Reproduction and repairs

The unmodified desktop gameplay at `c277a93` created, aged, and saved an isolated
Household life successfully. A second process reached the playable first frame,
then failed `Checkpoint hydration did not finish` after 90 seconds. Actor 1
remained at age 9, year 2001. Engine construction finished all 248 steps, but the
hydration queue retained all 12 items with `core_identity` at its head.

The controlled-actor invariant snapshot consumed more than the loader's 1 ms
budget. The next budget check then declined the actual loading work, repeatedly.
The loader now guarantees one bounded unit of progress once a slice is admitted.
Actor protection, chunk caps, and total-duration reporting remain active. The
regression deliberately makes the invariant snapshot exceed the live budget.

Continuing beyond that failure exposed a concurrent projection crash. Two cold
restore attempts crashed while UI projection workers accessed the runtime being
constructed and hydrated on the main thread. One logged a cross-thread node
notification error. The native core confirms a worker-thread crash, but the
official binary lacks symbols, so its exact native function is not established.
Checkpoint projections now execute through the existing bounded main-thread step
path. Other projection entry paths retain their existing scheduling.

The first complete business restore exposed a third problem: the compact save
contained the company bank account, but a nonempty partial save-contract registry
omitted its hydration contract. The company, cast, ownership, and history survived;
its reserves appeared as zero. The resolver now includes the compact checkpoint's
bank and diary owners when missing, preserving existing contracts. A partial-registry
regression reproduces the missing account before this repair.

## Repeatable checks

Use Godot 4.4.1 and a graphical display. Each command exits fully before starting
the next process. Use a fresh profile for creation, and retain it for Continue:

```sh
bash scripts/test-shared-lives.sh cycle /tmp/eralife-cold-example
# Existing isolated fixture:
bash scripts/test-shared-lives.sh restore /path/to/copied-test-profile
```

The restore harness compares saved identity, age/year, diary, world history,
relationships, story records, business cast, ownership, settlement history, and
personal/company bank accounts. Repeated same-year business servicing must leave
company balances and settlement history unchanged. It then ages and saves again
unless `ERA_YEARS=0` is selected. A final cold restore checks that second save.

Run the same commands in the Portrait worktree with `ERA_PORTRAIT=1`, and verify
the actual 420×900 viewport. This focused content harness retains its documented
drawer-navigation exclusion. It cannot close R02 or certify an Android device.

```sh
python3 scripts/check-structure.py
python3 scripts/test-headless.py
python3 scripts/code_map.py --write
python3 scripts/code_map.py --check
git diff --check
```

## Evidence in this task

- Original desktop timeout: `/tmp/eralife-r01-desktop-baseline-live/restore.log`.
  The pre-fix profile is preserved separately in
  `/tmp/eralife-r01-desktop-existing-fixture`.
- Starvation regression failed before the repair in `headless-orytz6f_` and passed
  afterward in `headless-wxe3pzmn`, alongside Shared Lives.
- Checkpoint projection thread regression passed in `headless-b_l5z6lr`.
- Partial-registry business regression failed before its repair in
  `headless-iq0o5eee`.
- Original business fixture: `/tmp/eralife-r01-shared-existing-fixture`, copied
  before any successful cold restore. Its saved personal funds are $8,800 and
  company reserves are $1,470.
- The original failing Household save passed Continue, age, and save after the
  progress and projection fixes (`restore-main-projection.log`).

All 19 desktop regressions passed with the final repairs in `headless-c0fg00yq`.
The original `a174e11` Household fixture also passed cold restore, age, and save
(`/tmp/eralife-r01-historical-household`). The pre-fix business fixture restored
$8,800 personal funds and $1,470 company reserves exactly, aged, and saved
(`/tmp/eralife-shared-4OhhF6/restore-bank-fixed.log`). Baseline profiles are retained
in `build/r01/desktop-existing-fixture` and `build/r01/desktop-business-existing-fixture`.

The fresh desktop cycle passed creation, save, cold Continue, age/save, and a
second cold Continue: $8,800 personal funds and $1,470 then $1,740 company reserves,
with the same actor, cast, ownership, relationships, and history. The second restore
performed no additional age-up or settlement. See `build/r01/desktop-fresh`.

Portrait results and source commits will be recorded before R01 is marked verified. Phone verification, the
Portrait Back issue, full-lifetime play, and native Windows/macOS checks remain
separate roadmap work.
