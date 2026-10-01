# Sibling Stories

## Play the arc

**What We Call Fair** follows a finished **The Time We Owe** care story. The player
must be aged 25 to 85, with the same living parent aged at least 55 and an existing
living adult sibling listed among that parent's children. A partner cannot fill
the sibling role. Co-residence, a job and a family business are not required.
The ordinary two-year admission cooldown and limit of two active stories apply.

The sibling challenges how the family counted time, money and unseen care work.
The parent retains a voice in the arrangements. Trust affects whether the sibling
will agree to another plan or maintain separate arrangements, including after an
apology or payment. Family papers give both siblings a chance to decide how their
shared history will be remembered. These choices do not divide a legal estate
or transfer ownership of game assets.

Shared responsibility, repaired trust, respectful boundaries, distance and
resentment leave distinct saved outcomes. A private ending stays in the player's
own diary and does not offer an inherited story. A participant's death offers a
named bereavement chapter. An unloaded participant pauses progress, including
resolution of an expired deadline, until the same person is available; nobody
is substituted.

An adult child can later discover **More Than One Version**. Its two chapters
retain the parent's actual sibling outcome and allow the child to adapt what
helped, preserve both accounts, or put down the inherited argument. A deceased
aunt or uncle can still be remembered. The parent's saved decisions are unchanged.

The pack adds two stories, ten chapters and thirty responses to the ten existing
stories. Normal routes take several authored years. It is one narrative slice,
not a simulation of hourly care duties or probate.

## Owners and compatibility

Content lives in `project/data/sibling_stories.json`. LifeStoryEngine admits and
resolves it through the existing Pending Situations contracts, diary, relationship
and banking owners. The optional `eligibility.completed_story` gate requires a
finished earlier record. The `household_siblings` cast resolver uses that record's
saved parent, then at most 32 indexed parent references and 32 sibling candidates.
It reuses the `relative` and `supporter` ensemble roles.

The existing version 1 save contract needs no migration. Older story records
remain intact. A preceding care record without its saved ensemble is retained but
cannot supply the sibling continuation's parent. The continuation captures the
earlier care outcome and its own era price scale when admitted.

Paid responses transfer $250 or $350 at the Modern Era scale from the player's
personal bank to the sibling for agreed practical help. Labels show the scaled
amount. Insufficient funds or a frozen account reject the response before story,
relationship or wellbeing effects. All chapters have a free deadline response.
Company reserves are never spent by this arc.

## Verification

```sh
python3 scripts/test-headless.py test_sibling_stories
ERA_FAMILY_STORY=sibling_fairness bash scripts/test-living-households.sh cycle /tmp/eralife-siblings-desktop
# In the Portrait checkout:
ERA_PORTRAIT=1 ERA_FAMILY_STORY=sibling_fairness bash scripts/test-living-households.sh cycle /tmp/eralife-siblings-portrait
```

The regression exercises every response, multiple complete routes with the full
catalog, trust-driven refusals, old records, unavailable and deceased cast, deadline
fallbacks, rejected and successful payments, company separation, binary checkpoint
hydration and the next generation's memory. Calendar fixtures do not establish
whole-world lifetime correctness or how frequently arbitrary families qualify.

The graphical harness supplies an older parent and sibling to an isolated
Household, retains the full catalog, completes preceding stories through their
authored defaults, and clicks visible sibling choices. Its cold cycle spans
sixteen actual simulation years across two sessions and a final cold Continue.
It compares saved story history, cast, bank state and diary. Portrait preview and
an exact APK on a phone require separate evidence.

Desktop verified on 2026-10-01, shared implementation `3ff2e9a`: all 24
regressions passed, including all thirty responses, five distinct completed routes,
trust-driven refusal, bank boundaries and binary hydration. Retained full-suite
logs: `build/sibling-evidence/headless-desktop` in the primary checkout.

