# Shared Lives — the family business chapter

Shared Lives adds **16 chapters and 46 authored responses** to the six existing
Life Stories. The first saga, **The Business We Built**, follows a founder,
cofounder, and mentor through a small partnership. **The Keys They Left** lets a
later generation decide what to do with that same company.

## Playing

An opportunity can appear in **Pending Situations → Family** when the controlled
person is 18–65 and has both an adult friend or sibling and a distinct parent or
coworker at least five years older. Casting uses existing people. The usual
maximum of two active stories and two-year gap between new stories still apply.
The story may therefore arrive after another eligible Life Story.

Start with $1,200 in company reserves, start small with $400, or decline. These
are Modern-era amounts: the era multiplier is fixed when the story begins and
survives a later era change. Investment moves money from your personal account
to a separate BankEngine account. The founder owns 60%; the cofounder owns 40%.
Both keep their existing jobs; this is a side business, not a replacement career.

The founder's full route unfolds over 15 years if each chapter is answered when
it appears. It covers decision rules, equipment, the division of work, time at
home, owner draws, expansion, flood recovery, and succession. Each chapter has
an explicit calendar deadline and a response that requires no payment if ignored.
Closing a popup does not choose a response.

Choices affect relationships between the player and the cast, and between the
two recurring NPCs. At the accounts review, a relationship below 45 causes the
cofounder to refuse expansion and propose new terms. This response follows the
actual relationship score after the review choice; it is not a random roll.

## The company is a saved asset

The Assets panel's **Family Business / Wealth** section shows ownership,
company reserves, working policy, quality, reputation, and inherited legacy.
These values come from the business and bank owners, not panel-local state.

- Investments and draws move real bank money. Equipment and recovery expenses
  spend the company's reserve. A failed payment does not advance the chapter or
  apply its relationship and business effects.
- Yearly net operating surplus is `(120 + quality × 2 + reputation) × era scale`.
  It stays in the company. The company settles once per game year, even if the
  player switches between its owners. Catch-up uses one aggregate operation,
  capped at 100 elapsed years, rather than a world scan or an unbounded loop.
- Frozen accounts defer their income settlement. Successful settlement is saved,
  so restoring the same year cannot pay it again.
- A draw is limited to the actor's share of available reserves. Leaving pays that
  exact liquid share and transfers the departing owner's stake to the original
  living cofounder. It does not sell the same stake twice.
- Quality and reputation affect the next settlement. Operating policy, legacy,
  and the bounded company history remain available to descendants.

This is a compact partnership model, not a complete company-management simulator.
It does not add a property deed, stock market, generated employees, formal loans,
or a replacement career assignment. Routine operating costs are represented by
net surplus; the authored crises and investments add explicit company expenses.

## Succession and loss

The succession chapter can transfer the founder's stake and management to their
oldest living adult child. If the owner dies first, that eligible child receives
the stake when their life is controlled. A child whose identity is not loaded is
not silently skipped in favor of a substitute. A household without an adult child
can keep managing instead. The next generation can eventually repeat the handover.

The company keeps its identity, original cast, bank account, reserves, policy,
and legacy. The incoming manager's relationship with a surviving original
cofounder also reflects part of the previous generation's relationship. An
inherited manager becomes eligible for The Keys They Left, subject to ordinary
story pacing. A minority shareholder inherits the asset without gaining unilateral
management authority.

When a founder-story participant dies, a named bereavement chapter closes that
story without deleting the company. A temporarily unloaded participant pauses
admission instead of being replaced. The inherited story refers to the founding
records and can retain deceased participants by name.

## Ownership and extension points

- `LifeStoryEngine` owns the data-driven chapter graph, stable ensemble roles,
  year-based deadlines, relationship consequences, and diary/memory entries.
- `project/data/shared_lives.json` holds the two new stories. Existing
  `life_stories.json` remains the original six-story catalog.
- `FamilyBusinessEngine` owns partnership shares, management, succession,
  operating policy, company history, and annual settlement.
- `BankEngine` remains the money authority, including the company account.
- `scenario_state.family_businesses` version 1 persists company records and an
  index of holdings by actor. Existing `scenario_state.life_stories` version 1
  accepts optional ensemble, company, and bereavement fields; old stories retain
  their original behavior and IDs.
- Compact checkpoints retain the ensemble and shareholders within the existing
  256-person limit. They include a bank snapshot scoped to saved people and
  company owners, including balances, account restrictions, and transaction IDs.
  Full-save bank state uses the existing exporter. Both hydrate through the
  existing bank import route.
- Both immediate and incremental Assets contract producers publish the same
  business projection. Gameplay mutations invalidate affected owner caches.

Additional story definitions may use `business_partners` or `business_heir` cast
roles, `relationships` edges between `player`, `cofounder`, and `mentor`, a
`business` action, an optional `next_untrusted` chapter, and a `death_node`.
Money actions and participant transfers cannot be mixed in one response. Every
ordinary and exceptional destination is validated for existence and cycles.

## Verification

Use Godot **4.4.1 stable**:

```sh
python3 scripts/test-headless.py
python3 scripts/check-structure.py
python3 scripts/code_map.py --write
python3 scripts/code_map.py --check
bash scripts/test-shared-lives.sh
```

`test_shared_lives.gd` checks all 46 authored responses through the real pending
and resolution owners, a complete founder route over its authored years, the
cofounder's refusal branch, NPC-to-NPC relationship changes, failed and repeated
transactions, year settlement, account freezing, living and post-death
succession, the heir's playable chapters, absent/dead cast, and binary checkpoint
hydration of exact personal/company balances. The original 125 Life Stories
routes remain covered separately.

The graphical fixture enters an adult Household life, supplies existing contacts,
opens the pending chapter, clicks the investment, inspects the visible Assets
panel, ages, and saves. It uses isolated test data. These checks do not certify a
full birth-to-death playthrough or the existing broader cold-restore lifecycle.

### Desktop validation, 2026-09-26

- Godot 4.4.1: all **19 headless regressions passed** (`build/tests/headless-5va5_mlj`).
- The graphical Household route passed investment, visibly rendered ownership and
  reserves, one complete simulated year, and binary save checks
  (`/tmp/eralife-shared-qqxTpS`). Personal funds moved from $10,000 to $8,800;
  company reserves moved from $1,200 to $1,470 after its first settlement.
- Structure and regenerated code-map checks passed.
- Banking regressions also cover the initially unresolved world becoming a realm,
  stale legacy mirrors, empty-account restore, and frozen transfer destinations.
- Existing shutdown resource warnings and the checkpoint `snapshot_not_found`
  diagnostic remain. The broader cold-restore issue documented in Architecture
  is outside this content change.
