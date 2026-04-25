#!/usr/bin/env bash
# Installs dependencies, fetches godot-cpp, generates bindings, and compiles.
# Usage: ./setup.sh [--release]
set -euo pipefail

TARGET="template_debug"
[[ "${1:-}" == "--release" ]] && TARGET="template_release"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXT_DIR="$REPO_ROOT/extension"
GODOT_CPP_DIR="$EXT_DIR/godot-cpp"

# ── helpers ───────────────────────────────────────────────────────────────────

ok()   { echo "  ✓ $*"; }
step() { echo ""; echo "▶ $*"; }
die()  { echo ""; echo "✗ $*" >&2; exit 1; }

install_scons_macos() {
  if command -v scons &>/dev/null; then
    ok "scons $(scons --version 2>&1 | head -1 | awk '{print $NF}')"; return
  fi
  step "Installing SCons"
  # brew avoids the PEP 668 "externally managed environment" error
  if command -v brew &>/dev/null; then
    brew install scons
  # pipx also avoids PEP 668 by using an isolated venv
  elif command -v pipx &>/dev/null; then
    pipx install scons
  # explicit opt-out of PEP 668, last resort
  elif command -v pip3 &>/dev/null; then
    pip3 install --break-system-packages scons
  else
    die "No package manager found. Install Homebrew (https://brew.sh) then re-run."
  fi
  ok "scons installed"
}

install_scons_linux() {
  if command -v scons &>/dev/null; then
    ok "scons $(scons --version 2>&1 | head -1 | awk '{print $NF}')"; return
  fi
  step "Installing SCons"
  # system package manager first — avoids PEP 668 on Ubuntu 23+, Fedora 38+
  if   command -v apt-get &>/dev/null; then sudo apt-get install -y scons
  elif command -v dnf     &>/dev/null; then sudo dnf install -y scons
  elif command -v pacman  &>/dev/null; then sudo pacman -Sy --noconfirm scons
  elif command -v zypper  &>/dev/null; then sudo zypper install -y scons
  elif command -v pipx    &>/dev/null; then pipx install scons
  elif command -v pip3    &>/dev/null; then pip3 install --user scons
  else die "Could not install SCons — install it manually: https://scons.org"
  fi
  ok "scons installed"
}

# ── platform setup ────────────────────────────────────────────────────────────

OS="$(uname -s)"

case "$OS" in
Darwin)
  step "macOS — checking dependencies"
  if ! xcode-select -p &>/dev/null; then
    echo "  → Installing Xcode command line tools (follow the prompt)..."
    xcode-select --install
    die "Re-run this script after the Xcode CLI tools finish installing."
  fi
  ok "Xcode CLI tools"
  install_scons_macos
  SCONS_PLATFORM="macos"
  ;;

Linux)
  step "Linux — installing build dependencies"
  if   command -v apt-get &>/dev/null; then sudo apt-get update -qq && sudo apt-get install -y build-essential pkg-config
  elif command -v dnf     &>/dev/null; then sudo dnf install -y gcc-c++ make pkgconfig
  elif command -v pacman  &>/dev/null; then sudo pacman -Sy --noconfirm base-devel
  elif command -v zypper  &>/dev/null; then sudo zypper install -y gcc-c++ make
  else echo "  ⚠ Unknown package manager — ensure g++ is installed."
  fi
  ok "build tools"
  install_scons_linux
  SCONS_PLATFORM="linux"
  ;;

*)
  die "Unsupported OS: $OS — use setup.ps1 on Windows."
  ;;
esac

# ── godot-cpp submodule ───────────────────────────────────────────────────────

step "godot-cpp submodule  (branch: 4.2)"

if ! grep -qs "godot-cpp" "$REPO_ROOT/.gitmodules" 2>/dev/null; then
  echo "  → Registering submodule..."
  # note: the branch is '4.2', not 'godot-4.2'
  git -C "$REPO_ROOT" submodule add -b 4.2 \
    https://github.com/godotengine/godot-cpp extension/godot-cpp
fi

echo "  → Fetching content..."
# --init handles first-time clones; --recursive pulls godot-cpp's own deps
git -C "$REPO_ROOT" submodule update --init --recursive
ok "godot-cpp ready"

# ── generate bindings (creates gen/include — needed for VS Code) ──────────────

step "Generating C++ bindings  (this is what creates the .hpp files VS Code needs)"
cd "$EXT_DIR"
# 'generate_bindings' is a scons alias that runs only the Python binding
# generator without compiling any C++ — fast, no compiler required.
scons platform="$SCONS_PLATFORM" target="$TARGET" generate_bindings=yes \
  --directory="$GODOT_CPP_DIR"
ok "gen/include headers written"

# ── VS Code IntelliSense config ───────────────────────────────────────────────

step "VS Code IntelliSense config"

VSCODE_DIR="$REPO_ROOT/.vscode"
mkdir -p "$VSCODE_DIR"

cat >"$VSCODE_DIR/c_cpp_properties.json" <<JSON
{
    "configurations": [
        {
            "name": "GDExtension",
            "includePath": [
                "\${workspaceFolder}/extension/godot-cpp/include",
                "\${workspaceFolder}/extension/godot-cpp/gen/include",
                "\${workspaceFolder}/extension/godot-cpp/gdextension",
                "\${workspaceFolder}/extension/src"
            ],
            "defines": [],
            "cppStandard": "c++17",
            "intelliSenseMode": "\${default}"
        }
    ],
    "version": 4
}
JSON
ok ".vscode/c_cpp_properties.json written"

# ── full build ────────────────────────────────────────────────────────────────

step "Compiling extension  (platform=$SCONS_PLATFORM  target=$TARGET)"
scons platform="$SCONS_PLATFORM" target="$TARGET" \
  -j"$(nproc 2>/dev/null || sysctl -n hw.logicalcpu 2>/dev/null || echo 4)"

# ── reload VS Code ───────────────────────────────────────────────────────────

step "Reloading VS Code IntelliSense"
if command -v code &>/dev/null; then
  # --command sends workbench commands to the running VS Code instance
  if code --command workbench.action.reloadWindow 2>/dev/null; then
    ok "VS Code window reloaded"
  else
    echo "  ↳ Press Cmd+Shift+P → 'Reload Window' in VS Code"
  fi
else
  echo "  ↳ 'code' not in PATH — press Cmd+Shift+P → 'Reload Window' in VS Code"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✓ Built → bin/libperennial.$SCONS_PLATFORM.$TARGET.*"
echo "  Open Godot 4.2 — GameWorld is ready to use."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
