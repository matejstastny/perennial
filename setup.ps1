# Installs dependencies, fetches godot-cpp, generates bindings, and compiles.
# Run from the repo root in PowerShell:
#   .\setup.ps1           (debug build)
#   .\setup.ps1 -Release  (release build)
#
# Compiler options (first found wins):
#   1. MSVC  -- via "Visual Studio Build Tools" or full Visual Studio
#              https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022
#   2. MinGW -- via MSYS2 (lighter, no Microsoft tooling required)
#              https://www.msys2.org  then: pacman -S mingw-w64-ucrt-x86_64-gcc
#
# VS Code is an editor, not a compiler. You need one of the above to build.
param([switch]$Release)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Target   = if ($Release) { "template_release" } else { "template_debug" }
$RepoRoot = $PSScriptRoot
$ExtDir   = Join-Path $RepoRoot "extension"

function Step($msg) { Write-Host ""; Write-Host ">> $msg" -ForegroundColor Cyan }
function Ok($msg)   { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Die($msg)  { Write-Host ""; Write-Host "[ERROR] $msg" -ForegroundColor Red; exit 1 }

# -- Python / SCons -----------------------------------------------------------

Step "Checking Python"
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Die "Python not found.  Install from https://python.org (check 'Add to PATH')."
}
Ok "Python $((python --version 2>&1) -replace 'Python ','')"

Step "Checking SCons"
if (-not (Get-Command scons -ErrorAction SilentlyContinue)) {
    Write-Host "  -> Installing SCons..."
    python -m pip install scons
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","User") + ";" + $env:PATH
}
Ok "scons"

# -- Compiler detection -------------------------------------------------------
# VS Code is an editor only -- it does not ship a C++ compiler.
# We support two compiler toolchains:
#   MSVC  (Visual Studio Build Tools or full Visual Studio)
#   MinGW (MSYS2 + mingw-w64 gcc -- no Microsoft tooling required)

Step "Detecting C++ compiler"

$UseMingw  = $false
$DevShell  = $null

# Check for MSVC via vswhere (finds both Build Tools and full VS installs)
$vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vsWhere) {
    $vsPath   = & $vsWhere -latest -property installationPath
    $DevShell = Join-Path $vsPath "Common7\Tools\VsDevCmd.bat"
    Ok "MSVC found at $vsPath"
}
# Fall back to MinGW/GCC (installed via MSYS2 or standalone)
elseif (Get-Command g++ -ErrorAction SilentlyContinue) {
    $UseMingw = $true
    Ok "MinGW g++ found at $((Get-Command g++).Source)"
}
else {
    Write-Host ""
    Write-Host "  No C++ compiler found.  Install one of:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Option A -- Visual Studio Build Tools (MSVC, ~6 GB):" -ForegroundColor White
    Write-Host "    https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022"
    Write-Host "    Select 'Desktop development with C++' workload."
    Write-Host ""
    Write-Host "  Option B -- MSYS2 + MinGW (GCC, ~2 GB, no Microsoft account needed):" -ForegroundColor White
    Write-Host "    1. Install MSYS2: https://www.msys2.org"
    Write-Host "    2. In the MSYS2 terminal run:"
    Write-Host "         pacman -S mingw-w64-ucrt-x86_64-gcc"
    Write-Host "    3. Add C:\msys64\ucrt64\bin to your PATH."
    Die "Re-run this script after installing a compiler."
}

# -- godot-cpp submodule ------------------------------------------------------

Step "godot-cpp submodule  (branch: 4.2)"

$gitModules = Join-Path $RepoRoot ".gitmodules"
$alreadyRegistered = (Test-Path $gitModules) -and (Select-String -Path $gitModules -Pattern "godot-cpp" -Quiet)

if (-not $alreadyRegistered) {
    Write-Host "  -> Registering submodule..."
    git -C $RepoRoot submodule add -b 4.2 `
        https://github.com/godotengine/godot-cpp extension/godot-cpp
}

Write-Host "  -> Fetching / updating..."
git -C $RepoRoot submodule update --init --recursive
Ok "godot-cpp ready"

# -- VS Code IntelliSense config ----------------------------------------------

Step "VS Code IntelliSense config"

$vscodeDir = Join-Path $RepoRoot ".vscode"
New-Item -ItemType Directory -Force -Path $vscodeDir | Out-Null

$intelliSenseMode = if ($UseMingw) { "windows-gcc-x64" } else { "windows-msvc-x64" }

$propsPath = Join-Path $vscodeDir "c_cpp_properties.json"
@"
{
    "configurations": [
        {
            "name": "GDExtension",
            "includePath": [
                "`${workspaceFolder}/extension/godot-cpp/include",
                "`${workspaceFolder}/extension/godot-cpp/gen/include",
                "`${workspaceFolder}/extension/godot-cpp/gdextension",
                "`${workspaceFolder}/extension/src"
            ],
            "defines": [ "_WIN32" ],
            "cppStandard": "c++17",
            "intelliSenseMode": "$intelliSenseMode"
        }
    ],
    "version": 4
}
"@ | Set-Content -Path $propsPath -Encoding UTF8
Ok ".vscode/c_cpp_properties.json written"

# -- Helper: run scons (wraps in VS dev shell for MSVC, plain for MinGW) ------

function Invoke-Scons($args) {
    if ($UseMingw) {
        $cmd = "scons $args use_mingw=yes"
        Invoke-Expression $cmd
    } else {
        cmd /c "`"$DevShell`" && scons $args"
    }
    if ($LASTEXITCODE -ne 0) { Die "scons failed: $args" }
}

# -- Generate bindings (creates gen/include -- needed for VS Code) ------------

Step "Generating C++ bindings"
Set-Location $ExtDir

Invoke-Scons "platform=windows target=$Target generate_bindings=yes --directory=`"$ExtDir\godot-cpp`""
Ok "gen/include headers written"

# -- Full build ---------------------------------------------------------------

Step "Compiling extension  (platform=windows  target=$Target)"
Invoke-Scons "platform=windows target=$Target"
Ok "Built -> bin\libperennial.windows.$Target.x86_64.dll"

# -- Reload VS Code -----------------------------------------------------------

Step "Reloading VS Code IntelliSense"
if (Get-Command code -ErrorAction SilentlyContinue) {
    code --command workbench.action.reloadWindow 2>$null
    if ($LASTEXITCODE -eq 0) {
        Ok "VS Code window reloaded"
    } else {
        Write-Host "  -> Press Ctrl+Shift+P -> 'Reload Window' in VS Code" -ForegroundColor Yellow
    }
} else {
    Write-Host "  -> Press Ctrl+Shift+P -> 'Reload Window' in VS Code" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "------------------------------------------------------------" -ForegroundColor Green
Write-Host "  Open Godot 4.2 -- GameWorld is ready to use."
Write-Host "------------------------------------------------------------" -ForegroundColor Green
