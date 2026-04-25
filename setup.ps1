# Installs dependencies, fetches godot-cpp, generates bindings, and compiles.
# Run from the repo root in PowerShell:
#   .\setup.ps1           (debug build)
#   .\setup.ps1 -Release  (release build)
#
# VS Code is an editor, not a compiler. This script auto-installs one for you.
param([switch]$Release)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Target   = if ($Release) { "template_release" } else { "template_debug" }
$RepoRoot = $PSScriptRoot
$ExtDir   = Join-Path $RepoRoot "extension"

function Step($msg) { Write-Host ""; Write-Host ">> $msg" -ForegroundColor Cyan }
function Ok($msg)   { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "  [!!] $msg" -ForegroundColor Yellow }
function Die($msg)  { Write-Host ""; Write-Host "[ERROR] $msg" -ForegroundColor Red; exit 1 }

function Test-Admin {
    ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# -- Python / SCons -----------------------------------------------------------

Step "Checking Python"
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    # winget can install Python silently
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "  -> Installing Python via winget..."
        winget install --id Python.Python.3 --accept-package-agreements --accept-source-agreements
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" +
                    [System.Environment]::GetEnvironmentVariable("PATH","User")   + ";" + $env:PATH
    } else {
        Die "Python not found and winget is unavailable.`n  Install Python from https://python.org (check 'Add to PATH')."
    }
}
Ok "Python $((python --version 2>&1) -replace 'Python ','')"

Step "Checking SCons"
# Resolve scons by asking Python where it puts scripts -- avoids PATH issues
# with packages installed mid-session (pip drops executables into Scripts\ but
# that folder isn't on PATH until a new shell starts).
$PyScripts = python -c "import sysconfig; print(sysconfig.get_path('scripts'))"
$SconsExe  = Join-Path $PyScripts "scons.exe"

if (-not (Test-Path $SconsExe)) {
    Write-Host "  -> Installing SCons..."
    python -m pip install --quiet scons
}

if (-not (Test-Path $SconsExe)) {
    Die "scons.exe not found at $SconsExe after install. Check your Python installation."
}

$SconsCmd = "`"$SconsExe`""
Ok "scons at $SconsExe"

# -- Compiler detection & auto-install ----------------------------------------
# Priority:
#   1. MSVC already present  (Visual Studio or Build Tools)
#   2. MinGW already present (g++ on PATH)
#   3. MSYS2 installed but gcc missing -> install gcc via pacman (no admin needed)
#   4. winget available -> install MSYS2 + gcc (no admin needed)
#   5. winget available -> install VS Build Tools  (needs admin, prompted)
#   6. Give up with clear instructions

Step "Detecting C++ compiler"

$UseMingw = $false
$DevShell = $null
$vsWhere  = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$Msys2Bash = "C:\msys64\usr\bin\bash.exe"
$Msys2Gcc  = "C:\msys64\ucrt64\bin"

function Find-MSVC {
    if (Test-Path $vsWhere) {
        $path = & $vsWhere -latest -property installationPath 2>$null
        if ($path) { return $path }
    }
    return $null
}

function Install-MinGW-ViaPacman {
    Write-Host "  -> Installing MinGW gcc via pacman (no admin required)..."
    & $Msys2Bash -lc "pacman -S --noconfirm mingw-w64-ucrt-x86_64-gcc" 2>&1 | Write-Host
    $env:PATH = "$Msys2Gcc;$env:PATH"
}

function Install-MSYS2-ViaWinget {
    Write-Host "  -> Installing MSYS2 via winget..."
    winget install --id MSYS2.MSYS2 --accept-package-agreements --accept-source-agreements
    if (-not (Test-Path $Msys2Bash)) {
        Die "MSYS2 installed but not found at C:\msys64. Re-run this script."
    }
}

function Install-BuildTools-ViaWinget {
    if (-not (Test-Admin)) {
        Warn "Build Tools installation requires admin rights."
        Write-Host "  -> Relaunching script as administrator..."
        Start-Process powershell `
            -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`" $(if ($Release) { '-Release' })" `
            -Verb RunAs
        exit 0
    }
    Write-Host "  -> Installing Visual Studio Build Tools via winget (this takes ~5 min)..."
    winget install --id Microsoft.VisualStudio.2022.BuildTools `
        --override "--quiet --wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended" `
        --accept-package-agreements --accept-source-agreements
}

