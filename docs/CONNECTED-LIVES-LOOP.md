# Connected lives feature loop

Requested 2026-11-04. Status: implementation in progress on desktop `main`,
starting at `7d90ed3`. This is a finite loop, with council review after validation.

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
four stories, 18 chapters and 50 responses; all built-ins total 18 stories.
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

Final layout/payment refinements, friendship graphical route and council pending.
Baseline resource-at-exit warnings remain. Fixtures and authored contract routes
do not certify a natural birth-to-death playthrough. Portrait has pre-existing
uncommitted work and retains its 14-story catalog. The native port is separate.
No push or publication requested.
