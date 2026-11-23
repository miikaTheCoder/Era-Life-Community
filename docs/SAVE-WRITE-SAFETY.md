# R16: Preserve normal saves during failed writes

Task: `codex/essential-roadmap`, based on `a4b8d0a`. Target: desktop `main`.
The roadmap update and this bounded persistence repair are one PR. Existing
Connected Lives corrections in the original checkout remain separate work.

## Defect and change

`GameState.save_game` delegates normal saves to
`GameStateSerializationRuntime.serialize_to_path`. Previously it opened the
existing destination with `FileAccess.WRITE`, truncating the old life, then wrote
without checking the result. Metadata and success could be published after a
failed write. Both binary and JSON formats used this pattern.

The writer now encodes the same payload, writes a uniquely named sibling ending
in `.tmp`, checks write/flush status and byte length, closes it, then renames it
onto the destination. The schema, binary encoder, reader, action IDs and paths of
successful saves are unchanged. Summary and continuity publication follow success
only. Failures retain the existing `write_failed` reason with an I/O error code.

A failed write removes its partial file. A failed rename preserves the complete
new file and includes `recovery_path` in the failure report. A process killed
while writing may leave a partial `.tmp` sibling, but it cannot truncate the old
save. Existing save discovery filters for `.bin` and `.json`, so temporary files
are not offered as playable lives. No automatic stale-file removal is introduced.

## Reproduce and verify

Use the pinned Godot 4.4.1 binary through `GODOT_BIN` if it is outside this checkout:

```sh
python3 scripts/test-headless.py
python3 scripts/test-save-interruption.py
python3 scripts/check-structure.py
python3 scripts/code_map.py --write
python3 scripts/code_map.py --check
```

`test_atomic_save` covers initial/replacement binary and JSON saves, existing
reader compatibility, successful metadata publication, failed open, failed rename,
recovery bytes and failure metadata. Its small payload fixture bypasses world
creation, not the production encoding or file-writing implementation.

The POSIX fault runner uses disposable XDG profiles and a 64 KiB file-size limit.
For each format it creates a valid old save, attempts a larger replacement, then
checks exact original bytes and decodes them in a new process. One case terminates
the writer with SIGXFSZ; the other allows a real write error and checks that the
production serializer returns failure without publishing metadata. It does not
fill the host disk or modify player saves. It requires an already imported project.

Initial baseline reproduction used sentinel old bytes: all four cases destroyed
them, and the handled errors incorrectly reported success. Retained baseline:
`build/tests/save-interruption-1cy3htkj/`. The first fixed run preserved all four
sentinels: `build/tests/save-interruption-iz3uaxlz/`. The final runner strengthens
that check with valid prior saves and a separate reader process. An earlier probe
using `/dev/null` as the Godot log path crashed at startup and proves nothing about
save writing; its logs remain in `save-interruption-umkbyowh/`.

Final source verification on Godot 4.4.1:

- Full frozen-source suite: **30/30 pass**, including import and the final recovery
  file assertions, in `build/tests/headless-8inwzkw2/`.
- Valid-prior-save fault runner: **4/4 pass** in
  `build/tests/save-interruption-uqr4x4we/`. Both formats retain exact old bytes
  under interruption and handled write failure, then decode in a fresh process.
- Structure, generated code-map freshness, whitespace, Python syntax, local
  documentation links and the no-em-dash rule pass. Historical roadmap content
  matches committed `a4b8d0a` apart from relative-link rebasing.

The earlier full suite `headless-vifdlkea` also passed 30/30, but started before
final recovery-file handling was frozen. Use `headless-8inwzkw2` for final-source
evidence.

Graphical evidence uses a private Xvfb display and isolated profile at
`build/save-write-gameplay/`. Household creation saved Bea Desktop at age 9,
year 2001, $10,000, diary 1 and world feed 130. The first cold restore exited
143 after about 23.5 seconds, ending with a broken X connection and no PASS
marker; `restore.log` retains it. This was earlier than the 900-second shell
limit. The reason for display/session termination is unconfirmed.

