#!/usr/bin/env python3
"""Check script ownership and direct Godot resource links without starting Godot."""

from collections import defaultdict
from pathlib import Path
import re

from code_map import ROOT, index_project, mask_literals

DIRECT_SCRIPT = re.compile(
    r'''\b(?:load|preload)\s*\(\s*["'](res://[^"'\n]+\.(?:gd|scn|tscn))["']'''
)
CONFIG_SCRIPT = re.compile(r'''["']\*?(res://[^"'\n]+\.(?:gd|scn|tscn))["']''')


def main():
    errors = []
    scripts = index_project()
    classes = defaultdict(list)
    uids = defaultdict(list)
    for script in scripts:
        path = ROOT / script.path
        if any(kind == "class_name" for _, kind, _ in script.symbols):
            classes[script.class_name].append(script.path.as_posix())
        if path.name.endswith(".gd.gd"):
            errors.append(f"{script.path}: duplicated .gd extension")
        uid = Path(str(path) + ".uid")
        if uid.exists():
            uids[uid.read_text().strip()].append(script.path.as_posix())
        else:
            errors.append(f"{script.path}: missing .gd.uid; import with Godot 4.4.1 and retain the generated UID")
        source = path.read_text()
        code = mask_literals(source)
        if re.search(r"\bMainScene(?:Helpers|Logic)\b", code):
            errors.append(f"{script.path}: retired catch-all scene helper class")
    for label, owners in [("global class", classes), ("script UID", uids)]:
        for name, paths in owners.items():
            if len(paths) > 1:
                errors.append(f"Duplicate {label} {name}: {', '.join(paths)}")
    if (ROOT / "project/Engine").exists():
        errors.append("project/Engine has been replaced by responsibility-based folders; use the architecture guide")

    checked = 0
    for base in [ROOT / "project", ROOT / "tests"]:
        for path in sorted(base.rglob("*")):
            if not path.is_file() or ".godot" in path.parts:
                continue
            if path.suffix not in (".gd", ".godot", ".tscn", ".tres"):
                continue
            source = path.read_text()
            relative = path.relative_to(ROOT)
            # Historical optional path candidates are not direct loads. Godot's
            # import and runtime tests cover the dynamic lookup side separately.
            code = mask_literals(source) if path.suffix == ".gd" else None
            pattern = DIRECT_SCRIPT if code is not None else CONFIG_SCRIPT
            for match in pattern.finditer(source):
                if code is not None and code[match.start():match.start() + 4].isspace():
                    continue
                resource = match[1]
                target = ROOT / "project" / resource.removeprefix("res://")
                checked += 1
                if not target.is_file():
                    errors.append(f"{relative}: missing direct resource {resource}")
            if "res://Engine/" in source:
                errors.append(f"{relative}: stale resource path into the retired Engine directory")
    for error in errors:
        print(f"FAIL {error}")
    if errors:
        return 1
    print(f"Structure OK: {len(scripts)} scripts, {len(classes)} global classes, {checked} direct resource links.")
    print("Dynamic paths and binary scenes require Godot import/runtime checks.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
