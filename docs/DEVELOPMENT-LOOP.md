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
3. **Portrait shared port ready for council.** Candidate `a25cda8` preserves
   startup, shell, touch controls and branch-specific serialization. All 30
   regressions, six story processes at actual 420x900 and 360x640 windows, and
   three older-save cold restores pass the unchanged hydration gate. A reproduced
   freed-popup cast has a bounded fix. The signed APK is built but untested on
   Honor. Port evidence remains in the Portrait checkout pending review.
4. **Mobile Web configuration repair ready for council.** Read-only R09 discovery
   found the exported Godot virtual-keyboard path disabled. A one-option source
   shell repair passes the real JavaScript configuration/gate check, which fails
   before the fix. A fresh Web export, all 15 artifact checksums, delivered-shell
   configuration checks and three adjacent Godot regressions pass. See
   [keyboard evidence](WEB-KEYBOARD.md). Existing layout work is preserved.
   Native contract tests do not establish browser touch, keyboard or storage.

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
