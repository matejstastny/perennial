#!/usr/bin/env python3
import http.server
import os
import platform
import subprocess
import sys
import webbrowser
from pathlib import Path

if platform.system() == "Windows":
    print("Error: deploy.py is not supported on Windows.", file=sys.stderr)
    sys.exit(1)

PORT = 8060
PROJECT_DIR = Path(__file__).parent.parent.resolve()
DIST_DIR = PROJECT_DIR / "dist"

def find_godot():
    if platform.system() == "Darwin":
        return Path("/Applications/Godot.app/Contents/MacOS/Godot")
    return Path("godot")

def find_editor_settings():
    if platform.system() == "Darwin":
        return Path.home() / "Library/Application Support/Godot/editor_settings-4.tres"
    return Path.home() / ".config/godot/editor_settings-4.tres"

def patch_editor_settings(path: Path, src: str, dst: str):
    if not path.exists():
        return
    text = path.read_text(encoding="utf-8")
    if src in text:
        path.write_text(text.replace(src, dst), encoding="utf-8")

def main():
    godot = Path(os.environ["GODOT"]) if os.environ.get("GODOT") else find_godot()
    if not godot.exists():
        print(f"Godot not found at: {godot}", file=sys.stderr)
        sys.exit(1)

    editor_settings = find_editor_settings()

    patch_editor_settings(
        editor_settings,
        "use_external_editor = true",
        "use_external_editor = false",
    )

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
        patch_editor_settings(
            editor_settings,
            "use_external_editor = false",
            "use_external_editor = true",
        )

    print(f"Serving at http://localhost:{PORT}")
    webbrowser.open(f"http://localhost:{PORT}")

    class Handler(http.server.SimpleHTTPRequestHandler):
        def end_headers(self):
            self.send_header("Cross-Origin-Opener-Policy", "same-origin")
            self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
            super().end_headers()

        def log_message(self, format, *args):
            pass  # suppress per-request noise

    os.chdir(DIST_DIR)
    http.server.HTTPServer(("", PORT), Handler).serve_forever()

if __name__ == "__main__":
    main()
