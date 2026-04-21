Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

param(
  [string]$OutputDir = "dist/windows-installer",
  [string]$Version = "0.1.0"
)

$RepoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
$BuildRoot = Join-Path $RepoRoot "tmp/winbrew-installer"
$PayloadDir = Join-Path $BuildRoot "payload"
$DepsDir = Join-Path $PayloadDir "deps"
$BrewDir = Join-Path $PayloadDir "winbrew"

$GitInstallerName = "Git-2.49.0-64-bit.exe"
$RubyInstallerName = "rubyinstaller-devkit-3.4.4-2-x64.exe"
$PythonInstallerName = "python-3.12.10-amd64.exe"

$GitUrl = "https://github.com/git-for-windows/git/releases/download/v2.49.0.windows.1/$GitInstallerName"
$RubyUrl = "https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-3.4.4-2/$RubyInstallerName"
$PythonUrl = "https://www.python.org/ftp/python/3.12.10/$PythonInstallerName"

Write-Host "Preparing Windows installer build workspace..."
if (Test-Path $BuildRoot) {
  Remove-Item $BuildRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $DepsDir -Force | Out-Null
New-Item -ItemType Directory -Path $BrewDir -Force | Out-Null
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

function Download-Dependency {
  param(
    [string]$Url,
    [string]$Destination
  )

  Write-Host "Downloading $Url"
  Invoke-WebRequest -Uri $Url -OutFile $Destination
}

Download-Dependency -Url $GitUrl -Destination (Join-Path $DepsDir $GitInstallerName)
Download-Dependency -Url $RubyUrl -Destination (Join-Path $DepsDir $RubyInstallerName)
Download-Dependency -Url $PythonUrl -Destination (Join-Path $DepsDir $PythonInstallerName)

Write-Host "Copying WinBrew sources into payload..."
$Excluded = @(".git", "tmp", "dist")
Get-ChildItem -Path $RepoRoot -Force | Where-Object {
  $Excluded -notcontains $_.Name
} | ForEach-Object {
  Copy-Item $_.FullName -Destination $BrewDir -Recurse -Force
}

$InnoScript = Join-Path $RepoRoot "package/windows/winbrew-installer.iss"
$InstallerPath = Join-Path (Resolve-Path $OutputDir).Path ("WinBrew-{0}-Setup.exe" -f $Version)

Write-Host "Building installer with Inno Setup..."
$Iscc = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
if (-not (Test-Path $Iscc)) {
  throw "ISCC.exe not found. Install Inno Setup 6 before running this script."
}

& $Iscc   "/DWinBrewVersion=$Version"   "/DRepoRoot=$RepoRoot"   "/DPayloadDir=$PayloadDir"   "/DOutputDir=$OutputDir"   $InnoScript

if (-not (Test-Path $InstallerPath)) {
  throw "Installer was not generated at expected path: $InstallerPath"
}

Write-Host "Installer generated: $InstallerPath"
