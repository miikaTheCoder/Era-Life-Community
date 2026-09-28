# Branch workflow

Updated 2026-09-28. There are two permanent development branches:

| Branch | Purpose | Local checkout |
| --- | --- | --- |
| `main` | Current desktop and browser game; default for new tasks | `/home/nextg/opencode-sandbox/Era-Life-Community` |
| `portrait` | Phone version with its own startup and touch presentation | `/home/nextg/.codex/worktrees/mobile-portrait/Era-Life-Community` |

The completed `browser-play` work is preserved in commit `cd6ca7d` and integrated
into `main`. Browser exports use the normal project checkout and do not need a
third permanent branch. See [the Web guide](WEB.md) for commands and evidence.

The temporary browser branch and checkout are retired after integration. Its
complete checkout, local builds, and logs are preserved in
`/home/nextg/Work/miikaTheCoder/Era-Life-browser-integration-backup-2026-09-28`.
The archive was verified against all 1,333 regular files, and the Git bundle
preserves the browser commit alongside both permanent branches.

## Starting and finishing work

1. Read `AGENTS.md`, `docs/AGENT-HANDOFF.md`, and `ROADMAP.md` in the intended
   checkout. Check `git status --short --branch` and `git worktree list`.
2. Default to desktop `main` unless the task is explicitly about Portrait or an
   existing task branch. Never reset or switch another task's occupied checkout.
3. For sequential work, use the clean permanent checkout. Use a temporary
   `codex/<task>` branch and isolated worktree when concurrent work needs isolation.
   Start it from current `main` or `portrait`, not an old feature branch.
4. Verify the change, integrate it into its permanent branch, and update the
   roadmap and handoff. Remove the completed task branch only after its commits
   are preserved and its worktree has no unfinished work. Preserve useful test
   evidence before removing a worktree.

Both permanent branches track the user's standalone repository, `origin`.
`upstream` is the original community repository and is used for deliberate imports. Ordinary pulls
on `main` must not silently select `upstream/main`.

Shared gameplay still develops on desktop first, followed by a verified Portrait
port. Branch cleanup does not unify the two platform implementations. Public
releases and APK verification remain separate steps.

## Consolidation record

Desktop `main` advanced from `800b573` to verified integration `cffca1d` without
rewriting history. This includes Shared Lives, Living Households, R01 save/Continue,
R07 input/display repairs, and the September 28 upstream integration. See
[integration evidence](UPSTREAM-SYNC-2026-09-28.md) for its checks and limitations.

`portrait` continues the former `codex/shared-lives-portrait` at `d9628e8` with
updated documentation. Its gameplay and platform files were not changed by this
cleanup. The former branch names below are historical, not starting points:

| Superseded branches | Where their commits are preserved |
| --- | --- |
| `mobile`, `codex/desktop-alpha`, `codex/crime-world-foundation`, `codex/desktop-stability`, `codex/sync-upstream-2026-09-01`, `era-life-new-ui`, `codex/shared-lives-desktop`, `codex/sync-upstream-2026-09-28` | `main` |
| `codex/mobile-portrait`, `codex/mobile-startup-performance`, `codex/shared-lives-portrait` | `portrait` |
| `codex/publish-v0.1.4-alpha.1` | Tag `archive/release-automation-v0.1.4-alpha.1` at `4e203d5` |

The release-automation tag preserves its unique workflow and notes without
activating the old publication workflow on `main`. Existing release tags remain.

The local recovery directory is
`/home/nextg/Work/miikaTheCoder/Era-Life-branch-backup-2026-09-28`.
It contains a verified Git bundle, the original branch tips/worktree inventory,
and the retired integration checkout's local evidence. This directory is a backup,
not a development checkout. Recovery of one old branch is possible with:

```sh
git fetch /path/to/before-consolidation.bundle refs/heads/OLD-NAME:refs/heads/codex/recovered-work
```

Historical documents retain the branch names and commits used for their tests.
Use the branch table at the top of this file to choose current work.

## Standalone repository

On 2026-09-28 the owner completed GitHub's Leave fork network operation for
`miikaTheCoder/Era-Life-Community`. GitHub's API confirmed `fork: false`, with no
parent or source repository, and `main` still selected as the default branch.
The repository URL and local remote URLs are unchanged. The `upstream` Git remote
still permits explicit fetches from the original community project; ordinary
development and releases belong to this standalone repository.

The conversion preserved desktop `a2ceae7`, Portrait `ad6fe96`, both release tags,
and the release-automation archive tag. Both published releases and their eight
assets remain available; their sizes and SHA-256 digests match the verified
backup. GitHub still attributes the checked desktop commit to `miikaTheCoder`.
The original Git history, contributor credits, and license remain intact.

The pre-conversion backup is at
`/home/nextg/Work/miikaTheCoder/Era-Life-standalone-backup-2026-09-28`.
It contains the complete history for `main`, `portrait` and local tags in a
verified bundle, public repository metadata, and both releases with all assets
checked against their published checksums. The local `browser-play` task was
excluded from changes. No gameplay or save files were modified by the conversion.
