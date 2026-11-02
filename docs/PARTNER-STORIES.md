# Partner Stories: Room for Two Futures

R11 adds *Room for Two Futures* and the inherited chapter *The Plans They Kept*.
The pack has eight main chapters, one memory chapter and 26 responses. It loads
after the previous twelve stories; the original six-story series is unchanged.
This direction came from source coverage and retained fixtures, not a new player
playthrough or a measurement of player demand.

## Eligibility and play

A controlled adult aged 18 through 85 needs an existing living adult reciprocal
partner. Marriage, children, employment, money, a company and a completed care
story are not prerequisites. Casting uses indexed resident people, saves the
original identity, and never substitutes a later partner. The existing two-active
story cap, two-year admission cooldown and once-per-person rule still apply.

The partner wants to make a small illustrated book without making it earn money.
The player can listen, offer limited involvement, help with materials, respect
separate pursuits, attach conditions, or acknowledge pressure. The partner can
continue independently and refuse a joint arrangement. Respectful independence
is a complete positive outcome. Neither payment nor an apology buys agreement.
No response changes real partnership status, jobs, qualifications, property,
residency or business ownership.

Optional personal transfers cost $150 for materials and $75 for copying costs in
the Modern Era. Admission-era scaling is saved: Ancient 0.2, Medieval 0.3,
Industrial 0.6, Modern 1.0, Future 1.5. Prices appear beside the response.
BankEngine moves money to the original partner. Failed or frozen payments commit
no story, relationship, wellbeing, diary or balance effects. Company reserves
are not involved. Paid choices do not increase the partner's trust.

Each chapter has a two-year response window, an absolute displayed deadline and
a free default. Defaults do not spend, claim attendance or establish consent.
All follow-ups wait two years. Ordinary routes finish in two to eight authored
years after admission, depending on the route. Calendar-based contract tests
check those delays; the offscreen harness separately exercises real Age Up.

| Route | Consequence |
| --- | --- |
| Listen, offer limited shared time, retain the invitation | Shared by invitation, if the partner is willing |
| Materials, practical help, room for both | Separate pursuits with room to grow |
| Independent work, respect, reflect on control | Support without a claim |
| Conditional help, accountability, room for both | Independent work continues; no purchased reconciliation |
| Conditional help, continued insistence | Unresolved pressure, no joint agreement |
| Private reflection | Completed story excluded from inheritance |
| Partnership ends through existing gameplay | End the unfinished arrangement or retain a lesson without reunion |
| Original partner dies | Remember unfinished work or keep the memory private |

## Runtime and compatibility

`LifeStoryEngine` retains version 1 state and existing popup actions. New content
uses `cast: partner`, `trust_from: cast`, and `separation_node: separation`.
Unknown selectors and missing interruption targets fail catalog validation.
Cast trust is the partner's affection toward the actor at decision entry, before
any effects. A value below 45 follows `next_untrusted`; 45 accepts the normal
branch. Missing `trust_from` preserves the old player-side, post-effect rule.

Separation needs authoritative evidence: a former-partner record or a different
resident reciprocal partnership. A null or nonreciprocal reference alone pauses
the story. Loading, hydration and missing cast also pause it, even beyond the
deadline. Returning cast resumes the free expired default once. Confirmed death
precedes separation. A stale paid choice after separation is rejected before
money or effects; its pending projection is cleared and ordinary servicing
publishes the separation chapter. This owner never calls breakup or divorce.

An adult child can encounter the parent's completed public outcome with the
original cast, even if that cast has died. The chapter shows the saved outcome
and retains `origin_story` admission, `origin`, and `origin_legacy`. The child can
adapt, preserve without adopting, or release the obligation. Parent records,
private and unfinished records, old missing optional fields, and unknown packs
remain intact. No migration is required.

## Reproduction and evidence

