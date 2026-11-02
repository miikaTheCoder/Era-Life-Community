# R09: mobile browser audit

Initial audit: **2026-09-30**, desktop/browser `main` at `c60a48a`.
This target is the Web export, not the native Portrait application. No gameplay,
export settings, Hyprland configuration, or Portrait files were changed.

## Available test coverage

| Target | Access established | Result / limit |
| --- | --- | --- |
| Honor 400 Lite, Android, Brave | Owner confirms device and browser; browser/Android versions not yet recorded | Real-phone test pending. ADB successfully listed devices outside the restricted sandbox, but the list was empty. |
| Linux desktop, connected Brave / Chromium 154 | Connected browser extension worked | Existing export booted and entered the adventure library with mouse input at narrow widths. Desktop viewport simulation only. |
| Linux Chromium 152, Brave 154, Firefox 155 | Installed binaries reported these versions | Only connected desktop Brave was exercised. Firefox and standalone Chromium compatibility remain untested. |
| Apple device / Safari | Owner has no Apple device | iOS validation unavailable in this session. An iPhone-sized Chromium viewport does not test Safari. |
| T3 collaborative preview / device automation | Preview status and open explicitly reported unavailable; device tool reported access disabled | Used the connected Brave extension for desktop inspection. No simulator/emulator access established. |

Native Portrait's earlier Honor results do not validate the Honor's browser.
R09's Android and iOS completion criteria remain open.

## Artifact and method

Used the existing September 28 export in `build/web/`, not a newly rebuilt export
of the current branch. All 15 entries in `build/web/SHA256SUMS.txt` passed.
The engine logged Godot **4.4.1 stable**, WebGL 2.0 and cross-origin isolation.

Key SHA-256 digests:

```text
index.pck  2ecc51f827f073720bf327e2e638d4170120ab7bb912a1b2585834cf734b63a8
index.wasm 06e279b5d08a8888fc6c670b12d48c0e953bb526429ce521f2e17ec91fc15286
```

The existing preview server used a separate origin,
`http://localhost:8069/?trace=1`, to avoid the usual browser save origins.
Trace: `build/logs/r09-browser.jsonl`. It recorded the known Emscripten
main-thread blocking warning, with no uncaught exception in this limited route.
No life was created or saved during this pass.

Requested viewport presets were 390x844 and 360x640. DOM measurement reported
433x937 and 400x711 CSS pixels respectively, with devicePixelRatio about 0.9.
The override therefore did not establish the requested exact CSS dimensions.
These are narrow desktop views, with the desktop user agent and mouse input.
The viewport override was reset and the audit tab closed after inspection.

## Findings

| Area | Evidence | Status / next check |
| --- | --- | --- |
| Boot and initial entry | Intro, title, three-mode menu, and Begin Adventure library rendered on the isolated preview | Works in the limited desktop route. Real-phone boot remains open. |
| Phone-width readability | Mode menu kept three columns. Title and adventure descriptions became extremely small. Owner confirmed the text was unreadable in the supplied screenshot. | Reproduced usability blocker in narrow desktop Brave. Confirm on Honor before changing presentation. |
| Viewport scaling | Source sets a 1440x900 design viewport, `canvas_items` stretch and `expand` aspect. EraShell chooses narrow layouts from Godot viewport width. | Likely cause of the shrunken desktop layout: browser canvas resizing alone does not establish a phone-sized logical game layout. Verify logical viewport and scale on-device before selecting a fix. |
| Mobile input adaptations | `MobileSupport.is_enabled()` checks native `android` or `--mobile-preview`; Web preset has no custom feature enabling this path. | Browser touch-to-mouse is enabled globally, but the native mobile scroll/form/title adaptations do not automatically run on mobile Web. Touch scrolling and keyboard entry need real-device checks. |
| Texture compatibility | Web export enables desktop VRAM compression and disables mobile VRAM compression. | Compatibility gap to investigate against the Honor's actual WebGL capabilities; no texture failure reproduced here. |
| Zoom and browser chrome | HTML shell disables user scaling, hides body overflow, and sets `touch-action: none`. | Browser zoom cannot be assumed to rescue unreadable text. Check address-bar changes, keyboard occlusion, orientation and game scrolling on Honor. |
| Save and Continue | Earlier desktop Web evidence in WEB.md covers save/reload/Continue. | Not rerun in this audit and not established on mobile. Test same-device, same-origin persistence after backgrounding and browser restart. |
| Hosting and performance | Threaded export; approximately 41.85 MB engine plus 26.06 MB pack before transfer compression. Preview is loopback-only. Prior plain-static reload stall remains open. | Measure cold/warm phone launch and memory. Use secure localhost forwarding or a valid HTTPS host. Public-host and Safari checks remain open. |

Godot's [4.4 Web documentation](https://docs.godotengine.org/en/4.4/tutorials/export/exporting_for_web.html)
describes mobile performance limits, Safari WebGL caveats, target texture
compression, and secure-context/isolation requirements. These are reasons to
test compatibility, not proof that this particular phone or Safari build fails.

## Repeatable desktop inspection under Hyprland

1. Run `python3 scripts/serve-web.py --port 8069` and open
   `http://localhost:8069/` in desktop Brave.
2. Right-click and choose Inspect, then toggle the device toolbar using its
   phone/tablet icon. Dock DevTools inside the browser if tiling makes separate
   windows awkward. No compositor configuration change is needed.
3. Select Responsive and enter 360x640, 390x844, and 420x900. Choose Mobile
   rather than Mobile (no touch) when testing simulated touch. Reload after
   changing device mode, then check portrait and landscape separately.
