#!/usr/bin/env python3
"""Set SDK paths in Godot's existing editor settings without booting the game."""
import json
import os
from pathlib import Path
import re

config_dir = Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config")))
settings = config_dir / "godot" / "editor_settings-4.4.tres"
text = settings.read_text()
if not text.startswith('[gd_resource type="EditorSettings"'):
    raise SystemExit(f"Not a Godot 4.4 editor settings resource: {settings}")
for key, value in {
    "export/android/android_sdk_path": os.environ["ANDROID_SDK_ROOT"],
    "export/android/java_sdk_path": os.environ["JAVA_HOME"],
}.items():
    line = f"{key} = {json.dumps(value)}"
    text, count = re.subn(rf"^{re.escape(key)} = .*?$", lambda _: line, text, flags=re.M)
    if count == 0:
        text = text.rstrip() + "\n" + line + "\n"
temporary = settings.with_suffix(".tres.tmp")
temporary.write_text(text)
temporary.replace(settings)
print(f"Android SDK/JDK paths configured in {settings}")
