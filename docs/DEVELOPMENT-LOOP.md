# Current development loop

Started 2026-11-02 at the owner's request. This is a bounded queue of work that
can proceed while the desktop is locked and the Honor phone is unavailable.
It does not schedule recurring work or expand the roadmap indefinitely.

## Order and completion rules

1. **Reliability first, complete on desktop; Portrait port remains open:** reproduce slow cold Continue, measure the
   responsible stage, implement a focused improvement where evidence supports it,
   and verify repeated separate-process restores and longer-play save fidelity.
   Preserve cast, story decisions, relationships, diary, ownership and money.
   Do not obtain a timing pass by extending a timeout or omitting simulation work.
2. **Content second, implemented and verified in isolation, council pending:** the selected
   slice is *Room for Two Futures*, an existing partner's independent aspiration,
   plus one inherited memory. See the implementation brief below. Implement after
   the reliability work reaches its review gate or a precise external blocker.
   Verify routes, payment rejection, deadlines, saved cast and inherited
   consequences through existing owners and contracts.
3. **Mobile Web separately, queued:** preserve the unfinished R09 work. Address
   only reproducible issues that can be checked without the owner's phone or
   interactive desktop. Do not claim device or browser usability from headless
   contract tests. If no new independently verifiable defect is found, leave the
   phone retest as the next action rather than inventing additional scope.

Each implemented feature follows reproduce or define acceptance criteria,
implement, verify, freeze the artifact, consult the council, address blocking
findings, and integrate. Council members are independent Security (GPT-6 Astra),
UI/UX/Design (GPT-6.1 Sol), and technical (GPT-6 Astra) reviewers using the council
skill. Consultation happens at feature completion. Changed review scope requires
fresh affected reviews. Headless verification does not certify visual quality,
actual device behavior, or ordinary-player lifetime pacing.

## Coordination and safeguards

The parent coordinates asynchronous T3 delegates and resumes on their completion
notifications. Implementation uses tool-managed isolation from `main` at
`5423b0c` because the permanent checkout contains unfinished Web work. Content
discovery is read-only. Do not reset, stash, commit or overwrite unrelated edits.
Use Godot 4.4.1 stable and isolated test save profiles. Keep timing runs separate
from heavy parallel tests. Preserve baseline evidence and logs of failed runs.
Do not read credentials or the untracked `.aws` path.

Integrate completed work locally after verification and review, preserving the
existing working tree. Keep `ROADMAP.md` and the handoff accurate. Prepare shared
gameplay ports only after desktop verification; preserve Portrait startup and
input behavior. Public pushes, releases and deployment are outside this loop.

## Selected content brief, 2026-11-02

Reliability implementation reached its review gate at
`018efd976441178e652f608e374dd70991f34128`, isolated checkout
`/home/nextg/.t3/worktrees/Era-Life-Community/t3-45fcdf67`, based on `5423b0c`.
Its committed evidence is `docs/COLD-CONTINUE-PERFORMANCE.md` in that checkout.
The subagent reports all 25 regressions passing, sequential before/after timing
samples, and sibling/business fixtures each continued for twelve real years
with repeated separate-process exact restores. The parent inspected the patch,
regression and profiling harness. All three council reviews passed and the desktop fix is integrated.
Portrait performance verification remains open. Preserve ignored
`build/cold-continue/` and `build/tests/headless-q1r24r0s/` before cleanup.

Council round `eralife-cold-continue-20261102-r1`, frozen head `018efd9`: all three
members returned PASS with no blockers. See [the council record](COUNCIL-COLD-CONTINUE.md)
for votes, limits and nonblocking suggestions. The unchanged reviewed commit was
fast-forwarded into `main`, preserving existing Web source hashes and merging
local documentation. All 26 combined regressions and an additional private-display exact cold restore passed. Evidence was
copied and hash-verified under `build/reliability-evidence-20261102/`. The completed
worktree and temporary branch were retired after preserving the commit and evidence.
The gameplay change is not yet ported to Portrait.

Discovery was read-only. The twelve current stories cover friendship, lending,
mentorship, care, criminal history, business succession, sibling fairness and
inherited memories. An established romantic partner appears as supporting cast,
but has no dedicated aspiration arc. This makes partnership the selected design
direction, not a claim that a new player playtest proved demand for it. Evidence
is in the four existing story catalogs and `docs/SIBLING-STORIES.md`. A retained
sibling fixture reached its arc in 2009 after other stories; that supports avoiding
another care prerequisite but does not measure ordinary-player admission rates.

