#!/usr/bin/env python3
"""Web export + local server for Perennial. Works on macOS and Windows."""

import http.server
import os
import platform
import shutil
import subprocess
import sys
import webbrowser
from pathlib import Path

PORT = 8060
PROJECT_DIR = Path(__file__).resolve().parent
DIST_DIR = PROJECT_DIR / "dist"


def find_godot() -> Path:
    # Honour explicit override first
    if os.environ.get("GODOT"):
        return Path(os.environ["GODOT"])

    if platform.system() == "Darwin":
        return Path("/Applications/Godot.app/Contents/MacOS/Godot")

    if platform.system() == "Windows":
        candidates = [
            Path(os.environ.get("LOCALAPPDATA", "")) / "Programs" / "Godot" / "Godot.exe",
            Path("C:/Godot/Godot.exe"),
            Path("C:/Program Files/Godot/Godot.exe"),
        ]
        for p in candidates:
            if p.exists():
                return p
        # Fall back to PATH
        found = shutil.which("godot") or shutil.which("Godot")
        if found:
            return Path(found)

    # Linux / fallback
    found = shutil.which("godot")
    if found:
        return Path(found)
    return Path("godot")


def find_editor_settings() -> Path:
    if platform.system() == "Darwin":
        return Path.home() / "Library/Application Support/Godot/editor_settings-4.tres"
    if platform.system() == "Windows":
        appdata = os.environ.get("APPDATA", "")
        return Path(appdata) / "Godot" / "editor_settings-4.tres"
    return Path.home() / ".config/godot/editor_settings-4.tres"


def patch_editor_settings(path: Path, src: str, dst: str) -> None:
    if not path.exists():
        return
    text = path.read_text(encoding="utf-8")
    if src in text:
        path.write_text(text.replace(src, dst), encoding="utf-8")


def main() -> None:
    godot = find_godot()
    if not godot.exists():
        print(
            f"Godot not found at: {godot}\n"
            "Set the GODOT environment variable to its path, e.g.:\n"
            "  macOS/Linux: export GODOT=/path/to/Godot\n"
            "  Windows:     set GODOT=C:\\path\\to\\Godot.exe",
            file=sys.stderr,
        )
        sys.exit(1)

    editor_settings = find_editor_settings()
    patch_editor_settings(editor_settings, "use_external_editor = true", "use_external_editor = false")

    if DIST_DIR.exists():
        shutil.rmtree(DIST_DIR)
    DIST_DIR.mkdir(parents=True, exist_ok=True)

    try:
        print("Exporting project...")
        subprocess.run(
            [
                str(godot),
                "--headless",
                "--path", str(PROJECT_DIR),
                "--export-release", "web",
                str(DIST_DIR / "index.html"),
            ],
            check=True,
        )
    finally:
        patch_editor_settings(editor_settings, "use_external_editor = false", "use_external_editor = true")

    print(f"Serving at http://localhost:{PORT}")
    webbrowser.open(f"http://localhost:{PORT}")

    class Handler(http.server.SimpleHTTPRequestHandler):
        def end_headers(self) -> None:
            # Required for SharedArrayBuffer (Godot web export)
            self.send_header("Cross-Origin-Opener-Policy", "same-origin")
            self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
            super().end_headers()

        def log_message(self, format: str, *args) -> None:
            pass  # suppress per-request noise

    os.chdir(DIST_DIR)
    http.server.HTTPServer(("", PORT), Handler).serve_forever()


if __name__ == "__main__":
    main()
