# An ordinary desktop life and its successor

On November 23, 2026, the Linux desktop playtest followed Maureen Ainsworth from birth to natural death, selected her son Robin, made a relationship choice as Robin, and restored his saved life in a new Godot 4.4.1 process. The graphical driver used a private X11 display, an isolated save profile, and the full desktop story catalog. Creation, introductions, naming, work, inheritance, saving, and Continue went through their on-screen controls.

## Maureen and Robin

| Year | What the player did or saw |
| --- | --- |
| 1872 | The Runaway Heir narrative led to the family birth path. Maureen was born to Joseph and Lillian Ainsworth. |
| 1878 to 1890 | Saved at six, quit, restored, and advanced to eighteen. The restored childhood retained the family, money, and diary. |
| 1890 to 1894 | Looked for work. The industrial-era occupations board showed no entry vacancy for the part-time roles she qualified for. Four dating invitations were declined on this route. At twenty-two, Maureen met Russell Whitlock through Relationships, opened his profile, and asked him out. Russell accepted. A fresh Continue preserved their reciprocal partnership. |
| 1900 | After several unsuccessful attempts to start a family, Maureen and Russell had a son. The player typed Robin's first name and confirmed his birth. The save recorded Robin as person 657 and both parents, Russell (502) and Maureen (1). |
| 1905 | The player named their second son Rowan (658). Both sons survived subsequent cold restores. Maureen also revisited the occupations board in later years. |
| 1936 | Maureen died naturally of old age at sixty-four. The death menu offered Robin, age thirty-six, and Rowan, age thirty-one. The player chose Robin and confirmed **Continue Lineage + Inheritance**. His first journal entry read “I remember my mother, Maureen Ainsworth.” |
| 1937 | Robin met Margaret Whitlock and asked her out. She accepted. The player advanced one year, saved, fully exited, and used title-screen Continue. The restored Robin was thirty-seven with Margaret (683) as his partner, parents 502 and 1, two diary entries, 970 world-feed entries, and the expected bank balance. |

The ordinary save records a single executed estate for Maureen with Robin as the named recipient. Her cash, vehicles, and business stakes were empty on this run. Two older family deaths had left cash with the deceased. Joseph died in 1893 and Lillian in 1909. Those deaths supplied the checkpoints for testing the NPC estate repair separately.

## Replay with a funded estate

The NPC estate repair was tested from Maureen's ordinary age-thirty-three save, after the births of both sons and before her mother's death. On the replay, four ordinary year advances brought Lillian to the same 1909 death. Her bank balance fell from 271299.187516247 to zero and Maureen's rose from zero to 271299.187516247. Lillian's estate recorded Maureen as the recipient. The accounting contract stores that amount in USD. Maureen's industrial-era interface displays pounds.

The test saved through the World menu at thirty-seven. A separate process restored the same family, accounts, currency, and receipt. In 1930, Russell died of old age at sixty-three and left Maureen another 4422 USD. Afterward, each deceased person's account held zero and each receipt named Maureen. Joseph had already died before the replay's starting save and his earlier estate remained unsettled.

Maureen died naturally at sixty-two in 1934. Both sons appeared in the lineage menu. The player selected Robin, age thirty-four, and confirmed **Continue Lineage + Inheritance**. Maureen's balance fell to zero. Robin received the full 275721.187516247 USD. His mother's receipt named him (657) and recorded that amount. His journal read “I remember my mother, Maureen Ainsworth.” Robin opened Relationships, met Frances Fletcher, and asked her out. She declined. The player advanced to 1935, saved, quit, and used title-screen Continue in a fresh process. At thirty-five Robin was single, with both parent IDs (502 and 1), two journal entries, 959 world-feed entries, the exact inherited balance, and the same estate receipt.

The maternal transfer is in `build/estate-natural/replay-years.log`. Under `build/material-succession/`, `age61-estate.log` records Lillian's and Russell's executed estates, and `life-material-3-from-61.log` records Maureen's death, both selectable sons, the balances before and after selection, Robin's first journal entry, and his date invitation. `heir-material-continue.log` records the cold restore, and `heir-estates.log` independently decodes the resulting save.

