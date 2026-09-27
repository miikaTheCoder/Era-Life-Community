# Living Households

Desktop first slice, 2026-09-27. This is R05 on `codex/shared-lives-desktop`.
Portrait's corresponding gameplay port and phone checks are tracked under R06.

## Play the family arc

**The Time We Owe** starts through ordinary Pending Situations for an adult aged
25 to 75 who has a living parent aged at least 55 and an existing adult partner
or sibling. The partner is considered first. The sibling must share that parent.
The story does not invent relatives, require a company, or require co-residence.
Earlier eligible stories and the normal two-year admission cooldown can delay it.

An older parent wants to keep their independence. Another family member asks how
the time, practical tasks and cost of support will be divided. Their willingness
to continue depends on their relationship with the player and earlier decisions.
The parent also has a say in what help is welcome. Work attention, wellbeing,
relationships, personal payments and boundaries all have consequences.

The main routes span four to six authored years. A sustainable shared routine,
a smaller promise, repaired trust, estrangement and unresolved distance leave
different outcomes. After a finished arc, an adult child can encounter **A Place
at the Table**, a two-chapter family-memory continuation. That child can adapt
what helped, honor the memory, or choose a different life. A private ending does
not offer this inherited chapter. A deceased supporter can still be remembered.

The pack contains two stories, eleven chapters and thirty responses. Alongside
the six original Life Stories and two Shared Lives stories, the desktop catalog
now contains ten definitions.

## Consequences and persistence

Relationship effects use RelationshipEngine for the player, parent and supporter.
Wellbeing and work-performance changes use the existing player statistics. These
are bounded authored consequences, not a new hourly scheduling or care-service
simulation. Diary entries and saved story history record each response.

Paid choices transfer real money from the player's personal bank to the supporter
who arranges the agreed help. Labels show the price; chapter context identifies
the payer and recipient. Era scaling is captured when the story begins. Frozen
accounts and insufficient funds reject the choice before story consequences;
a free response remains available. Company reserves are separate and are never
used for these care transfers. Every deadline uses a free authored default.

Cast identities are saved in the existing ensemble contract. An unavailable
participant pauses progress, including expired choices, until that same person
is available again. A death leads to a named bereavement chapter with free
responses. Neither condition replaces the person with an arbitrary new NPC.
Compact checkpoints retain the ensemble, decisions, money and relationships.

## Implementation and authoring

Content lives in `project/data/living_households.json`. LifeStoryEngine loads it
through the same version 1 schema, validates choices, admits stories, renders
contracts and commits responses through the existing narrative owners. Old saves
and their existing story records need no migration.

The `household_care` cast resolver reads at most 32 known parents and, for each, the partner plus
at most 32 sibling candidates through the indexed person lookup. It does not scan the
world population. Its saved ensemble has `relative` and `supporter` roles, usable
in text and relationship effects. Optional saved `context` explains personal
care payments and the separation from an owned company.

A legacy definition may name `origin_story` to require a finished story with that
ID on a parent. `allow_deceased_cast` permits that remembered participant to have
died. These optional keys leave existing legacy definitions' behavior intact.
No care balances, household truth or story state are stored in UI controls.

## Verification

```sh
python3 scripts/test-headless.py test_living_households
bash scripts/test-living-households.sh cycle /tmp/eralife-households-example
python3 scripts/test-headless.py
```

Use a fresh isolated profile for the graphical cycle. The regression checks all
thirty responses, three complete routes with the full catalog, relationship-driven
refusal, diary history, personal payments, company separation, era prices, free
fallbacks, deadlines, absent/deceased cast, binary checkpoint hydration and a later
life's inherited continuation. Full-route fixtures advance the story calendar and
participant ages; they do not certify a whole-world lifetime simulation.

The graphical harness creates a Household, supplies an older parent and an adult
partnership as explicit test relationships, and keeps all ten stories enabled.
Competing stories receive their authored defaults. Age Up runs the actual yearly
simulation. Care responses are clicked in the visible Pending Situations viewer.
The cycle saves between processes and compares the saved story, cast, bank state,
relationships and diary after cold Continue. It is a short functional playthrough,
not a measurement of story frequency in arbitrary generated families.

The initial two-year graphical session stalled at its second Age Up. Its log and
screenshot are retained with the evidence; this is not a passed multi-year session.
The cold-cycle harness saves and restarts between individual years. Longer
uninterrupted sessions remain a separate investigation under R07. The specific
second-click input failure was subsequently reproduced and repaired in the
[Age Up input follow-up](AGE-UP-INPUT.md); the original R05 evidence below is
unchanged.

Verified 2026-09-27: all 21 regressions passed in
`build/tests/headless-c2aa11j9`. This includes all 30 authored responses and the
complete shared-routine, boundary and repaired-trust routes. In full-catalog
fixtures the story began in 2008 and finished in 2012 or 2014. A later life
completed the inherited memory with the full catalog enabled.

The graphical cycle passed five actual years across separate processes, then a
final cold Continue. The care request appeared in 2004 after family care and a
declined company offer. The visible $300 payment left personal funds at $9,700;
2005's review remembered that choice, and its visible listening response committed
once. The final restart preserved both decisions, cast, bank accounts,
relationships and all six diary years. Offer and follow-up screenshots were
inspected. Logs, profiles and screenshots are retained in
`build/r05/desktop-cold-cycle`; the initial two-year failure is retained in
`build/r05/initial-two-year-session`. Structure, code-map and whitespace checks
passed. Native Windows/macOS and Portrait/device validation remain separate work.


## Local Linux package

The archive in `build/r05/EraLife-linux-x86_64.tar.gz` was exported with Godot
4.4.1 from clean desktop commit `c02f528`. Its checksum passed, and the extracted
executable loaded all ten definitions with no catalog errors. All three packaged
story JSON hashes matched source; the persistence runtime also loaded.
`BUILD_INFO.txt` and `build/r05/package-check.log` retain the exact evidence.
This is a local playtesting package, not a published release or a Portrait build.
