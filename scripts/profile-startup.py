#!/usr/bin/env python3
"""Measure the real mobile boot scene with an isolated save/config profile."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--entry", choices=["new_life", "title", "intro"], default="new_life")
    parser.add_argument("--headless", action="store_true", help="No graphical timing/screenshots; useful for route checks")
    args = parser.parse_args()
    binary = os.environ.get("GODOT_BIN", str(ROOT / "build/tools/godot-4.4.1/Godot_v4.4.1-stable_linux.x86_64"))
    if not subprocess.check_output([binary, "--version"], text=True).startswith("4.4.1.stable."):
        parser.error("Godot 4.4.1 stable is required")
    parent = ROOT / "build/startup-profiles"
    parent.mkdir(parents=True, exist_ok=True)
    output = Path(tempfile.mkdtemp(prefix=args.entry + "-", dir=parent))
    env = os.environ.copy()
    for key, folder in [("XDG_DATA_HOME", "data"), ("XDG_CONFIG_HOME", "config"), ("XDG_CACHE_HOME", "cache"), ("ERA_PREVIEW_DIR", "screens")]:
        path = output / folder
        path.mkdir()
        env[key] = str(path)
    command = [binary, "--path", str(ROOT / "project"), "--rendering-method", "gl_compatibility", "--script", str(ROOT / "tests/profile_startup.gd")]
    if args.headless:
        command.append("--headless")
    command += ["--", "--mobile-preview", "--startup-profile", "--startup-entry=" + args.entry]
    print("Startup profile: " + str(output), flush=True)
    with (output / "output.log").open("w") as log:
        try:
            result = subprocess.run(command, env=env, stdout=log, stderr=subprocess.STDOUT, timeout=150)
        except subprocess.TimeoutExpired:
            print("FAIL: startup process timed out")
            return 1
    text = (output / "output.log").read_text()
    rows = [json.loads(line.split("|", 1)[1]) for line in text.splitlines() if line.startswith("ERALIFE_STARTUP|")]
    (output / "timings.json").write_text(json.dumps({"headless": args.headless, "entry": args.entry, "stages": rows}, indent=2) + "\n")
    for row in rows:
        print(f"{row['at_ms']:>7} ms  {row['stage']}")
    ok = result.returncode == 0 and "STARTUP PROFILE: PASS" in text and "SCRIPT ERROR:" not in text
    print("PASS" if ok else "FAIL: inspect " + str(output / "output.log"))
    return 0 if ok else 1

if __name__ == "__main__":
    raise SystemExit(main())
