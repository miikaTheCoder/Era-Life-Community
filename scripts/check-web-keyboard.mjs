#!/usr/bin/env node
// Check the shipped Godot configuration path without launching WASM or a browser.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import vm from 'node:vm';

const htmlPath = resolve(process.argv[2] || 'project/platform/web/boot.html');
const enginePath = resolve(process.argv[3] || 'build/web/index.js');
const html = readFileSync(htmlPath, 'utf8');
const engineSource = readFileSync(enginePath, 'utf8');
const inline = [...html.matchAll(/<script\s*>([\s\S]*?)<\/script>/g)];
assert.equal(inline.length, 1, 'Expected one inline startup script');
const startup = inline[0][1]
  .replace('$GODOT_CONFIG', JSON.stringify({ executable: 'index', experimentalVK: false }))
  .replace('$GODOT_THREADS_ENABLED', 'true');

// These are the actual pinned export's internal conversion and availability gate.
const configSource = engineSource.match(/var GodotConfig=(\{[\s\S]*?\});var GodotFS=/)?.[1];
const availableSource = engineSource.match(/var GodotDisplayVK=\{[\s\S]*?available:(function\(\)\{[^}]*\})/)?.[1];
assert.ok(configSource && availableSource, 'Unsupported engine layout; inspect the exported keyboard path');

async function check(touch) {
  class Canvas {
    tabIndex = 0;
    focus() {}
  }
  const canvas = new Canvas();
  const elements = new Map();
  const failures = [];
  const context = vm.createContext({
    window: touch ? { ontouchstart: null } : {},
    navigator: { languages: ['en-US'] },
    HTMLCanvasElement: Canvas,
    document: {
      getElementsByTagName: () => [canvas],
      getElementById: (id) => {
        if (!elements.has(id)) elements.set(id, { style: {}, remove() {}, removeAttribute() {}, appendChild() {} });
        return elements.get(id);
      },
      createTextNode: (text) => ({ text }),
      createElement: () => ({}),
    },
    sessionStorage: { removeItem() {} },
    console: { error: (error) => failures.push(String(error)) },
    fetch: () => { throw new Error('Network access is forbidden in this check'); },
  });
  vm.runInContext(engineSource, context, { filename: enginePath, timeout: 2000 });
  const RealEngine = vm.runInContext('Engine', context);
  let runtimeConfig;
  let starts = 0;
  function TestEngine(config) {
    const instance = new RealEngine(config);
    // Keep real startGame/update/getGodotConfig; stub only loading and execution.
    instance.init = async () => {};
    instance.preloadFile = async () => {};
    instance.start = async () => {
      starts += 1;
      runtimeConfig = instance.config.getGodotConfig(() => {});
    };
    return instance;
  }
  TestEngine.getMissingFeatures = () => [];
  context.TestEngine = TestEngine;
  vm.runInContext(`(function (Engine) { ${startup} })(TestEngine);`, context, { filename: htmlPath, timeout: 2000 });
  await new Promise(setImmediate);
  assert.deepEqual(failures, [], 'Shell startup reported a failure');
  assert.equal(starts, 1, 'Shell must start the engine once');
  assert.equal(runtimeConfig.virtualKeyboard, true, 'Shell must enable the Web keyboard');
  context.runtimeConfig = runtimeConfig;
  const available = vm.runInContext(
    `var GodotConfig = ${configSource}; GodotConfig.init_config(runtimeConfig); (${availableSource})()`,
    context,
    { timeout: 2000 },
  );
  assert.equal(available, touch, 'Keyboard availability must retain the touch-device gate');
  console.log(`PASS ${touch ? 'touch' : 'desktop'} configuration: virtualKeyboard=true, available=${available}`);
}

await check(true);
await check(false);
console.log('Web keyboard configuration: PASS (no browser or OS keyboard exercised)');
