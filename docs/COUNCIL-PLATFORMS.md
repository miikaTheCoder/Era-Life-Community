# Council: Portrait port and Web keyboard

Consultation `eralife-platforms-20261102-r1`, completed 2026-11-02. Each member
gave independent, separate verdicts for both artifacts using Codex with xhigh
reasoning and priority service. No production change followed the frozen heads.

| Artifact | Base | Reviewed head | Council verdict |
| --- | --- | --- | --- |
| Portrait reliability and partnership port | `b47a973cd171e225e491fb0c15c35c79e8522d70` | `a25cda87ac6c84d9b9c4d12ebcf96c4b7d3067c0` | **APPROVED: The council gives its blessing.** |
| Web keyboard configuration | `137e148de85c5b44e19468c2989d2f7b0e9a4d8c` | `72ed96e2620b054379f90b99076a454b7827edbb` | **APPROVED: The council gives its blessing.** |

The Web implementation is `a41517f`; its later reviewed commit adds verification
and scope documentation. The Portrait work is already committed on `portrait`;
the Web repair is on `main`. No cross-platform production merge is needed.

| Member | Model | Portrait | Web | Reason |
| --- | --- | --- | --- | --- |
| A, Security | GPT-6 Astra | PASS | PASS | State/payment guards and branch boundaries remain intact; the Web override adds no new network or persistence behavior. |
| B, UI/UX/Design | GPT-6.1 Sol | PASS | PASS | Tested story controls, prices and deadlines remain usable; the Web override reaches the effective configuration with its touch gate preserved. |
| C, The Nerd | GPT-6 Astra | PASS | PASS | Shared source equality, guarded hydration and freed-control repair are supported; the Web checker exercises the actual configuration path. |

No blocking objections remain. These verdicts concern the bounded artifacts,
not general device readiness, all unfinished R09 layout work or public release.

## Evidence assessed

Portrait: [port report](PORTRAIT-PARTNER-PORT.md), 21-file diff, 30 final passing
regressions, the reproduced freed-control failure and passing repair, six final
graphical processes, three older-save timing samples, both window sizes and
APK provenance. Member C verified all 1,775 evidence hashes and 804 recorded
project inputs against the reviewed commit. A and B checked independent subsets.
All five packaged story catalogs match source. Signing identity is supported by
retained signature-tool logs; no reviewer installed the APK.

Web: [keyboard report](WEB-KEYBOARD.md), six-file diff, source and delivered
startup/configuration code, the corrected negative controls, passing checks,
three adjacent regressions, fresh export and all 15 artifact checksums. Member C
verified all 98 evidence hashes and 797 recorded working-tree inputs. Member B
also reran the read-only JavaScript checker against source, new delivered shell
and old delivered shell, obtaining pass, pass and expected failure respectively.

Reviewers did not rerun Godot, export, use browsers or access devices. The parent
also verified evidence hashes and inspected selected small-screen captures.
The original failed graphical run and checker-fixture failure remain failures;
later successes do not erase them. Runtime diagnostics and shutdown warnings
remain disclosed. The export includes preserved local Web layout changes and
is not presented as a clean-commit-only build.

## Nonblocking follow-up

- At actual 360x640, the notebook heading's upper line is clipped. Chapter
  identity, body, deadline and responses remain readable. Fit the long heading
  within the existing card without taking space from reading or responses.
- Touch harnesses prove drag movement, then programmatically position the
  deadline or response. A gesture-only path to an initially hidden response
  would strengthen manual reachability evidence. Touch latency remains unknown.
- The profiling runner should reject output nested inside fixture data and
  clean up its process group on cancellation as well as timeout. These are
  static tooling weaknesses, not incidents observed in the retained runs.
- The JavaScript checker accepts executable input. Use trusted pinned exports;
  its VM and rejected fetch are not hostile-code isolation.

These suggestions are not conditions for the two approvals and were not expanded
into another feature cycle. Earlier optional council suggestions remain in their
feature records.

## Remaining acceptance

Test the exact Portrait APK on Honor: restore cast and decisions, make a paid
and free choice, age/save, fully stop and Continue, then check interruption/resume
and navigation. Private software rendering and post-port timing samples do not
establish phone performance or a matched before/after Portrait comparison.
Company isolation is regression evidence; the graphical partner route has no
company. Natural discovery, family pacing and full-lifetime play remain open.

For Web, use the exact rebuilt artifact and a fixed isolated origin. Test Honor
and Safari keyboard editing, dismissal/reopening, IME, occlusion and rotation,
touch scrolling, creation, choices, age/save and cold reload/Continue. Effective
configuration is verified; real OS keyboard behavior and broader R09 acceptance
are not. No push, installation, deployment or public release was performed.
