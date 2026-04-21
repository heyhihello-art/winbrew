# WinBrew Windows Installer

This directory contains the Windows packaging pipeline for WinBrew.

## Components

- `build-installer.ps1`: downloads prerequisite installers (Git, Ruby, Python), stages the WinBrew repository payload, and calls Inno Setup.
- `winbrew-installer.iss`: Inno Setup recipe that installs prerequisites and deploys WinBrew.

## Local build

```powershell
choco install innosetup -y
./package/windows/build-installer.ps1 -Version "0.1.0-local" -OutputDir "dist/windows-installer"
```

## CI build

The GitHub Actions workflow `.github/workflows/winbrew-windows-installer.yml` runs the same script and uploads the generated `.exe` installer artifact.

## Notes

- Installer URLs are version-pinned in `build-installer.ps1`.
- The current implementation is online-only and downloads installers at build time.
- Add checksum/signature verification before production releases.