A bounded retry on a fresh private display passed: it restored the same actor,
year, diary and feed, advanced to age 10/year 2002/$10,000 and saved diary 2,
feed 135. The creation Life journal and save confirmation were visually inspected.
The final zero-year cold restore also passed, preserving Bea (actor 1), age 10,
year 2002, $10,000, diary 2/feed 135 and family IDs 1/2/3. Its inspected Life
screen agrees with the saved state. Logs: `household.log`, `restore-retry.log`
and `final-restore.log`; screenshots include
`screens/final-restore/restore-life.png`. These short Linux routes verify normal
save/Continue behavior, not a whole lifetime or another platform.

## Limits and follow-up

These are Linux process-interruption and I/O-failure checks, not a power-loss or
filesystem-durability guarantee. `flush` does not establish parent-directory
fsync. Summary/continuity files are derived metadata and are not a multi-file
transaction with the save. Rewind snapshots use a separate pipeline covered by the follow-up below. Full lifetime progression remains R17.

Godot 4.4.1's [Windows rename implementation](https://github.com/godotengine/godot/blob/4.4.1-stable/drivers/windows/dir_access_windows.cpp#L254)
removes the old destination before moving a differently named source. Therefore
this patch does not claim atomic final replacement on Windows. If that final
move fails, the complete new temporary file is retained for recovery; a crash
inside that Windows replacement gap is still an open platform acceptance case.
Windows/macOS native checks, browser storage synchronization after rename and
page termination, and the Portrait port/device test remain unverified. Keep these
limitations in the target release gate instead of treating Linux results as a
cross-platform certification.

Source inspection of [Godot's Web synchronization](https://github.com/godotengine/godot/blob/4.4.1-stable/platform/web/os_web.cpp#L75)
shows that closing a writable user file schedules synchronization for a later
main-loop iteration. The new write/close/rename sequence does not yield. That
supports retaining the existing scheduling mechanism, but is not an observed
browser save/reload pass. R09 still requires the real browser check.

## Rewind storage

The original incremental writer opened the destination for writing on the
first chunk. The regression in `build/tests/headless-2ft6mpwy/` observed that
the old file changed before the replacement finished. The writer also lacked
an error report for a failed open.

The replacement uses the existing binary format and chunk budget. It checks
each flushed chunk and confirms the staged file length before renaming the
file and updating the rewind history. Replacing a year already in the history
moves that year to the newest slot. Starting another capture or resetting the
life removes an unfinished temporary file. A killed process can leave a partial
`.tmp` file, which the game never offers as a rewind. If the final rename fails,
the completed file is retained at `recovery_path` in the pipeline report.

Run the focused regression and Linux process tests from an imported checkout:

```sh
python3 scripts/test-headless.py test_rewind_storage
python3 scripts/test-save-interruption.py --rewind
```

In `build/tests/rewind-interruption-bqyk2xs5/`, the 64 KiB limit first killed
the writer with SIGXFSZ and then produced a handled write error in a second
run. In both cases the prior snapshot remained byte-identical and a separate
process decoded actor 42 in year 2001. The handled error discarded its partial
file. The platform and power-loss limits described above also apply to rewind.

The graphical Household smoke created Bea Desktop and saved her at age 9 in
2001. A new process restored the same actor, diary entry, 129 feed entries
and $10,000 balance. After the next Age Up, an instrumented check drove the
live rewind capture to completion and decoded actor 1 at age 10 in 2002,
with three NPCs in the snapshot. The Household and restore flows both passed.
The instrumented script and its logs are retained in `build/rewind-household/`.

All 31 Godot 4.4.1 headless regressions passed on implementation `987f9b0`.
The logs are in `build/tests/headless-qiu3npf5/`. Structure and code-map
freshness checks also passed.