4. Verify `window.innerWidth`, `window.innerHeight`, and
   `window.devicePixelRatio` in the Console. Record measured dimensions rather
   than assuming the toolbar or outer window dimensions are correct.
5. Keep browser page zoom at 100 percent. DevTools preview zoom can fit the
   viewport into the available screen area, but does not fix game typography.

[Chrome's device-mode guide](https://developer.chrome.com/docs/devtools/device-mode)
explains that this is an approximation. Even simulated touch cannot establish
phone GPU, memory, keyboard, storage or Safari behavior.

## Next real-phone pass

Connect the Honor with USB debugging authorized, record its Android and Brave
versions, and verify that `adb devices -l` lists it as `device`. With the existing
loopback preview running, forward it without exposing a LAN server:

```sh
adb -s DEVICE_SERIAL reverse tcp:8069 tcp:8069
```

Open `http://localhost:8069/?trace=1` in the Honor's normal Brave profile. Keep
the same origin for repeat loads and save checks. A plain HTTP LAN IP is not an
equivalent secure-context test for this threaded export. Remove only this test
forward after the session:

```sh
adb -s DEVICE_SERIAL reverse --remove tcp:8069
```

Record actual CSS viewport/DPR where remote inspection is available, orientation,
normal versus installed-PWA mode, cold/warm launch time, and any console errors.
First confirm readable title, modes, story library and choices. Then create a
life, make a choice, age up repeatedly, navigate Life/Relationships/School/World,
scroll by touch, enter text with the keyboard, save, reload, and Continue.
Verify identity, age/year, diary and relationships after restore, age again,
save again, and repeat after a full browser restart. Include background/resume
and browser Back behavior separately from native Android Back behavior.

Smallest implementation candidate after that baseline: a Web-specific logical
viewport and responsive layout adjustment in the existing presentation owners,
with desktop behavior preserved and no assumption that importing the native
Portrait shell will solve browser input or persistence. Safari needs a separate
real-device tester or available remote device service before R09 can be verified.

## Readability implementation and handoff, 2026-09-30

ADB subsequently recognized the authorized Honor. The preview on port 8069 and
the matching USB reverse forward worked. Its Brave trace reached the server with
`isolated=true`; the owner confirmed startup and supplied phone screenshots of
the three-column menu and God Mode form. Those screenshots confirm the
readability defect on real hardware. The reduced user agent reports Chromium
154, but its Android 10 token does not establish the actual Android version.
No full mobile life or storage cycle was certified.

The phone then disconnected to charge. The following changes are on browser
`main`, not the native Portrait app:

- `platform/web/WebSupport.gd` supplies CSS viewport dimensions to the existing
  density contract. The physical backing buffer no longer makes a high-DPI phone
  appear desktop-wide. The startup and resize paths use the same contract.
- The existing menu's narrow layout now receives the correct logical width and
  displays one mode card per row inside its scroll container.
- God Mode's existing control rows use vertically switchable box containers.
  Labels sit above full-width fields on narrow Web views; the three reality
  choices also stack. Prepare world stays in the existing fixed footer.
- The presentation adapter enforces at least 16-pixel UI text and 48-pixel form
  targets on narrow Web views. Option menus receive larger item spacing.
- Web enables the existing touch-gesture arbitration for scroll containers,
  including swipes beginning over controls. Native Android detection and
  Portrait's own shell are not imported or changed.

Verification:

- Full pinned Godot regression suite: **24/24 passed**, including the new browser
  density/layout regression and existing UI, mobile gestures, saves and stories.
  Logs: `build/tests/headless-5r34_5tf/`. The initial focused attempt had a
  test-script type annotation error, corrected before the passing runs.
- Structure, generated code map and whitespace checks passed. Godot generated
  the new Web support script's `.gd.uid` during import.
- Web release export passed: `build/logs/export-web.log`, `build/web/` and its
  regenerated `SHA256SUMS.txt`. This export contains uncommitted task changes.
- Native desktop God Mode entry, one year and binary save passed in
  `/tmp/eralife-desktop-mJwIZn/god.log`. Existing shutdown warnings remain.
- Graphical layout fixture passed at logical sizes 360x640, 420x900, 844x390 and
  1440x900. It checks field bounds, scroll range, reachable preparation controls,
  resize behavior and preserved entered names. Screenshots/log:
  `/tmp/eralife-r09-visual/`. Aspect preservation prevents Hyprland tiling from
  distorting this fixture's screenshot shape; these are native fixture renders,
  not phone browser screenshots.
- Actual rebuilt desktop Brave at measured **393x700 CSS pixels** rendered a
  readable one-column menu. Scrolling reached God Mode, whose labels and fields
  stacked and scrolled with Prepare world visible. At measured **1440x900**, the
  same form returned to horizontal rows. Mouse/desktop browser evidence only.
  Trace: `build/logs/r09-reflow-browser.jsonl`, retaining the known Emscripten
  warning without an uncaught exception in this limited route. One initial
  screenshot request timed out during loading; the retry reached the game.

The fresh test origin is `http://localhost:8072/?trace=1`, avoiding the old
service-worker cache and existing port-8069 saves. The preview server was left
running for the next check. On reconnect, establish the new USB forward:

```sh
adb -s DEVICE_SERIAL reverse tcp:8072 tcp:8072
```

Then open that localhost URL in the Honor's normal Brave profile. First check
menu scrolling, God Mode field readability, swiping across fields without
accidental activation, option selection and keyboard entry. Repeat with the
browser toolbar changing height and in landscape. The native gesture regression
does not substitute for that phone pass. Continue with the full play/save/restore
route above after entry usability passes. Honor retest, Safari and public HTTPS
hosting remain open. No push or publication was performed.
