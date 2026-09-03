# PC playtest checklist

Use the Linux or Windows desktop build and record its release tag. Keep macOS
experimental until someone can test it on a Mac. Android is a separate effort.
Back up any life you care about before testing; use a new life for each route.

The post-alpha-1 working tree includes four repairs found by extended testing:
relationship ID normalization on Continue, the resident yearly phase schedule,
diary entries for quiet years, and finalization after a frame-budget yield.
The original published alpha-1 archives do not include those repairs. Local
candidates are under `build/desktop-long-validation/candidate/`; their build
metadata explicitly records uncommitted source changes.

Long-life validation is not yet a clean pass across all modes. Household and God
Mode runs timed out during yearly relationship/event processing, and a Narrative newborn
save restored its original relationship score on the first frame but showed a
different score after background hydration. Record these as unresolved; do not
replace or retag the existing release based only on successful exports.

## Four routes

Run Household, Narrative → newborn, Narrative → adult continuation, and God Mode.
For Household, create a parent, a child and a roommate, then play the child.
For each route, aim for 25 years of play in five-year sessions.

| When | Try | Check |
| --- | --- | --- |
| Creation | Enter the life through its menu | Correct character, age, stats, story history and family |
| Childhood | Open School and Pending Situations; choose an available schooling response | Enrollment, school stage and diary agree; the choice produces a result |
| School years | Study and interact with a classmate when those actions are available | A visible result; grades/stats/relationships respond as described |
| Adulthood | Open Career, browse a suitable job and apply | A visible offer/rejection; accepting a job changes the role and income |
| Following years | Age with the job; try a work action | Employment, money and diary progress; no silent stuck action |
| Any age | Open Relationships and interact with an available person | Correct person and relationship; an action result appears |
| Events | Open Pending Situations and resolve several choices | Choice is acknowledged and resolved state is consistent |
| Every five years | World → Save Game, fully quit, relaunch, press C | Same age, year, money, school/job, relationship scores and earlier diary entries |
| After each reload | Repeat an action and age another year | The restored life continues; old history remains and new results appear |

Close an open school, career or relationship overlay before selecting another
main navigation tab. Check for stale information: an adult should not still see
the same childhood-only options solely because an earlier screen was cached.

A natural death is a result to record, not a reason to silently start a replacement
life and count it as a 25-year pass. Record the cause and whether continuation works.

## Report a problem

Use [this fork's Issues](https://github.com/miikaTheCoder/Era-Life-Community/issues).
Include the release tag, OS, entry mode, age/year, steps, expected result and actual
result. Add a screenshot and a log excerpt if helpful. Remove private information
before posting logs or saves; GitHub Issues is public.

## Automated aging and checkpoint run

On Linux with the pinned Godot 4.4.1 toolchain and a graphical desktop:

```sh
bash scripts/test-desktop-long.sh household /tmp/eralife-household-long
bash scripts/test-desktop-long.sh narrative-family /tmp/eralife-newborn-long
bash scripts/test-desktop-long.sh narrative-continue /tmp/eralife-adult-long
bash scripts/test-desktop-long.sh god /tmp/eralife-god-long
```

Each command uses a new isolated profile, runs five five-year sessions, and checks
the final checkpoint in a sixth process. It stops on a failure. Logs and screenshots
remain in that profile. A tiling window manager may need the test window floated
at 1440×900. `ERA_EXPLORE=1` additionally opens the school, career and relationship
screens for inspection; it does not complete their activities for you.

These checks cover aging, yearly execution and checkpoint continuity. They do not
replace the school, job, event-choice and usability checks above. Passing an export
or an age counter check alone does not certify those systems.
