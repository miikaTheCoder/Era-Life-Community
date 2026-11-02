# Current development loop

Started 2026-11-02 at the owner's request. This bounded queue covers work that
can proceed while the desktop is locked and the Honor phone is unavailable.
It does not schedule recurring work or expand the roadmap indefinitely.

1. **Desktop reliability complete.** History normalization batching `018efd9`
   preserves all history and actor guards. Three council members passed.
   Controlled before/after samples and longer sibling/business save cycles are
   retained in [performance evidence](COLD-CONTINUE-PERFORMANCE.md).
2. **Desktop content complete.** *Room for Two Futures* and *The Plans They Kept*
   add nine chapters and 26 responses. Round-1 blockers were reproduced and
   fixed. All three members passed corrected `954645b`, now integrated unchanged.
   All 27 combined regressions and an additional exact cold restore, visible
   payment and one-year save pass. See [content evidence](PARTNER-STORIES.md)
   and [council record](COUNCIL-PARTNER-STORIES.md).
3. **Portrait shared port next.** Apply only these approved shared changes to
   the existing Portrait checkout, preserving lazy startup, mobile shell,
   touch controls and branch-specific serialization/harnesses. Verify native
   previews at 420x900 and 360x640, full target regressions and separate-process
   save/Continue. Preserve the normal hydration timing gate. Consult all three
   council members on the completed port. Actual phone verification stays open.
4. **Mobile Web separately.** Audit the existing unfinished R09 changes without
   altering them during discovery. Address only independently reproducible
   issues that can be verified without the owner's phone or desktop. If none
   is established, retain the phone retest as the next action. Native contract
   tests do not establish browser touch, keyboard or storage behavior.

## Coordination and evidence

Each implemented feature follows acceptance criteria, implementation, checks,
frozen-artifact council review, bounded corrections and local integration.
Council members are Security (GPT-6 Astra), UI/UX/Design (GPT-6.1 Sol) and
Technical (GPT-6 Astra). Changed review scope requires fresh affected reviews.

The parent coordinates T3 delegates. Use Godot 4.4.1 stable, private Xvfb and
isolated copied save profiles. Do not run heavy tests in parallel with timing
checks. Do not use the locked desktop or phone. Do not reset, stash, commit or
overwrite another task's changes, or read credentials or `.aws`. No push,
public release or deployment is part of this loop.

Reliability evidence is archived in primary `build/reliability-evidence-20261102/`
with 1,475 verified files. Story evidence is in `build/partner-evidence-20261102/`
with 1,288 verified files, preserving original source-relative paths. Original
failures and diagnostics remain retained. Combined main suite logs are
`build/tests/headless-_y9erp29/`; the added story integration check is in the
story archive's `integration-check/`. Existing Web source hashes are preserved.

The story selection came from source coverage and retained fixtures, not a
fresh player journey. The partner's independent aspiration fills a catalog gap;
refusal and respectful independence are complete outcomes. Payments cannot buy
agreement. Cast identity and public inherited consequences remain authoritative.
See [Partner Stories](PARTNER-STORIES.md) for the implemented contract and scope.

## Deferred verification

- Interactive desktop playtesting of a full natural family journey and pacing.
- Honor checks of the exact signed Portrait APK, including cast, choices,
  age/save and cold Continue.
- Real-phone mobile Web readability, keyboard, scrolling and save/Continue.
- iOS Safari and other unavailable platforms.

Stop the queue when achievable work is complete and only external checks remain.
Report exact next actions without claiming deferred checks passed.