Use Godot 4.4.1 stable. `test_partner_stories` is automatically discovered by the
existing runner. It covers all 26 responses, full-catalog routes and minimal
couples, admission exclusions, trust direction and boundaries, payment failures,
company isolation, interruptions, duplicate clicks, binary hydration and actual
adult-child identities. Calendar assignments in these unit fixtures are contract
checks, not real-simulation evidence.

```sh
python3 scripts/test-headless.py test_partner_stories test_life_stories test_sibling_stories
python3 scripts/test-headless.py
python3 scripts/check-structure.py
python3 scripts/code_map.py --write
python3 scripts/code_map.py --check
git diff --check
```

The Living Households smoke now accepts `ERA_FAMILY_STORY=partner_futures`. Its
partner cycle keeps the full catalog, discovers the arc through real simulation
years, checks visible text, deadlines and priced response buttons, then makes
real binary saves and separate-process Continue calls. It retains checkpoint
copies before payment, after payment, during follow-up and after completion.
Restore comparisons include both partner links and affection directions, cast,
story state/deadlines/history, diary, personal accounts and company accounts.
Run sequentially after regressions on a private display:

```sh
env -u WAYLAND_DISPLAY LIBGL_ALWAYS_SOFTWARE=1 ERA_FAMILY_STORY=partner_futures \
  xvfb-run -a -s '-screen 0 1440x900x24 -nolisten tcp' \
  bash scripts/test-living-households.sh cycle "$PWD/build/partner-evidence/cycle"
```

The normal 90-second hydration gate is unchanged. These checks do not reduce the
population or omit simulation phases. They do not certify interactive visual
quality, natural discovery rates, lifetime pacing or phone usability.

The original isolated implementation evidence is recorded below. Council and
desktop integration are complete as described at the end of this document.
Portrait porting remains separate: retain its lazy startup, touch viewer, shell
and save adaptations, then rerun target tests and phone-sized graphical checks.
No APK, Web deployment or public release is claimed here.

### Retained regression evidence

- Initial sandbox import: `build/tests/headless-s3wb410z/import/output.log`.
  Local socket creation was denied before tests. The permitted execution path
  with isolated profiles completed import; no production workaround was added.
- Initial focused run: `build/tests/headless-kthwxxqu/`. Existing launch and
  sibling tests passed. The new test exposed fixture defects: omitted default
  series keys, a minimal couple that still supplied criminal-history eligibility,
  and numeric/key-type comparisons after binary decoding. These assertions and
  fixtures were corrected; this run remains retained as failed evidence.
- Corrected focused partner run: `build/tests/headless-cqcl28bn/`, PASS, all 26
  responses. The full suite also includes the added authoritative breakup-owner
  check and confirms the final regression version.
- Full suite: `build/tests/headless-p6u3vd62/`, **26/26 PASS**. This is the
  committed desktop baseline's 25 tests plus the new partner test, not the dirty
  primary checkout's Web test. Structure, regenerated code map/check and
  `git diff --check` passed. Baseline resource-at-exit warnings remain tolerated
  by the unchanged runner; script errors are not tolerated.

### Private-display real-year and cold-save evidence

`build/partner-evidence/cycle/` passed all five processes: fresh creation and four
separate-process restores. No timing failure occurred. Each restore used the
unchanged 90-second post-first-frame hydration gate. The run used private Xvfb
and Mesa llvmpipe, not the owner's display. No population or phase was removed.

Ada Desktop (ID 1) and Cora Desktop (ID 3) began with reciprocal partner links.
The full catalog first admitted `family_care` in 2000, `family_business` in 2002,
`household_balance` in 2004 and `partner_futures` in 2006. Earlier stories used
free defaults. The partner story was not filtered or force-inserted.

