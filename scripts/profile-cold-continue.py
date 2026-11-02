#!/usr/bin/env python3
"""Run sequential private-display Continue samples from copied test profiles."""
import argparse
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
p = argparse.ArgumentParser(description=__doc__)
p.add_argument('fixture', type=Path)
p.add_argument('output', type=Path)
p.add_argument('--offscreen', action='store_true', help='Use a private Xvfb software-rendered display')
p.add_argument('--samples', type=int, default=3)
p.add_argument('--years', type=int, default=0)
p.add_argument('--continue-profile', action='store_true', help='Copy once, then restore each preceding sample save')
a = p.parse_args()
if not a.offscreen:
    p.error('Continue requires rendered frames; use --offscreen for a private Xvfb display')
if a.output.exists() or a.samples < 1 or not 0 <= a.years <= 30:
    p.error('Use a new output directory, positive samples and 0 to 30 years')
binary = os.environ.get('GODOT_BIN', str(ROOT / 'build/tools/godot-4.4.1/Godot_v4.4.1-stable_linux.x86_64'))
if not subprocess.check_output([binary, '--version'], text=True).startswith('4.4.1.stable.'):
    p.error('Godot 4.4.1 stable required')
a.output = a.output.resolve()
a.output.mkdir(parents=True)
results = []
for index in range(a.samples):
    profile = a.output / f'sample-{index + 1}'
    source = a.output / f'sample-{index}' if a.continue_profile and index else a.fixture
    shutil.copytree(source / 'data', profile / 'data')
    env = os.environ.copy()
    for variable, folder in [('XDG_DATA_HOME', 'data'), ('XDG_CONFIG_HOME', 'config'), ('XDG_CACHE_HOME', 'cache')]:
        (profile / folder).mkdir(exist_ok=True)
        env[variable] = str(profile / folder)
    env.pop('WAYLAND_DISPLAY', None)
    env['LIBGL_ALWAYS_SOFTWARE'] = '1'
    env.update(ERA_MODE='restore', ERA_YEARS=str(a.years), ERA_FAMILY_STORY='sibling_fairness', ERA_PREVIEW_DIR='')
    started = time.monotonic()
    with (profile / 'output.log').open('w') as log:
        try:
            run = subprocess.Popen([
                'xvfb-run', '-a', '-s', '-screen 0 1440x900x24 -nolisten tcp',
                binary, '--display-driver', 'x11', '--rendering-method', 'gl_compatibility',
                '--path', str(ROOT / 'project'),
                '--script', str(ROOT / 'tests/profile_cold_continue.gd'),
            ], env=env, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
            run.wait(timeout=900)
            code = run.returncode
        except subprocess.TimeoutExpired:
            os.killpg(run.pid, signal.SIGTERM)
            try:
                run.wait(timeout=5)
            except subprocess.TimeoutExpired:
                os.killpg(run.pid, signal.SIGKILL)
                run.wait()
            code = 124
    content = (profile / 'output.log').read_text()
    errors = [s for s in content.splitlines() if s.startswith(('ERROR:', 'SCRIPT ERROR:')) and 'resources still in use at exit' not in s]
    result = dict(sample=index + 1, process_seconds=time.monotonic() - started, exit_code=code, errors=errors, passed=code == 0 and not errors and 'DESKTOP MODES: restore PASS' in content)
    for line in content.splitlines():
        if line.startswith('COLD CONTINUE TIMING: '):
            result['timing'] = json.loads(line.split(': ', 1)[1])
    result["passed"] = result["passed"] and "timing" in result and result["timing"]["first_frame_to_complete_ms"] <= 90000
    results.append(result)
    (a.output / 'results.json').write_text(json.dumps(results, indent=2) + '\n')
    print(json.dumps(result), flush=True)
    if a.continue_profile and not result['passed']:
        break
raise SystemExit(0 if all(r['passed'] for r in results) else 1)
