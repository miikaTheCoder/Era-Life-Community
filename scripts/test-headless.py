#!/usr/bin/env python3
"""Run the Godot regression scripts with isolated profiles and retained logs."""

import argparse
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
ERROR = re.compile(r"SCRIPT ERROR:|Parse Error:|Failed to load script|^ERROR:", re.MULTILINE)
PASS = re.compile(r"^[^\n]*\bTESTS?: PASS\b|^UI PRESENTATION: PASS$", re.MULTILINE)


def run(binary, arguments, directory, timeout, require_pass=False):
    directory.mkdir(parents=True, exist_ok=True)
    environment = os.environ.copy()
    for variable, folder in [("XDG_DATA_HOME", "data"), ("XDG_CONFIG_HOME", "config"), ("XDG_CACHE_HOME", "cache")]:
        path = directory / folder
        path.mkdir(exist_ok=True)
        environment[variable] = str(path)
    log = directory / "output.log"
    try:
        with log.open("w") as output:
            result = subprocess.run(
                [binary, "--headless", "--path", str(ROOT / "project"), *arguments],
                env=environment, stdout=output, stderr=subprocess.STDOUT, timeout=timeout,
            )
    except subprocess.TimeoutExpired:
        print(f"FAIL {directory.name}: timed out after {timeout}s; {log}", flush=True)
        return False
    content = log.read_text(errors="replace")
    # Resource cleanup warnings occur in the baseline too. Other engine/script
    # errors must fail even when Godot exits with status zero.
    errors = [line for line in content.splitlines() if ERROR.search(line)
              and not re.match(r"^ERROR: \d+ resources still in use at exit", line)]
    passed = result.returncode == 0 and not errors and (not require_pass or PASS.search(content))
    print(f"{'PASS' if passed else 'FAIL'} {directory.name}: {log}", flush=True)
    if not passed:
        print("\n".join(errors[:8]) or content[-2000:], flush=True)
    return bool(passed)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("tests", nargs="*", help="Test stems, e.g. test_narrative; default: all test_*.gd")
    parser.add_argument("--list", action="store_true", help="List available tests without running Godot")
    parser.add_argument("--timeout", type=int, default=180, help="Seconds allowed per test (default: 180)")
    args = parser.parse_args()
    available = {path.stem: path for path in sorted((ROOT / "tests").glob("test_*.gd"))}
    if args.list:
        print("\n".join(available))
        return 0
    unknown = set(args.tests) - available.keys()
    if unknown or args.timeout <= 0:
        parser.error(f"Unknown tests: {', '.join(sorted(unknown))}" if unknown else "--timeout must be positive")
    binary = os.environ.get("GODOT_BIN", str(ROOT / "build/tools/godot-4.4.1/Godot_v4.4.1-stable_linux.x86_64"))
    try:
        version = subprocess.check_output([binary, "--version"], text=True, timeout=10).strip()
    except (OSError, subprocess.SubprocessError) as error:
        parser.error(f"Cannot run Godot: {error}. Run scripts/setup-godot.sh or set GODOT_BIN.")
    if not version.startswith("4.4.1.stable."):
        parser.error(f"Godot 4.4.1 stable required; found {version}")
    logs = ROOT / "build" / "tests"
    logs.mkdir(parents=True, exist_ok=True)
    run_dir = Path(tempfile.mkdtemp(prefix="headless-", dir=logs))
    print(f"Results: {run_dir}", flush=True)
    if not run(binary, ["--import"], run_dir / "import", max(240, args.timeout)):
        return 1
    failed = []
    for name in args.tests or available:
        arguments = ["--script", str(available[name])]
        if name in ("test_mobile", "test_mobile_scroll"):
            arguments += ["--", "--mobile-preview"]
        if not run(binary, arguments, run_dir / name, args.timeout, require_pass=True):
            failed.append(name)
    print(f"{len(failed)} failed / {len(args.tests or available)} tests", flush=True)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