| Retained checkpoint | Year | Story state | Decisions | Ada / Cora personal funds | Ada to Cora / Cora to Ada affection |
| --- | --- | --- | --- | --- | --- |
| `checkpoints/before-payment/` | 2006 | Notebook pending, deadline 2008 | 0 | $10,000 / $10,000 | 59 / 59 |
| `checkpoints/after-payment/` | 2007 | First attempt waiting, due 2009 | 1 | $9,850 / $10,150 | 59 / 59 |
| `checkpoints/during-delay/` | 2008 | First attempt still waiting, due 2009 | 1 | $9,850 / $10,150 | 63 / 62 |
| `checkpoints/completion/` | 2013 | Finished in 2011, separate pursuits | 3 | $9,775 / $10,225 | 63 / 62 |

The visible materials choice committed in 2007, practical support in 2009, and
room for both lives in 2011. The real simulation continued through 2013 without
replaying a choice. Affection changed through ordinary simulation during the
2008 year; it did not change across the corresponding cold restores. Personal
funds total $20,000 in every retained checkpoint. There is no company in this
route; the funded-company isolation checks are in `test_partner_stories`.

Logs are `before-payment.log`, `after-payment.log`, `during-delay.log`,
`completion.log`, and `completed-restore.log` in that cycle directory. Each
restore checks the full story state including original cast, history, due year,
deadline and legacy, exact diary state, personal bank accounts, and both partner
links and affection directions. The final restore retained 14 diary entries,
839 world-feed entries and exactly three partner choices. Visible name, deadline,
price, button bounds and exact transfer assertions passed. Screens are in
`cycle/screens/`; they are automated offscreen artifacts, not interactive visual
certification. The decoded binary summary is
`build/partner-evidence/checkpoint-summary.log`.

Deferred: interactive natural-family pacing, a full birth-to-death playthrough,
Portrait port and phone-sized adaptation, exact Honor testing, mobile Web and
other platforms. The corrected desktop implementation is council-approved and integrated locally.
See the integration record below; no release or Portrait pass is claimed.

Final focused rerun: `build/tests/headless-0ykofa3t/`, **3/3 PASS** (partner,
original Life Stories, sibling stories). This follows the full suite and cold
cycle. It verifies the tightened reciprocal adult-child fixture, the longest
limited-involvement route, the invitation-lapse ending, and inherited eligibility
using the standard adult-memory age range rather than the main arc's age-85 cap.
The shared engine is unchanged from the passing full suite. All 26 authored
responses pass; eight full ordinary contract routes now cover the main endings.


### Council corrections, 2026-11-02

Round 1 requested two fixes: established-separation liveness after a third person
leaves residency, and unusable generic trait responses in the completed story
view. The coordinator reproduced both, corrected resolution and projection
behavior, and added focused regression and visible-button checks. Old cached
story views now rebuild without trait options; ordinary situations retain them.
The fresh-invitation wording also avoids implying earlier shared involvement.

The corrected full suite passes 26/26 in `build/tests/headless-v_m7kwu1/`.
Three additional sequential private-display restores pass, including visible
notebook, practical-help and independent-ending choices and an exact final
2012 restore. See [the council correction record](COUNCIL-PARTNER-STORIES.md)
for pre-fix failures, complete test paths, screenshot inspection and limitations.
The original thirteen-year cycle remains separate historical evidence. Fresh
reviews from all three council members now pass exact corrected commit `954645b`.


### Approved desktop integration

All three council members passed `954645b`; see
[the full council record](COUNCIL-PARTNER-STORIES.md). The unchanged reviewed
commit is on main. All 27 combined regressions pass in
`build/tests/headless-_y9erp29/`, including the existing local Web test. A further
private-Xvfb integration route restores exact saved state, makes the visible
materials payment, advances one real year and saves. The unchanged hydration
gate is retained. Evidence is in
`build/partner-evidence-20261102/integration-check/`.

All 1,288 source evidence files are archived and hash-verified in primary
`build/partner-evidence-20261102/`, preserving their original `build/` hierarchy.
Source worktree paths above are historical. The original failures and diagnostics
remain recorded. Portrait receives this evidence document only until the
separate shared-code port and verification. No phone, interactive pacing or
public release claim is added by integration.
