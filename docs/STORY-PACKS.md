# Author a community story

EraLife loads data-only story packs from `user://mods/stories/*.json` when the
Life Stories engine starts. Restart the game after adding or changing a pack.
On Linux the normal location is the Godot app's `mods/stories` directory under
your XDG data home. Use Godot's **Project > Open User Data Folder** when running
the editor to locate the exact directory for this project. Test with a disposable
profile so your regular saves remain separate.

Copy [the working sample](../examples/story-packs/community_first_story.json),
rename its `pack_id` and every story ID, and write your own chapters. The sample
is not installed by default. It offers an adult with an existing friend a walk
and a later invitation, with a complete free route in either direction.

## Validate and install

Use the project's Godot 4.4.1 binary after importing the project:

```sh
build/tools/godot-4.4.1/Godot_v4.4.1-stable_linux.x86_64 --headless \
  --path project --script "$PWD/scripts/validate-story-pack.gd" -- \
  "$PWD/examples/story-packs/community_first_story.json"
```

The command exits nonzero and prints the story/chapter and cause when invalid.
Copy a passing file into `mods/stories` in your chosen user data directory, then
restart. Eligible stories appear in Pending Situations using the ordinary
two-active-story limit and two-year admission cooldown. A pack does not create
people or force itself ahead of built-in stories. The sample requires an existing
living friend within five years of the controlled adult's age.

## Version 1 format

The top level contains `schema: "eralife.life_stories"`, `version: 1`, `pack_id`,
and a nonempty `stories` array. Pack IDs contain 3 to 48 lowercase letters, digits
or underscores, starting with a letter. Story IDs are `pack_id.story_name`, with
the same rules for the suffix. Duplicate IDs are rejected, never overridden.

Each story needs `id`, `title`, `category`, `cast`, `start`, and `nodes`.
Optional fields are `series`, `eligibility`, `era_context`, `trust_from`,
`origin_story`, `allow_deceased_cast`, `death_node`, `separation_node`, and
`connections`. The schema is data, not a scripting interface.

Supported casts:

| Cast | Existing participant |
| --- | --- |
| `friend` | Living friend within five years of the player's age |
| `parent` | Living parent aged at least 55 |
| `relative` | Adult parent or sibling with the existing loan eligibility |
| `mentor` | Employed coworker at least five years older |
| `partner` | Living reciprocal adult partner |
| `child` | Living reciprocal child aged 16 to 30 |
| `story_cast` | Original adult participant from `eligibility.completed_story` |
| `legacy` | Participant in a parent's public memory, optionally restricted by `origin_story` |
| `parent_memory` | Parent whose completed public `origin_story` cast this controlled child |

`eligibility` supports `min_age`, `max_age`, `employed`, and `completed_story`.
Use `trust_from: "cast"` for choices whose acceptance depends on the other
person's affection before the response. Below 45 follows `next_untrusted`;
otherwise the normal `next` is used. An apology must not imply automatic consent.

A node needs `title`, `text`, `default`, `choices`, and optionally a positive
integer `deadline` (default 2 years). Each response needs `id`, `label`, `result`.
Optional effects are:

- `next` and positive integer `delay`: a later chapter, never a same-year loop.
- `next_untrusted`: alternate later chapter for low trust.
- `transfer`: a signed personal transfer in Modern-era units. Negative pays the
  participant; positive receives money from them. Era scaling is saved on admission.
- `relationship`: change to the relationship with the participant.
- `stats`: changes to the player's `smarts`, `mental_health`, `health`, or
  `job_performance` (integers from -100 to 100).
- `legacy`: a stable outcome tag; `private` prevents inherited disclosure.
- `outcome`: readable completion text. Omitting `next` finishes the story.

Every chapter requires a free default: no transfer or business cost. Write defaults
that do not pretend the player attended, paid, or gave consent. Use `{person}` for
the saved participant's name. A `death_node` can use `{lost_person}`. Only partner
stories support `separation_node`; absence during loading is not proof of breakup.

Connections are optional recollections, captured when the new story begins:

```json
"connections": [{
  "story": "partner_futures",
  "texts": {"separate_pursuits": "You remember making room for separate pursuits."}
}]
```

Only the controlled person's completed public outcomes qualify. Missing, private,
or unfinished stories add no text. Connections do not alter earlier records or
force an outcome in the new story. Avoid implying a listener knows private facts.

## Limits and compatibility

Packs are JSON only. They cannot load scripts, resource paths, executable hooks,
migrations, ensemble relationship operations or company effects. Each file is at
most 256 KiB, with at most 32 stories, 64 nodes per story, 16 choices per node,
and 8 connections per story. At most 32 JSON files load in filename order.
Deadlines are 1 to 50 years; money effects are bounded to 100,000 Modern-era units.
Missing destinations, cycles, unreachable chapters, unsafe defaults, malformed
types, unsupported roles and duplicate IDs are rejected. A rejected file cannot
disable built-in stories or another valid file.

Keep story, node and response IDs stable after release. Removing a pack leaves
its saved state intact and pauses that content. Reinstalling a compatible pack
allows it to continue; a changed node layout is not a supported migration. Close
the game before replacing files. The game has no hot reload for this surface.
If a saved chapter is absent in the installed version, it pauses with an explanation
in the Family chronicle. Restore the compatible pack rather than deleting the save.

Run `python3 scripts/test-headless.py test_connected_lives` for the reference
loader/continuation checks. Test your own complete routes, money failures, free
defaults, missing/deceased cast and save/Continue before distributing a pack.
The authoring path is implemented on desktop `main`; native Portrait porting and
browser file import are separate tasks. This does not add a marketplace or editor.
