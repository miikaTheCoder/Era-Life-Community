# R04: desktop Shared Lives readiness

Checked 2026-09-27 on `codex/shared-lives-desktop`, after R01. This is a local
Linux playtesting build. Publication and Portrait readiness remain separate.

## What was exercised

The full catalog remained enabled. In the regression fixture, earlier eligible
stories delayed the founder offer until year 2006. The founder answered each
chapter at its authored date and handed over the original 60% stake in 2018.
After ordinary story competition on the heir, the inherited continuation finished
in 2029. The original company, cast and account survived; reserves were $7,437,
and the saved legacy was `a_living_family_business`.

The route uses the real story admission, pending-resolution, relationship, diary,
banking and company owners. Its fixture advances the story calendar and ages
participants; it is not a 29-year whole-world simulation certification. No story
catalog filtering, forced chapter assignment or invented inheritance is used.

A frozen-account investment was rejected without creating a company, changing
money or committing story consequences. Reopening the account allowed the same
offer to proceed. An unknown response was rejected; declining was playable and
did not reappear over four more years. Existing Shared Lives regressions cover
every authored response, including unaffordable expenses and unavailable heirs.

The graphical harness now also keeps the full catalog. It enters a generated
Household, supplies two known contacts in its isolated test profile, and lets the
normal eligibility rules choose the offer. The visible chapter explains the
$1,200 and $400 investments, payer, ownership split, free decline and calendar
deadline. Funding, Assets, Age Up and Save are exercised through UI input.
R01's exact bank/history checks run in later, separate Continue processes.

This establishes discovery for a qualifying household. It does not measure how
often an arbitrary generated person naturally acquires those contacts. Players
without an adult friend/sibling and a distinct older parent/coworker remain
ineligible, as described in [Shared Lives](SHARED-LIVES.md).

## Reproduce and report feedback

```sh
python3 scripts/test-headless.py test_shared_lives_readiness test_shared_lives
bash scripts/test-shared-lives.sh cycle /tmp/eralife-r04-example
bash scripts/build.sh linux
```

Use a new isolated directory for a cycle. For player feedback, include the source
commit from `BUILD_INFO.txt`, story/chapter title, actor age and year, selected
response, expected and observed balances, and whether Continue followed a full
process exit. Retain a copy of the failing save before retrying.

## Evidence and package

Readiness regression: `build/tests/headless-nfpdpa0m`. The graphical full-catalog cycle passed creation,
save, cold Continue/age/save and a second cold Continue. Its logs, saves and
inspected screenshots are retained in `build/r04/desktop-full-catalog`. The
full desktop suite passed all 20 tests in `build/tests/headless-5y6yvnos`.
Structure, code-map and whitespace checks passed. Packaging is the remaining
desktop readiness step.

Known limits: resource cleanup warnings and `snapshot_not_found` diagnostics;
long lifetime performance, native Windows/macOS playtesting and asset provenance
review for publication remain open. Portrait's creation, Back and device-crash
issues remain on its roadmap. This task does not mark those checks as passing.