A software-rendered Xvfb playthrough with Mesa llvmpipe discovered the arc in 2009
through the full catalog. The visible $250 response transferred personal funds
from $10,000 to $9,750. Two choices were saved in 2010. An isolated cold Continue
restored exact story, cast, relationships, accounts and history, completed the
remaining visible choices, and saved the finished outcome in 2016. A final cold
Continue restored all four decisions, seventeen diary years and $9,750. Captured
chapter labels and controls were inspected. The complete run used sixteen actual
simulation years and retained the same cast.

The first restore while the regression suite ran concurrently exceeded the existing
90-second hydration limit. A later isolated final restore also timed out, then
passed on repeat. These failures remain in `restore-story.log` and
`restore-final.log`; the successful repeats are `restore-isolated.log` and
`restore-final-repeat.log`. Profiles, saves and screenshots are retained in
`build/sibling-evidence/desktop`. No production hydration change or increased test
timeout was made. Treat the intermittent cold-load timing issue as open under R07.

Portrait shared port `fd3488c` passes all 28 regressions. Full-suite logs are
retained in `build/sibling-evidence/headless-portrait` in the primary checkout.
Touch harness `6ff438c` adds screen-touch responses and swipes of the existing
scrollable story text. The 420x900 full-catalog preview discovered the story and
saved its first two visible decisions in 2010 with $9,750. A cold diagnostic
Continue restored those exact decisions, cast, relationships, accounts and diary,
then touch swipes and taps completed the review and return chapters. The finished
2016 save has four decisions, seventeen diary years and $9,750. Both the story
body and deadline were visually inspected; controls wrap and remain reachable.

Portrait's original `restore-story.log` and `restore-repeat.log` exceeded the
normal 90-second hydration limit. An ignored diagnostic copy of the harness
waited up to 240 seconds to measure eventual state fidelity and enable the touch
checks. This is not a pass of the normal cold-load timing criterion. No tracked
timeout or production persistence code changed. `restore-diagnostic.log` reached
hydration but failed an incorrect new test assumption about the text scroller;
it also records two missing screenshot-directory errors. The corrected
`restore-diagnostic-touch.log` passes the complete playthrough. Retain these logs
in `build/sibling-evidence/portrait`.

A separate 360x640 cold diagnostic Continue restored a copy of the 2010 profile,
swiped the review body to its deadline, tapped the visible copies response and
saved 2011 with three decisions. Story title and response labels wrap; the body
and options retain their separate scroll regions. Screenshots were inspected.
Evidence is in `build/sibling-evidence/portrait-small`. A final 420x900 cold
diagnostic Continue restored the finished 2016 save with all four decisions,
same cast, seventeen diary years and $9,750. This is state-fidelity evidence with
the 240-second diagnostic window, not a normal timing pass. The final log is
`build/sibling-evidence/portrait/restore-final-diagnostic.log`.

## Android package and next checks

The signed ARM64 performance-preview APK is retained in the primary checkout:
`build/sibling-evidence/package/EraLife-portrait-android-performance.apk`.
Its package is `org.eralife.community.portrait`, version code 4. It uses the same
local test signing certificate as the existing Portrait APK. Signature verification,
manifest extraction and all four packaged story JSON files match source. Gameplay
source is committed at `6ff438c`; documentation was pending during export.
`BUILD_INFO.json`, `SHA256SUMS.txt` and build/signature/manifest logs sit beside it.
APK SHA-256:
`bc52c7e30e796b9bf1fc16eeebdb729159d173f8baa902bc425a73eb04883e8d`.

No Android device was connected, so this exact APK has not been installed or
played on a phone. Next: on Honor, verify fresh entry, sibling cast, story scrolling
and choices, age/save, full process stop and cold Continue; retain any failure.
Then profile the normal cold-load timing under R07. Source is integrated locally
into `main` and `portrait`; temporary task branches are retired after preserving
evidence. No public release or push is included. Native Windows/macOS remain
separate checks.