Proposed story IDs: `partner_futures` and `partner_futures_legacy` in a new
`project/data/partner_stories.json`, using the existing LifeStoryEngine owner.
The partner pursues a small creative project with or without the player's
participation. Offer honest involvement, practical help, independent pursuits,
conditional support, or accountability. Refusal and respectful independence are
substantive outcomes. Money and apologies cannot purchase renewed agreement.

Target eight main nodes and one inherited node, approximately 27 responses;
chapter count is a scope bound rather than a quality goal. Nodes are notebook,
first attempt, own terms, refusal, shared close, parallel close, separation and
loss. The last two respond to confirmed relationship changes or death elsewhere
in gameplay. The story itself neither starts nor ends a partnership. Do not
claim a new job, qualification, company, property or residency change. Ordinary
routes should span several authored years, with positive follow-up delays and
explicit deadlines. Every chapter has a free default that does not invent consent,
attendance, spending or reconciliation.

Admission uses an existing living adult reciprocal partner and the existing story
cap/cooldown. It requires no care story, children, marriage, company, employment
or wealth. Preserve the original cast through unavailability, separation and
remarriage. Pause while hydration or missing residency prevents an authoritative
relationship check. Never infer breakup from a partially restored reference.

Use existing personal-bank transfers for optional materials/practical support
(proposed Modern Era costs $150 and $75), with admission-era scaling. Reject
unaffordable/frozen payments before story effects. A stale paid choice after
confirmed separation must reject before transferring money. Death takes its
existing precedence over separation, with named truthful outcomes.

The parent checked current choice resolution: `next_untrusted` reads the player's
affection after effects, and relationship changes are asymmetric. If the new story
uses the partner's trust, add an opt-in cast-side selector evaluated before effects.
Leave existing stories' trust semantics unchanged. Validate new selectors and
interruption targets and cover asymmetry and the trust threshold in regressions.

The inherited chapter, *The Plans They Kept*, preserves the parent's actual public
outcome and original partner. An adult child can adapt the lesson, preserve it
without adopting it, or decline the obligation. Exclude unfinished/private records
and never rewrite the parent's history. Reuse version 1 records and existing legacy
contracts; no migration or new UI owner is planned.

Acceptance includes every response and distinct complete routes, full-catalog
admission, unavailable/deceased/separated cast, stale clicks, failed payments,
personal/company money separation, asymmetric affection, old saves and unknown
records, and adult-child succession. Use binary hydration and separate-process
Continue before/after payment, during delay, and after completion. Compare cast,
partner links, both affection directions, history, deadlines, diary and balances.
Run timing-sensitive checks after reliability work without concurrent heavy tests.
Do not claim natural pacing, visual quality or phone usability from these tests.

Discovery reports the story engine, four packs and sibling regression currently
match between `main` and `portrait`; verify again before porting. Preserve branch-
specific serialization, startup and touch harnesses. The actual historical baseline
is 24 committed desktop tests, 25 in the combined tree with local Web changes,
and 28 Portrait tests. These are recorded results, not new checks in this loop.

R11 implementation is in `t3/partner-futures-story`, based on integrated desktop
`57c626a`. The complete authored slice and focused regression are implemented.
[Partner Stories](PARTNER-STORIES.md) records behavior and verification evidence.
All 26 regressions and the thirteen-real-year private-display route passed,
including four exact cold restores with the normal hydration gate. Next: freeze
the implementation commit and have the parent run all three council reviews. Content council approval and integration are not yet claimed.

## Deferred verification

- Interactive desktop playtesting of a full natural family journey and pacing.
- Honor checks of the exact signed Portrait APK, including restored cast,
  meaningful choices, age/save and cold Continue.
- Real-phone mobile Web readability, keyboard, scrolling and save/Continue.
- iOS Safari and other unavailable platform checks.

Stop this queue when the achievable items are complete or only external checks
remain. Report blockers and exact next actions instead of repeating unproductive
attempts or claiming the deferred checks passed.


R11 council follow-up, 2026-11-02: the coordinator fixed both round-1 blockers
(confirmed-separation liveness and unusable trait buttons), reproduced them with
regressions, and passed the full 26-test suite plus three private-display cold
restores. See [the correction record](COUNCIL-PARTNER-STORIES.md). All three
members must review the corrected commit; no renewed approval is claimed yet.
