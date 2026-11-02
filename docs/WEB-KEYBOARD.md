# Web keyboard configuration

R09 follow-up, 2026-11-02. The source shell now passes `experimentalVK: true`
to Godot's existing `engine.startGame` API. This enables the Web virtual-keyboard
path on touch-capable browsers. It does not establish that an OS keyboard opens
correctly on Honor or Safari, or that a focused field stays visible above it.

## Finding and bounded repair

The retained September 30 Web export sets `experimentalVK: false` in its
generated initial configuration. The source shell previously supplied no
override. The pinned Godot 4.4.1 JavaScript accepts overrides before startup,
maps this option into `virtualKeyboard`, and initializes its internal
`virtual_keyboard` setting. `GodotDisplayVK.available()` requires that setting
and an `ontouchstart` property on the browser window.

The source-supported defect is the disabled Godot path. It was not a newly
observed phone keyboard failure, and the audit did not establish the behavior
of the separate IME path. The repair changes one source-shell option. Layout,
gesture arbitration, viewport policy, persistence and service-worker behavior
are unchanged. Generated export files are not edited by hand.

## Available verification

`scripts/check-web-keyboard.mjs` runs the actual inline startup script against
the bundled engine's real `startGame`, configuration update and conversion code.
Loading WASM and starting the game are stubbed. It then runs the exported engine's
internal configuration conversion and keyboard-availability function, checking
both touch-capable and ordinary desktop window fixtures. Network access is
rejected. This is a configuration integration check, not browser automation.

```sh
node scripts/check-web-keyboard.mjs
# After a fresh export, check the delivered shell too:
node scripts/check-web-keyboard.mjs build/web/index.html build/web/index.js
```

The checker requires Node and an existing Godot 4.4.1 Web export. It fails if the
bundled engine layout changes, so a future engine upgrade requires inspecting
the relevant implementation before adapting the extraction.

Evidence is retained in `build/web-keyboard-evidence-20261102/`:

- `initial-fixture-failure.log`: the first checker used the wrong JavaScript
  binding for its engine stub and failed in its incomplete DOM fixture. This is
  a harness failure, not evidence of the production defect.
- `before.log`: the corrected checker fails on the unchanged source shell with
  `Shell must enable the Web keyboard`, actual false versus expected true.
- `after.log`: the same checker passes after the one-option repair. The touch
  fixture reports available; the ordinary desktop fixture remains unavailable.

The existing Web export is still the September artifact at this point, not a
build of the November source or this repair. Fresh export and adjacent Godot
regressions are deferred until the concurrent Portrait timing work finishes.
Council review follows those checks. No R09 completion or council approval is
claimed here. Existing uncommitted Web work remains preserved.

## Remaining acceptance

Use the exact rebuilt artifact on an isolated, fixed origin. Record its hashes,
browser/OS versions, CSS viewport, DPR, and browser versus installed-PWA mode.
Tap editable fields, enter and edit text, dismiss and reopen the keyboard, then
repeat after toolbar changes and rotation. Values must survive and the focused
field and preparation actions must stay reachable. Repeat touch scrolling over
interactive controls without unintended activation.

Create a life, make a choice, age, save and reload. Compare actor, year, diary,
relationships and balances after Continue, then repeat after background/resume
and full browser restart. Repeat on real iOS Safari when available. Phone and
interactive checks remain unavailable in this loop. Do not infer their success
from the configuration checker or native `--web-preview` fixtures.