# 1. MSVC already present?
$vsPath = Find-MSVC
if ($vsPath) {
    $DevShell = Join-Path $vsPath "Common7\Tools\VsDevCmd.bat"
    Ok "MSVC found at $vsPath"
}
# 2. MinGW already on PATH?
elseif (Get-Command g++ -ErrorAction SilentlyContinue) {
    $UseMingw = $true
    Ok "MinGW g++ found at $((Get-Command g++).Source)"
}
# 3. MSYS2 installed but gcc not on PATH yet?
elseif (Test-Path $Msys2Bash) {
    Install-MinGW-ViaPacman
    if (Get-Command g++ -ErrorAction SilentlyContinue) {
        $UseMingw = $true
        Ok "MinGW gcc installed"
    } else {
        Die "pacman ran but g++ still not found. Add $Msys2Gcc to your PATH and re-run."
    }
}
# 4 & 5. Nothing found -- try winget
elseif (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host ""
    Write-Host "  No C++ compiler found. Installing automatically via winget..." -ForegroundColor Yellow
    Write-Host "  Trying MSYS2 + MinGW first (no admin needed)..." -ForegroundColor White

    try {
        Install-MSYS2-ViaWinget
        Install-MinGW-ViaPacman
        if (Get-Command g++ -ErrorAction SilentlyContinue) {
            $UseMingw = $true
            Ok "MinGW gcc installed via MSYS2"
        } else {
            throw "g++ not found after MSYS2 install"
        }
    } catch {
        Warn "MSYS2 install failed ($_). Falling back to VS Build Tools (needs admin)..."
        Install-BuildTools-ViaWinget
        # Refresh vswhere after install
        $vsPath = Find-MSVC
        if ($vsPath) {
            $DevShell = Join-Path $vsPath "Common7\Tools\VsDevCmd.bat"
            Ok "MSVC Build Tools installed"
        } else {
            Die "Build Tools installed but vswhere still can't find them. Please restart and re-run."
        }
    }
}
# 6. No winget, no compiler -- print instructions and exit
else {
    Write-Host ""
    Write-Host "  No C++ compiler or winget found." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Option A -- Visual Studio Build Tools (MSVC, ~6 GB):" -ForegroundColor White
    Write-Host "    https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022"
    Write-Host "    Select the 'Desktop development with C++' workload."
    Write-Host ""
    Write-Host "  Option B -- MSYS2 + MinGW (GCC, ~2 GB, no Microsoft account needed):" -ForegroundColor White
    Write-Host "    1. https://www.msys2.org"
    Write-Host "    2. In the MSYS2 terminal: pacman -S mingw-w64-ucrt-x86_64-gcc"
    Write-Host "    3. Add C:\msys64\ucrt64\bin to your PATH."
    Die "Re-run this script after installing a compiler."
}

# -- godot-cpp submodule ------------------------------------------------------

Step "godot-cpp submodule  (branch: 4.5)"

$gitModules = Join-Path $RepoRoot ".gitmodules"
$alreadyRegistered = (Test-Path $gitModules) -and (Select-String -Path $gitModules -Pattern "godot-cpp" -Quiet)

if (-not $alreadyRegistered) {
    Write-Host "  -> Registering submodule..."
    git -C $RepoRoot submodule add -b 4.5 `
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

# -- Helper: run scons --------------------------------------------------------

function Invoke-Scons($sconsArgs) {
    if ($UseMingw) {
        # python -m scons avoids relying on scons being on PATH
        Invoke-Expression "$SconsCmd $sconsArgs use_mingw=yes"
    } else {
        cmd /c "`"$DevShell`" && $SconsCmd $sconsArgs"
    }
    if ($LASTEXITCODE -ne 0) { Die "scons failed: $sconsArgs" }
}

# -- Generate bindings --------------------------------------------------------

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
