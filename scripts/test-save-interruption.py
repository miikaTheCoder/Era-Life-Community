#!/usr/bin/env python3
"""Exercise real save-write failures with POSIX file limits in disposable profiles.

Run scripts/test-headless.py first to import the project. No normal saves are used.
"""
import os
from pathlib import Path
import signal
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    if os.name != "posix":
        raise SystemExit("POSIX file limits required; run on Linux or macOS")
    import resource

    binary = os.environ.get("GODOT_BIN", str(ROOT / "build/tools/godot-4.4.1/Godot_v4.4.1-stable_linux.x86_64"))
    version = subprocess.check_output([binary, "--version"], text=True, timeout=10)
    if not version.startswith("4.4.1.stable."):
        raise SystemExit("Godot 4.4.1 stable required")
    evidence = ROOT / "build/tests"
    evidence.mkdir(parents=True, exist_ok=True)
    run = Path(tempfile.mkdtemp(prefix="save-interruption-", dir=evidence))
    print(f"Evidence: {run}", flush=True)
    failures = []
    for extension in ("bin", "json"):
        for mode in ("interrupt", "write-error"):
            case = run / f"{extension}-{mode}"
            case.mkdir()
            env = os.environ.copy()
            for key in ("XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"):
                folder = case / key.lower()
                folder.mkdir()
                env[key] = str(folder)
            saved = case / f"life.{extension}"
            command = [binary, "--headless", "--path", str(ROOT / "project"),
                       "--script", str(ROOT / "tests/test_atomic_save.gd"), "--"]
            seeded = subprocess.run(command + ["--seed-path", str(saved)], env=env,
                                    capture_output=True, text=True, timeout=120)
            (case / "seed.log").write_text(seeded.stdout + seeded.stderr)
            if seeded.returncode != 0 or not saved.is_file():
                raise RuntimeError(f"Could not create valid prior save: {case}")
            previous = saved.read_bytes()

            def limit_write():
                resource.setrlimit(resource.RLIMIT_CORE, (0, 0))
                resource.setrlimit(resource.RLIMIT_FSIZE, (65536, 65536))
                signal.signal(signal.SIGXFSZ, signal.SIG_DFL if mode == "interrupt" else signal.SIG_IGN)

            result = subprocess.run(
                command + ["--fault-path", str(saved)],
                env=env, preexec_fn=limit_write, stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT, text=True, timeout=120,
            )
            (case / "output.log").write_text(result.stdout)
            unchanged = saved.read_bytes() == previous
            expected_exit = result.returncode == -signal.SIGXFSZ if mode == "interrupt" else result.returncode == 0 and "SAVE FAILURE REPORT: PASS" in result.stdout
            cleaned = mode == "interrupt" or list(case.glob("life.*")) == [saved]
            restored = subprocess.run(command + ["--verify-path", str(saved)], env=env,
                                      capture_output=True, text=True, timeout=120)
            (case / "restore.log").write_text(restored.stdout + restored.stderr)
            passed = unchanged and expected_exit and cleaned and restored.returncode == 0
            print(f"{'PASS' if passed else 'FAIL'} {case.name}: previous_save_preserved={unchanged}, exit={result.returncode}, cleanup={cleaned}", flush=True)
            if not passed:
                failures.append(case.name)
    return bool(failures)


if __name__ == "__main__":
    raise SystemExit(main())
