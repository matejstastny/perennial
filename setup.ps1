# Installs dependencies, fetches godot-cpp, generates bindings, and compiles.
# Run from the repo root in PowerShell:
#   .\setup.ps1           (debug build)
#   .\setup.ps1 -Release  (release build)
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

# -- Visual Studio (MSVC) -----------------------------------------------------

Step "Checking Visual Studio"
$vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"

if (-not (Test-Path $vsWhere)) {
    Write-Host ""
    Write-Host "  Visual Studio not found." -ForegroundColor Yellow
    Write-Host "  Install VS 2019 or 2022 with the 'Desktop development with C++' workload:"
    Write-Host "  https://visualstudio.microsoft.com/downloads/" -ForegroundColor DarkCyan
    Die "Re-run this script after installing Visual Studio."
}

$vsPath = & $vsWhere -latest -property installationPath
Ok "Visual Studio at $vsPath"

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
            "intelliSenseMode": "windows-msvc-x64"
        }
    ],
    "version": 4
}
"@ | Set-Content -Path $propsPath -Encoding UTF8
Ok ".vscode/c_cpp_properties.json written"

# -- Generate bindings (creates gen/include -- needed for VS Code) ------------

Step "Generating C++ bindings"

$devShell = Join-Path $vsPath "Common7\Tools\VsDevCmd.bat"
Set-Location $ExtDir

$genCmd = "scons platform=windows target=$Target generate_bindings=yes --directory=`"$ExtDir\godot-cpp`""
cmd /c "`"$devShell`" && $genCmd"
if ($LASTEXITCODE -ne 0) { Die "Binding generation failed." }
Ok "gen/include headers written"

# -- Full build ---------------------------------------------------------------

Step "Compiling extension  (platform=windows  target=$Target)"

$buildCmd = "scons platform=windows target=$Target"
cmd /c "`"$devShell`" && $buildCmd"
if ($LASTEXITCODE -ne 0) { Die "Compilation failed." }

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
    Write-Host "  -> 'code' not in PATH -- press Ctrl+Shift+P -> 'Reload Window' in VS Code" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "------------------------------------------------------------" -ForegroundColor Green
Write-Host "  [OK] Built -> bin\libperennial.windows.$Target.x86_64.dll"
Write-Host "  Open Godot 4.2 -- GameWorld is ready to use."
Write-Host "------------------------------------------------------------" -ForegroundColor Green
