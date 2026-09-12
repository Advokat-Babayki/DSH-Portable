# Changelog

All notable changes to **DSH-Portable** — the portable wrapper that runs
[DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (`dsh`) from
a USB stick — are documented in this file.

Versioning follows [SemVer](https://semver.org/). The version below is the
version of the **wrapper** (build scripts, launchers, packaging). The bundled
`@deepseek-ai/dsh` version is pinned per release and listed with each entry.

## [1.0.0] — 2026-09-13

First stable release. Bundled dsh: **0.1.5-rc.1** (latest on npm at release
time). Verified on a real exFAT USB stick: build → unpack → run.

### Added

- `CHANGELOG.md`, a version badge and a **Changelog** section in both READMEs.
- **Install guide without a build step** — download the bundle from Releases,
  unpack it on the stick, run. This is now the primary path; building from
  source moved into its own developer section.
- FAQ entries: *Windows won't open the file I downloaded* (which archive for
  which OS), *How do I add plugins or my own agent presets*, and *why an exFAT
  stick needs far more space than the archive size*.
- `.gitignore` now ignores the whole live `dsh-home/` — settings, profiles,
  sessions, cache, `.credentials.yaml` and `.agent-presets/`.

### Fixed

Build pipeline:

- `make-portable.sh` did not parse at all (unclosed quote) — the bundle could
  not be built by this script. Fixed; the build runs end to end.
- exFAT: `npm install` aborted with `EPERM` while creating
  `node_modules/.bin` symlinks. The build now uses `--no-bin-links`, which also
  keeps the archive free of symlinks — otherwise it cannot be unpacked on a
  stick.
- Fragile `sed` patching replaced by `patch-js.mjs`: exactly one replacement per
  file, a per-patch marker, a fail-fast if the pattern is missing, and
  `node --check` afterwards. Previously a patch could silently not apply, or
  insert invalid JavaScript.
- Patches were applied *before* `dsh-home` was copied and could be overwritten;
  the order is now: copy → patch → verify.
- `$SCRIPT_DIR` was used before it was defined (and after `cd`), so a normal
  relative invocation copied the launcher into the temporary build tree and the
  build died. Now `$ROOT` is used.
- Missing `rsync`/`zip` no longer kill the build silently; dependency checks and
  messages added.
- `verify_tree` validates the **unpacked archive**: patch markers present, files
  parse, zero symlinks — a bundle that cannot run on exFAT now fails the build
  instead of shipping.
- The credentials patch no longer relies on `require()` inside an ESM bundle.

Launchers and tooling:

- `launch.cmd` did not set `DSH_PORTABLE`, which would have broken startup on an
  exFAT stick under Windows; it also had no Node.js check and an unquoted `echo`
  inside a block. Rewritten (CRLF, ASCII-only, `chcp 65001`, exit code
  forwarded).
- `launch.sh` used bash-only redirection and did not check the bundle; it now
  explains that a source checkout has to be built first.
- `init-portable.sh`: added `--help`, `--no-creds`, a warning that API keys are
  copied in plain text, `rsync` version detection with a fallback, and real
  error reporting instead of `2>/dev/null`.
- `LICENSE` (MIT) added and made a required build input — the README linked to a
  file that did not exist.

### Changed

- `README.md` / `README.ru.md` restructured: **Install** → **Build from source**
  → Usage → Requirements → Updating → Filesystem → What's inside → How it works
  → Security → FAQ → Limitations → Changelog → License.
- Repository layout clarified: the repo holds wrapper sources only. It contains
  no `dsh/node_modules/` and no `dsh-home/` — both are generated.

### Removed

- Personal data from the repository **and its history**: the author's live
  `dsh-home/` (settings, profiles and a private agent preset) is gone from every
  commit.

### Notes

- The bundle ships dsh itself only. No third-party plugins and no agent presets
  are bundled — install your own into `dsh-home/profiles/<profile>/` and
  `dsh-home/.agent-presets/`.
- Recommended filesystems: **exFAT** (default target, no symlinks, no POSIX
  permissions), ext4 for Linux-only use.
- The Windows archive is produced from the same pure-JS dependency tree; it is
  not yet verified on a live Windows machine (the Linux path is verified on real
  hardware).

[1.0.0]: https://github.com/Advokat-Babayki/DSH-Portable/releases/tag/v1.0.0