## Fresh life on the combined build

A second run started from an empty profile, with the same 802 production files
throughout. The smoke driver gained extra receipt and bank checks during the run. Ida Hargrove was born in 1886. Rupert accepted her invitation,
and she named their daughter Robin in 1908. Ida had three children and inherited
USD 499,175.343077976. At her natural death at 70, all three children appeared
in the chooser. Robin inherited the full balance, read her journal, asked Blake
Ward out, and was declined. At 49, a new process restored Robin in 1957 with
the same balance, parents and estate receipt, two diary entries and 1,079 feed
entries. The first frame to completed restore took 36.8 seconds.

The isolated profile is `build/exact-lifetime-founder-01/`. The manifests
`production-before.sha256` and `production-after.sha256` match. The terminal
and restore logs are `life-integrated-5-from-66.log` and
`heir-integrated-continue.log`.

## Restricted estates across generations

The first council review identified a case outside the ordinary playthroughs.
When an account was frozen, the first beneficiary could die before the payment
cleared. The regression reproduced a stranded bank balance and vehicle after
cold Continue. When the beneficiary chooses a successor with inheritance, the
unpaid claim now follows that choice. Earlier saves can recover the choice from
the intervening estate receipt. The eventual receipt records both the original
beneficiary and the person who received the assets.

The combined regression checks the restricted balance and vehicle across
checkpoint restoration, account reopening, another death notification and a
yearly retry. The reproduction logs are in `build/council-r2/`. The original
lifetime manifests above identify the production version before this correction.

## Reproduction

After importing the project with Godot 4.4.1 and setting `GODOT_BIN` if necessary, start a fresh profile and run further segments against the same profile. The commands below use a private software-rendered display.

```sh
profile="$PWD/build/lifetime-playtest"
export ERA_NATURAL_FAMILY=1
export LP_NUM_THREADS=2
ERA_YEARS=6 ERA_RUN_LABEL=birth xvfb-run -a -s '-screen 0 1600x1000x24' \
  bash scripts/test-desktop-modes.sh narrative-family "$profile"
ERA_YEARS=12 ERA_RUN_LABEL=to-adulthood xvfb-run -a -s '-screen 0 1600x1000x24' \
  bash scripts/test-desktop-modes.sh restore "$profile"
```

Continue in bounded restore segments with a new run label for each. The founder's lifespan, the people met, invitations, pregnancies, family stories, and available work depend on the generated world and ordinary simulation. After succession, run another process with `ERA_YEARS=0` to verify the saved heir.

## Retained evidence

The integrated checkout retains the original profile, screenshots, and logs under `build/lifetime-narrative/`. The following filenames identify the route and its boundaries.

| Evidence | File in the profile |
| --- | --- |
| Narrative birth and first save | `birth.log` |
| Childhood restore and age eighteen | `childhood.log` |
| Four invitations declined and age twenty-two saved | `partner-save.log` |
| Russell accepted and the couple saved before the Partner tab repair | `adulthood30.log` |
| Robin's birth and family save | `firstborn-save.log` |
| Rowan's birth and age thirty-three save | `life-family-1-from-29.log` |
| Subsequent twelve-year stages | `life-b-1-from-33.log`, `life-b-2-from-45.log` |
| Natural death, heir selection, journal, choice, and save | `life-b-3-from-57.log`, `screens/life-b-3-from-57/` |
| Separate processes restoring Robin and his estate receipt | `heir-b-continue.log`, `heir-receipt-cold.log` |

The route used ordinary saved checkpoints while fixing the relationship display and teaching the driver to answer the birth-naming popup and return from Relationships. Earlier diagnostic replays from those checkpoints are retained in separate logs. The completed route above follows the saved son Robin. The exact saved estate was independently decoded in `build/lifetime-route/estate-heir.log`.
