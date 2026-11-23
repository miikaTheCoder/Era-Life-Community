# Connected lives feature loop

Requested 2026-11-04. Status: complete and unanimously council-approved on `main`,
starting at `7d90ed3`. All five desktop slices and required corrections are verified.
The implementation is `a4b8d0a` plus reviewed local corrections. See the
[council verdict](COUNCIL-CONNECTED-LIVES.md#round-3-approved-the-council-gives-its-blessing).

## Playable slices

1. **A Future of Their Own:** an existing child aged 16 to 30 explores a skilled
   craft. Support, negotiation, pressure and distance lead to distinct outcomes.
   Money is optional, personal, and does not purchase agreement. A later controlled
   child can revisit the parent's public memory. No job or qualification is invented.
2. **Connected conversations:** completed public care, sibling and partner outcomes
   inform later story text. Context is captured at admission and survives restores.
3. **Family chronicle:** a readable view of the current person's choices and the
   parents' completed public outcomes, plus a short journal recap on Continue or
   generation change. Existing saved story state remains authoritative.
4. **The Years Between:** an adult continuation of the childhood pact, using the
   original friend even after drift. Mutual help, honest limits, repair and distance
   are complete routes. No replacement friend is generated.
5. **Community stories (R08):** data-only JSON packs, a runnable sample, bounded
   loading, actionable validation and stable IDs. Invalid packs cannot disable
   built-in stories. Removing a pack preserves its saved progress for reinstatement.

## Chronicle design

Keep EraLife's permanent dark theme: canvas `#101214`, panel `#191d20`, line
`#38454d`, text `#edf5fa`, muted `#a8bac5`, accent `#66dbff`. Use existing
Liberation Serif headings and Liberation Sans body text. A vertical sequence of
dated choices makes the family history recognizable; inherited outcomes are
explicitly attributed to the parent. Keep the journal intact, use one entry
button, readable wrapping, scrolling, keyboard focus and an explicit close route.
No speculative family relationships or disclosure of private parental stories.

## Acceptance and evidence

Run the pinned Godot 4.4.1 full regressions, structure and code-map checks. Add
coverage for every new response, complete routes, reciprocal child casting,
original friend retention, trust, free defaults, failed payments, missing/deceased
cast, inherited identity, context snapshots, pack rejection/reinstallation and
binary hydration. Inspect the rendered chronicle and exercise graphical age/save
and separate-process Continue. Record exact limitations instead of treating
fixtures as natural lifetime or phone certification.

Council: Security (GPT-6 Astra), UI/UX/Design (GPT-6.1 Sol), and The Nerd
(GPT-6 Astra), independent reviews of the same frozen artifact. Resolve findings
and obtain fresh affected reviews before recording an approval.

## Handoff

All five desktop slices are implemented. Story state remains version 1 with
optional saved `story_title`, `actor_name` and `connections`. The new catalog has
four stories, 18 chapters and 51 responses; all built-ins total 18 stories.
The child arc has priority 10 to keep its 16 to 30 age window discoverable;
equal-priority existing stories retain their order. Caps and cooldowns are unchanged.
Community packs cannot assign admission priority.

Initial verification:

- `build/tests/headless-ox02ly5a`: sandbox local-socket import failure, no game
  regression result. Isolated permitted Godot execution was used afterward.
- `build/tests/headless-8lcva3y3`: first connected regression failed on child
  discovery and an invalid sample fixture's friend age gap. Both were corrected.
- `build/tests/headless-g8zmdfhv`: connected regression passes all 50 responses,
  nine complete routes, trust, private/unfinished memories, money failures,
  missing/deceased cast, binary hydration and pack removal/reinstallation.
- `build/tests/headless-pftthmlz`: chronicle regression passes.
- `build/tests/headless-27v4qyuu`: full suite, **29/29 PASS**.
- `build/connected-lives-evidence/chronicle`: private Xvfb rendered check passes
  at 1440x900, 420x900 and 360x640. Images inspected for wrapping and close/scroll
  reachability. This is native desktop rendering, not phone or browser evidence.

- `build/tests/headless-bb2vojcj`: final lazy-loader boundary rerun, all three
  connected, chronicle and partner regressions pass.
- `build/connected-lives-evidence/child-cycle`: visible materials transfer,
  delayed encouragement, five real years and two exact cold restores pass.
  The later `chronicle-check` route exposed a one-pixel wrapped recap despite
  correct text and working timeline navigation. An explicit minimum height and
  regression assertion repair it; the failed log remains retained.

- `build/tests/headless-7qkuuws8`: **4/4 PASS** after the final recap-height,
  era-price and incompatible-pack regression refinements. Connected stories,
  chronicle, adjacent desktop UI and Web presentation all pass.
- `build/connected-lives-evidence/child-cycle/chronicle-fixed.log`: normal cold
  restore from 2006, a real year to 2007, visible recap, mouse-open/close timeline
  and another save pass. The earlier failed layout run remains separate evidence.
- `build/connected-lives-evidence/friend-cycle`: full-catalog adult continuation
  with an explicitly seeded completed childhood pact. Three visible choices,
  five real years, $100 transfer, two exact cold restores, recap and timeline
  navigation pass. Final year 2005, personal balance $9,900, three decisions.
  The unit routes play the preceding childhood pact through its actual choices.
- `build/connected-lives-evidence/desktop-mode/household.log`: the standard
  `scripts/test-desktop-modes.sh household` entry/year/navigation/save route passes.
- `build/connected-lives-evidence/authoring/output.log`: the documented standalone
  validator accepts the sample pack, `STORY PACK: PASS; stories=1`.
- Structure, regenerated code map/check, whitespace and no-em-dash checks pass.

Round-one council requested changes. Corrections and new validation are complete;
round two found a further profile-switch text path to repair. Scope: the five desktop slices on `main`,
with implementation commit `a4b8d0a` against base `7d90ed3`, final documentation
edits, and a frozen manifest. The shared checkout was committed while the final
checks ran; this task did not run a commit, push or release command. See
[the council record](COUNCIL-CONNECTED-LIVES.md).
Baseline resource-at-exit warnings remain. Fixtures and authored contract routes
do not certify a natural birth-to-death playthrough. Portrait has pre-existing
uncommitted work and retains its 14-story catalog. The native port is separate.
No push or publication requested.

## Council corrections

Round one requested changes in all three roles. The six distinct findings are
recorded in [the council report](COUNCIL-CONNECTED-LIVES.md). The repaired build
adds one neutral friendship response, for **51 responses** across the same 18
Connected Lives chapters. Existing response IDs remain intact.

- Missing or incompatible packs now acquire optional saved suspension timing.
  Pending deadlines and waiting delays pause; cast and history remain intact.
  Reinstatement respects the two-active-story cap and waits behind incumbents.
- Pending contract revisions include the validated definition, saved era scale,
  chapter and deadline. Changed or legacy projections are regenerated under a
  new contract ID, and old buttons cannot resolve new effects.
- Validation rejects noncanonical IDs and references before runtime normalization.
  Authored text and names render literally in pending situations, diary rows,
  restored diary packets and formatted header paths. Trusted formatting stays
  separate from story prose.
- Ignoring the friendship repair opening records distance without accepting
  contact or changing affection. Same-person origin captions use "Your earlier
  story". Pack-loading errors appear before the chronicle entries.
- The chronicle now links its internal return button and timeline for Tab
  traversal. Its viewport-bounded minimum size prevents deferred layout from
  shrinking a reopened timeline to a one-line reading area.
- The final graphical run exposed a shared Crime panel conversion of pending
  contract IDs to item numbers. Pending summaries now retain their opaque source
  identity, while numeric weapon and person identities remain unchanged.

Correction evidence:

- `build/tests/headless-60amde7e`: all six council findings reproduced before
  production fixes. The benign text probes use formatting-looking strings,
  not resource loads or allocation attacks.
- `build/tests/headless-8aikkt9m`: pause and offer cold cases passed. Follow-up
  failures identified test fixture mistakes: replacing the restored diary owner,
  advancing before servicing pack reinstatement, and a missing explicit type.
- `build/tests/headless-w0hlb0g0`: all 51 Connected Lives responses pass after
  correcting the reinstatement fixture. Keyboard checks continued separately.
- `build/tests/headless-8f1pgoo1`: the safety regression passes all six required
  repairs and nine cold-process cases. The chronicle still failed actual scroll
  input because the reopened reading area had collapsed; this failure is retained.
- `build/tests/headless-5nen9fn0`: chronicle layout and input pass after the size
  repair: Tab from Age up, Enter opening, Tab to the timeline, PageDown, wheel,
  Escape and focus return. This checks native desktop controls.
- `build/tests/headless-c433whij`: full **30-test** run, 28 passed. The two older
  partner/sibling tests needed fixture updates: a version-1 definition must be
  installed before its offer is presented; unloaded-cast comparisons now allow
  only the new content-availability timestamp to advance. All gameplay fields
  remain compared, including history, cast and deadlines.
- `build/tests/headless-b3lard3r`: corrected partner and sibling regressions and
  the chronicle all pass (**3/3**). Together with the full run, all 30 test stems
  pass on unchanged production code. The full-run failures remain visible above.
- `build/connected-lives-evidence/r2/child-cycle/entry.log`: the paid child choice,
  real year and save passed, but the run correctly failed on a numeric conversion
  error in the Crime panel's shared pending list. This is retained failed evidence.
- `build/tests/headless-vrvp31ga`: the added pending-summary regression reproduces
  that conversion error using an actual story offer. It also checks stable weapon
  and person row identities. Final validation follows the focused boundary fix.
- `build/tests/headless-zz6zvnch`: fresh full suite after the pending-row repair,
  **30/30 PASS**, including all 51 responses, the nine cold safety cases, adjacent
  crime regressions, and chronicle keyboard, wheel, Escape and focus checks.
- `build/connected-lives-evidence/r2/child-fixed-cycle`: repaired full-catalog
  graphical route passes the visible $200 materials transfer, delayed trial,
  five real years and two exact cold restores. Completed at 2005 with two story
  decisions and $9,800. Recap, timeline and closing controls were inspected.
- `build/connected-lives-evidence/r2/friend-fixed-cycle`: original-friend route
  passes reunion, $100 help and reciprocity, five real years and two exact cold
  restores. Completed at 2005 with three decisions and $9,900. Rendered earlier
  story caption, recap and timeline were inspected.
- `build/connected-lives-evidence/r2/desktop-mode/household.log`: standard desktop
  creation, real year, navigation and save pass.
- `build/connected-lives-evidence/r2/authoring/output.log`: the documented sample
  validator passes with one story.
- `build/connected-lives-evidence/r2/chronicle-fixed`: input/layout test and the
  1440x900, 420x900 and 360x640 timeline images pass. Image inspection found that
  the loading-error capture showed a closed panel after the fixture switched
  people. The shell correctly hid a panel still owned by the former person.
  `r2/chronicle-final` retains the failed visibility assertion that identified it.
  The fixture now reopens through the shell after switching people, then supplies
  its synthetic error contract, uses the actual viewport, and asserts visibility.
- `build/tests/headless-z5i16w5j`: final chronicle fixture passes, including
  reopening for the next generation and asserting the loading-error panel is
  visible. Only this test fixture changed after the 30/30 full suite.
- `build/connected-lives-evidence/r2/chronicle-visible`: final graphical chronicle
  test passes; its loading-error image visibly shows the summary before the
  empty timeline. Three viewport renders and actual Tab/Enter/PageDown/wheel/
  Escape/focus-return checks pass. Earlier capture failures remain separate.

All final graphical logs contain their PASS markers and no unexpected engine or
script errors. Baseline resource/ObjectDB shutdown warnings remain. Final source,
tests and documentation are identified by
`build/connected-lives-evidence/r2/review-manifest.json` and remained frozen while
the three reviewers inspected them. UI/UX and The Nerd passed; Security requested
the remaining profile-switch diary repair. No council approval is assumed.

The cold-process regression serializes a binary checkpoint and exports active
popup projections, launches a fresh Godot process, hydrates state, and imports
the retained runtime projection. It covers pending and waiting chapters with
missing or incompatible content, ten absent years, changed-price offers before
and after normal service, legacy offers without revisions, and literal text
before and after restoration. This is fixture evidence, not natural-life pacing.

## Round-three profile-switch correction

Round-two Security found that two additional MainScene consumers trusted cached
profile-switch diary strings as BBCode. UI/UX and The Nerd passed that snapshot,
but the P1 objection kept the council verdict at rework required.

Both consumers now prefer the supplied literal diary lines and apply the existing
owned diary formatter. Cached text and caller/packet text fallbacks follow the
same literal path. The local relationship-profile cache now stores plain text
and raw lines, consistent with `UniversalSwitchContractEngine`; no saved text is
promoted to trusted markup. The adjacent generation-switch minimum diary also
uses the literal formatter. Packet/state owners and existing contract keys stay
intact, and rendering does not fetch or rebuild the authoritative history.

The safety regression calls the real `prepare_profile_pointer_packet()` and both
MainScene consumers. It checks ordinary packets, cached-text-only packets,
caller/diary text fallbacks, and lines-only packets in the live state and the
existing two fresh-process text cases. It uses benign formatting-looking results
and participant names, not resource-loading payloads.

- `build/connected-lives-evidence/r3/text-before`: initial reproduction also
  entered an unrelated deferred UI tail without an attached scene tree. The
  fixture was corrected to use the real relationship-switch no-tail policy.
- `build/connected-lives-evidence/r3/text-repro`: clean reproduction before the
  production repair, failing both consumers and text fallbacks in live and cold
  history. The lines-only published path was already safe; the press path was not.
- `build/connected-lives-evidence/r3/text-after`: the same focused probes pass
  after the correction, including both fresh-process text cases, with only the
  known resource/ObjectDB shutdown warnings.

- `build/tests/headless-pyr2zn7x`: fresh full suite **30/30 PASS**, including all
  nine cold safety cases and the expanded profile-switch probes. No production
  code changed after this run.
- `build/connected-lives-evidence/r3/profile-text-final`: both real profile-packet
  consumers render benign BBCode-looking results and names literally, before and
  after in-process hydration. Four 1440x900 PNGs were inspected and have identical
  hashes, as expected. The fixture also asserts visible text pixels. This is a
  focused rendered fixture, not a full-scene profile-switch acceptance run;
  fresh-process restoration is covered separately by the safety regression.
  The earlier `r3/profile-text` files also pass and contain the same images.
- `build/connected-lives-evidence/r3/desktop-mode/household.log`: standard desktop
  Household entry, year, navigation and save PASS.
- `build/connected-lives-evidence/r3/friend-restore`: a copy of the completed
  round-two friendship save restores at year 2005, advances one ordinary year,
  saves, and restores again at year 2006 / age 41 / $9,900 with all three decisions.
  Both processes pass. The restored journal and chronicle were inspected.

Final logs have no unexpected engine/script errors beyond the retained shutdown
resource/ObjectDB warnings. Runtime diagnostics such as `snapshot_not_found`,
`missing_signature` and the existing resident-projection stall notice remain
visible in the graphical logs; passing assertions do not certify those systems.
Structure, regenerated code map and whitespace checks pass. The only test change
after the full suite adds a short graphical capture delay and a visible-pixel
assertion in the separate smoke fixture; its rerun passes.

The exact reviewed source, documentation, tests and evidence are identified by
`build/connected-lives-evidence/r3/review-manifest.json`. All three fresh reviewers
returned PASS, with no required findings, and matched all 33 reviewed-file hashes
and 131 evidence hashes at both start and end. The coordinator rechecked those
hashes before recording the verdict. Only closure documentation changed after
review; production, tests and evidence remain unchanged. Earlier manifests and
failed logs remain retained. Natural lifetime pacing, Portrait, phone input,
browser acceptance and performance certification remain outside this loop.

Optional future checks are a complete real-scene authored-text profile switch
after cold Continue and capacity competition combined with fresh-process restore.
They are additional assurance, not unresolved blockers. This finite desktop loop
is closed; separate platform adaptation or pacing work needs its own scope.
