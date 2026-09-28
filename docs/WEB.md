# Desktop browser export

Browser support lives on `main`, alongside the desktop game. The completed
`browser-play` work was preserved in `cd6ca7d` and merged with the newer desktop
fixes. It exports the existing game with Godot **4.4.1 stable**. Gameplay, the
desktop main scene, binary saves, and native platform presets remain in use.

## Build and play

From the repository root:

```sh
bash scripts/setup-godot.sh web
bash scripts/build.sh web
python3 scripts/serve-web.py
```

Setup is only needed when the pinned editor or Web templates are missing. Open
`http://localhost:8060/`. The complete export is in `build/web/`; keep all its files
together. Opening `index.html` directly as a local file will not work.

For a retained browser console trace, use `http://localhost:8060/?trace=1`.
The local preview writes messages to `build/logs/web-browser.jsonl`, including
uncaught exceptions and rejected promises. This optional instrumentation is
injected by the preview server; it is absent from the exported HTML.

## Hosting and persistence

Use HTTPS in production, WebAssembly, and WebGL 2.0. A host that supports
response headers should send:

```text
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

Serve `.wasm` as `application/wasm`. The included preview server provides the
headers and MIME types on localhost. It binds to loopback and is for local tests.
The Web preset now enables Godot's PWA service worker. On a static host without
custom headers, it installs and claims the worker before the first reload, so
the threaded game can start. This was verified on a plain local static server,
not on a published GitHub Pages site. HTTPS is required away from localhost.

The worker caches the 40 MB WebAssembly engine and 25 MB game pack after their
first successful load. A repeated visit to the same origin can reuse both; an
isolated static-server reload issued no new requests for either file. The first
visit must still download and initialize them. The WebAssembly file compressed
from 41.85 MB to 9.41 MB with gzip in a local measurement, so production hosting
should compress it in transit. [Godot's Web guide](https://docs.godotengine.org/en/4.4/tutorials/export/exporting_for_web.html)
lists GitHub Pages as providing gzip. A cache may be evicted, and a new build or
origin can require another download.

The export retains threads because residency, hydration, and projection use
existing background workers. A single-thread template would require adapting
those owners. The custom Web shell is based on Godot 4.4.1's default shell; it
waits for the service worker to control the page before reloading. The default
shell reloaded on registration and reproduced a blank first visit on a static
host. The retry is bounded and reports a visible error if isolation cannot be
established.

Save through World > Save Game. Godot persists the existing `user://` files in
IndexedDB. Allow browser storage and keep the same origin, including the port,
when returning to a life. Wait for the saved confirmation and allow the browser
to finish its asynchronous storage synchronization before closing the page.
Browser storage clearing, private profiles, or another origin do not preserve
the same save. Native save directories are separate.

## Web adaptations

- `renderer/rendering_method.web` selects Compatibility; native renderer settings
  and Android's scene selection are preserved. Desktop texture imports are enabled.
- Web audio streams long music tracks. Sample playback reproduced an uncaught
  `NotSupportedError` when resuming a track and stopped the game loop.
- The state contract reads its origin through `globalThis.location`, which exists
  in both the page and same-origin workers. Reading `window.location` reproduced
  a worker `ReferenceError` during life creation.
- The TCP self-host listener is not created on Web. Requests to start it return
  `ERR_UNAVAILABLE` with `unsupported_on_web`. Native listeners retain their local
  opt-in behavior. Browsers support HTTP clients, not native TCP listeners.
- Updater HTTP requests disable `use_threads` on Web, where threaded HTTP requests
  are unsupported. The community's existing upstream-update policy is preserved.

## Verified on 2026-09-28

Chromium 153 in the Codex browser, with WebGL 2.0 and cross-origin isolation:

- Normal intro, title, and three-mode main menu booted.
- Begin Adventure > The Runaway Heir > narrative choices > family birth created
  Aris Helix at age 0 in year 617975306.
- Mouse Age Up and keyboard Return advanced five consecutive years. The diary
  showed ages 1 through 5 and year 617975311.
- Relationships, relationship profile/Back, School, World, Life, and diary
  scrolling worked through the rendered controls.
- World > Save Game confirmed a saved checkpoint. Browser reload exposed Continue
  for Aris Helix, age 5. Keyboard C restored the same person, year, and diary,
  including the entries for ages 3, 4, and 5.
- After Continue, mouse and keyboard Age Up reached age 7, year 617975313.
  A second save/reload exposed the updated age-7 Continue entry. Keyboard C
  restored Aris Helix at age 7 in year 617975313.

