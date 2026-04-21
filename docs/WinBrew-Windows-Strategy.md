# WinBrew Windows-First Strategy

This document defines how WinBrew evolves from a Homebrew fork into a Windows-first package manager while still being able to ingest upstream improvements from `homebrew/brew`.

## Goals

1. Make Windows the default and primary supported platform for WinBrew.
2. Keep Unix-like command behavior through a bundled Bash runtime (Git-for-Windows style).
3. Prevent accidental pushes to `homebrew/brew`.
4. Keep a predictable upstream-sync cadence with low merge pain.
5. Preserve optional compatibility tracks for macOS/Linux builds during migration.

## Non-goals

- Building a full one-to-one clone of Homebrew behavior on day one.
- Maintaining long-term parity for every macOS/Linux-only capability.
- Requiring PowerShell rewrites of all existing shell logic.

## Branch model

WinBrew uses purpose-specific long-lived branches:

- `main`: stable Windows releases.
- `preview`: prerelease branch for integration testing before promotion to `main`.
- `bash`: Bash runtime bundling, launcher, and path translation work.
- `web`: docs/website/content publishing changes.
- `compat`: shared compatibility adaptations for non-Windows build/test scenarios.
- `compatlinux`: Linux-specific compatibility maintenance.

### Promotion flow

1. Feature branches merge into their domain branch (`bash`, `web`, etc.) or directly into `preview`.
2. `preview` receives regular upstream sync and cross-branch integration.
3. `main` only receives tested releases from `preview`.

## Remote policy (safety rail)

- `upstream` points to `https://github.com/homebrew/brew.git` (read/fetch source).
- `origin` points to the WinBrew fork (all pushes).
- Local automation must fail fast if `origin` resolves to `homebrew/brew`.

Recommended local setup:

```bash
git remote add upstream https://github.com/homebrew/brew.git
git remote set-url origin git@github.com:<your-org>/winbrew.git
```

## Upstream sync strategy

- Sync cadence: daily or every 48 hours.
- Target branch: `preview` first, then fast-forward/merge into `main` after validation.
- Conflict policy:
  - resolve conflicts in platform abstraction layers first,
  - avoid invasive rewrites in shared logic unless required,
  - track recurring conflict hotspots and extract adapters.

### Suggested sync sequence

```bash
git fetch upstream
git checkout preview
git merge --no-edit upstream/master
# run checks
# open PR preview -> main when stable
```

## Windows runtime strategy (Git-for-Windows approach)

WinBrew keeps Unix-like script behavior by shipping or standardizing on a Bash runtime:

- runtime root convention: `%ProgramData%\\WinBrew\\bash` (or configurable path),
- expected executable: `<runtime_root>/bin/bash.exe`,
- wrapper launchers normalize Windows paths into POSIX paths,
- process execution defaults to bundled Bash for scripts that assume Unix semantics.

## Platform architecture

### Rule 1: prefer capability checks over OS-name checks

Replace checks that hardcode macOS/Linux assumptions with capabilities such as:

- symlink support,
- executable bit behavior,
- case sensitivity,
- available shell/runtime,
- package extraction and linker behavior.

### Rule 2: isolate platform behavior

Keep platform-specific logic in adapters and avoid spreading conditionals across commands.

### Rule 3: degrade clearly

When unsupported behavior is encountered, produce explicit guidance and next-step remediation.

## CI and quality gates

Minimum CI gates for `preview` and `main`:

1. Windows unit tests for critical commands (`update`, `install`, `upgrade`, `doctor`).
2. Lint/style/type checks.
3. Upstream-sync smoke test validating merge and launcher boot.

Compatibility branches (`compat`, `compatlinux`) may run reduced suites as transitional tracks.

## Migration plan

### Phase 1: Foundation (now)

- finalize branch policy and safety rails,
- establish bundled Bash conventions,
- add upstream-sync automation,
- publish contributor docs.

### Phase 2: Core command readiness

- implement Windows-first adapters,
- make high-frequency commands reliable,
- enforce Windows CI for release gates.

### Phase 3: Default Windows posture

- remove remaining hard macOS/Linux assumptions from WinBrew defaults,
- keep compatibility branches for controlled non-Windows support,
- formalize deprecation policy for unsupported legacy behavior.

## Contributor workflow

1. Branch from `preview` for Windows/core changes.
2. Keep diffs small and isolate platform abstractions.
3. Rebase/merge from `preview` frequently to reduce sync conflicts.
4. Open PRs to `preview`; release PRs go `preview` -> `main`.

## Release policy

- `main` is stable and tagged.
- `preview` is prerelease and may include upstream-integration changes.
- Emergency fixes may cherry-pick from `main` into `preview` to keep branches aligned.

## Open decisions

- Exact bundled Bash distribution and update cadence.
- Minimum supported Windows versions and shells.
- Whether `compatlinux` remains long-term or is eventually retired.

## Windows installer pipeline

WinBrew provides a dedicated GitHub Actions workflow at
`.github/workflows/winbrew-windows-installer.yml` to build a Windows installer.

The build script (`package/windows/build-installer.ps1`) currently:

1. Downloads pinned installers for Git for Windows, RubyInstaller+Devkit, and Python.
2. Copies the WinBrew repository into the installer payload.
3. Invokes Inno Setup with `package/windows/winbrew-installer.iss`.
4. Produces `WinBrew-<version>-Setup.exe` as a workflow artifact.

Installer behavior:

- installs Git, Ruby, and Python in silent mode,
- installs WinBrew into `Program Files\WinBrew\brew`,
- sets `WINBREW_BASH_ROOT` to `C:\Program Files\Git`.

Future hardening items:

- checksum/signature verification for downloaded installers,
- bundled/offline dependency mode,
- signed installer output and release publishing.
