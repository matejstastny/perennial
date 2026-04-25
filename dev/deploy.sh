#!/bin/bash
set -e

GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$PROJECT_DIR/dist"
PORT=8060
EDITOR_SETTINGS=~/Library/Application\ Support/Godot/editor_settings-4.tres

# Disable Godot's external editor during export so it doesn't open VS Code on warnings
sed -i '' 's/use_external_editor = true/use_external_editor = false/' "$EDITOR_SETTINGS"
trap 'sed -i "" "s/use_external_editor = false/use_external_editor = true/" "$EDITOR_SETTINGS"' EXIT

echo "Exporting project..."
"$GODOT" --headless --path "$PROJECT_DIR" --export-release "Web App" "$DIST_DIR/perennial.html"

# Restore immediately after export (trap also covers crash/abort)
sed -i '' 's/use_external_editor = false/use_external_editor = true/' "$EDITOR_SETTINGS"
trap - EXIT

echo "Serving at http://localhost:$PORT/perennial.html"
open "http://localhost:$PORT/perennial.html"

python3 - <<EOF
import http.server, os

class Handler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        super().end_headers()

os.chdir("$DIST_DIR")
http.server.HTTPServer(("", $PORT), Handler).serve_forever()
EOF