The trace retains the initial failures as well as the successful rebuilt runs.
Successful runs start at `2026-09-27T21:38:47Z` (UTC). There were no uncaught
JavaScript exceptions, GDScript errors, or fatal WebGL errors in these runs.
Emscripten emits a nonfatal main-thread blocking warning when threads are joined.
This is retained, not suppressed. The game's thread collectors poll `is_alive()`
before joining; removing joins would abandon thread cleanup. See
[Emscripten's explanation](https://emscripten.org/docs/porting/pthreads.html#blocking-on-the-main-browser-thread).
An earlier browser reload stalled during concurrent builds, then recovered;
subsequent reloads succeeded. Longer sessions and Firefox/Safari remain separate
validation, not established by this Chromium run.

Repository and native checks:

- Structure check, generated code-map check, shell/Python syntax checks, and
  `git diff --check` passed.
- Full headless suite: **23/23 passed**, logs in `build/tests/headless-eeb32txm/`.
- Web release export passed; `build/logs/export-web.log` and
  `build/web/SHA256SUMS.txt` retain build output and file checksums.
- Linux, Windows, and macOS release exports passed; `build/logs/export-*.log` and
  `build/SHA256SUMS.txt` retain output and archive checksums. Native Windows/macOS
  gameplay was not run on this Linux host.
- Android debug export and APK signature checks passed, using the existing local
  development key. The APK was not installed or tested on a phone.
- Graphical desktop Household creation, three years, School/Career/Relationships,
  and binary save passed in `/tmp/eralife-desktop-ThPTeb/household.log`. The existing
  resource-at-shutdown warning remains.

This is a desktop browser port. The separate Portrait branch and its documented
phone issues remain separate work.

## Startup measurement and limits

On this Linux host, a cold headless Godot editor launch took about 1.1 seconds
without the main scene and 13.2 seconds with it. Loading `main.scn` inside a
probe took about 11.4 seconds, mostly before instantiation. A packaged Linux
release took about 7.2 seconds to exit after its first frame. These numbers are
not Web or 2015 MacBook Air timings. The large scene and script dependency graph
is still a first-visit CPU cost, so the PWA cache does not promise a fast first
launch on an older machine. This pass improves repeat Web loads and avoids a
first-visit static-host failure without changing gameplay or native exports.
The final Web export and all 23 headless regressions passed after the shell
change; the retained regression log is `build/tests/headless-w1d4ipo6/`.

## Integration into main, 2026-09-28

The completed browser work is commit `cd6ca7d`, merged into desktop `e536c15`.
The only merge conflict was the generated code map, which was regenerated.
The original checkout, builds, and logs were archived and all 1,333 regular files
were verified in
`/home/nextg/Work/miikaTheCoder/Era-Life-browser-integration-backup-2026-09-28`.

- Structure, script syntax, code-map freshness, and whitespace checks passed.
- All 23 regressions passed in `build/tests/headless-54mg63wh/` with Godot
  4.4.1 stable. The initial sandboxed import could not open local sockets;
  `headless-ma3ly9q4/` retains that environment failure.
- The integrated Web release export and all file checksums passed. Outputs are
  `build/web/`, `build/logs/import.log`, and `build/logs/export-web.log`.
- Native Household creation, three consecutive years, and saving passed.
  Cold Continue passed on repeat with the same code, save, and 90-second
  hydration limit: Bea Desktop, age 11, year 2003, three diary years, $10,000,
  saved player fields, relationships, and world history preserved.
- Retain the first cold-restore timeout. Background loading advanced only to
  engine step 89/248 before the limit; the repeat reached 248 within about ten
  seconds of the first playable frame. The cause of this timing variation is
  unconfirmed. No production hydration change or longer test timeout was used.
  Both logs and screenshots are in `/tmp/eralife-web-merge-20260928/`.
- Brave/Chromium 154 on the supplied preview server passed normal narrative
  entry, one Age Up, Save Game, browser reload, and Continue. Helene of Chengdu
  returned at age 1 in 689349157 BCE with her birth history and first-year diary;
  another Age Up reached age 2 in 689349156 BCE. The isolated test origin was
  `http://localhost:8070/?trace=1`, separate from existing browser saves.
  `build/logs/web-merge-browser.jsonl` retains the known nonfatal Emscripten
  main-thread warning, with no uncaught JavaScript exception or GDScript error.
- A fresh plain static origin at port 8071 reached the title without manual
  refresh. One repeat reload remained on the HTML loading screen for over a
  minute without a reported JavaScript exception. The host received no second
  engine or pack download, but that alone does not certify repeat startup.
  Retain this static-host limitation separately from the passing preview-server
  reload/Continue check. The request log is `build/logs/web-merge-static-host.log`.
  A later return visit to the same cached static origin reached the title again;
  the intermittent reload stall was not diagnosed or repaired by this merge.

The integration logs, native test profile, and Web checksums are also retained
in the browser integration backup directory above, so checkout cleanup does not
discard the evidence. Use the preview server or a host that supplies COOP/COEP
headers while static-host repeat loading remains under investigation.

These checks do not establish public hosting, Safari/Firefox compatibility,
older hardware performance, or a Portrait port.
