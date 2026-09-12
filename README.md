<div align="center">

# 💾 DSH-Portable

**Portable [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (dsh) — runs straight from a USB drive, no installation.**

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](CHANGELOG.md)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20Windows-blue.svg)](#-install-no-build-required)
[![Node](https://img.shields.io/badge/node-%E2%89%A5%2018-brightgreen.svg)](#-requirements)
[![dsh](https://img.shields.io/npm/v/@deepseek-ai/dsh?label=dsh&color=orange)](https://www.npmjs.com/package/@deepseek-ai/dsh)

**English** | [Русский](README.ru.md)

*Config, sessions, cache and profiles live next to the launcher — nothing is
written to `~/.dsh` or `~/.config`. Windows and Linux share **one dsh-home**:
switch the OS, keep your sessions.*

</div>

## 📑 Contents

- [Features](#-features)
- [Install (no build)](#-install-no-build-required)
- [Build from source](#-build-from-source-developers)
- [Usage](#-usage)
- [Requirements](#-requirements)
- [Updating the bundle](#-updating-the-bundle)
- [Choosing a filesystem for the USB drive](#-choosing-a-filesystem-for-the-usb-drive)
- [What's inside](#-whats-inside)
- [How it works](#-how-it-works)
- [Security](#-security)
- [FAQ / Troubleshooting](#-faq--troubleshooting)
- [Limitations](#-limitations)
- [Changelog](#-changelog)
- [License](#-license)

## ✨ Features

- ⚡ **No installation** — only Node.js must be on the system, everything else lives on the stick
- 🔑 **Your API keys** — stored in `dsh-home/.credentials.yaml` on the stick
- 🧭 **Path-independent** — works from any mount point or drive letter; launcher paths are relative to itself
- 🖥️ **Windows (`launch.cmd`) and Linux (`launch.sh`)** from the same bundle
- 🧩 **Works on exFAT/FAT** — no symlinks, no POSIX permissions, no admin rights
- 🔄 **One dsh-home for both OSes** — sessions and settings follow you across systems
- 📦 **Plain dsh, nothing personal** — the bundle ships dsh itself: no third-party plugins, no preinstalled agent presets

## 🚀 Install (no build required)

**You need:** a USB stick, and [Node.js ≥ 18](https://nodejs.org) installed on the
computer you plug it into. Nothing else — no admin rights, no installer.

**1. Download the bundle** from
[**Releases**](https://github.com/Advokat-Babayki/DSH-Portable/releases/latest):

| Your OS | File to take |
|---|---|
| Windows | `dsh-portable-windows-x64.zip` |
| Linux / macOS | `dsh-portable-linux-x64.tar.gz` |

**2. Unpack it onto the stick** — any folder, any drive letter, e.g. `D:\dsh-portable\`:

```bash
# Linux / macOS
tar -xzf dsh-portable-linux-x64.tar.gz -C /media/usb/dsh-portable
```

*Windows:* take the `.zip` and extract it with Explorer (right-click →
**Extract All**). If you downloaded the `.tar.gz` instead, Windows 10+ can
unpack it in PowerShell with `tar -xzf dsh-portable-linux-x64.tar.gz -C
D:\dsh-portable` — or use [7-Zip](https://7-zip.org).

**3. Run it:**

```
Windows:        D:\dsh-portable\launch.cmd          (double-click)
Linux / macOS:  cd /media/usb/dsh-portable && ./launch.sh --profile web
```

**4. Add your API key** on the first run — `dsh-home/.credentials.yaml`:

```yaml
OPENROUTER_API_KEY: sk-or-v1-...
```

Nothing is installed into the system: sessions, settings and keys live in
`dsh-home/` on the stick, and `~/.dsh` is never touched. The same stick works on
Windows and Linux — both OSes share one `dsh-home/`.

> 🧩 **The bundle ships dsh itself and nothing personal** — no third-party
> plugins, no preinstalled agent presets. Plugins go into
> `dsh-home/profiles/<profile>/`, agent presets into
> `dsh-home/.agent-presets/` — install your own whenever you need them.

**Already running dsh on this computer?** One command brings your setup to the
stick — profiles, settings, sessions and (optionally) API keys:

```bash
cd /media/usb/dsh-portable
bash init-portable.sh              # copies keys too; --no-creds to skip them
```

## 🛠 Build from source (developers)

Build a bundle yourself from the npm registry (needs `node`, `npm`, `tar` and
network access; about 15 minutes and ~1 GB of free space):

```bash
git clone https://github.com/Advokat-Babayki/DSH-Portable.git
cd DSH-Portable
bash make-portable.sh              # latest @deepseek-ai/dsh
bash make-portable.sh 0.1.5-rc.1   # or a pinned version (reproducible)

# artifacts land in release/
#   dsh-portable-linux-x64.tar.gz  (always built)
#   dsh-portable-windows-x64.zip   (built too when `zip` is in PATH)
```

Then unpack the archive to the stick exactly as in
[step 2](#-install-no-build-required). Pin the dsh version: a "latest" build
silently gets old over time.

## 🖥️ Usage

**Linux:**

```bash
./launch.sh --profile web                # web interface (usually on :3080)
./launch.sh --profile headless "prompt"  # one-shot query in the console
./launch.sh --dump-config --profile web  # inspect the configuration
```

**Windows:**

```
X:\dsh-portable\launch.cmd
```

Both launchers set `DSH_HOME` to the `dsh-home` folder next to them and
`DSH_PORTABLE=true` (a signal for the patched dsh — see
[How it works](#-how-it-works)).

## 🧰 Requirements

| Where | What you need |
|---|---|
| Any run | **Node.js ≥ 18** in `PATH` (not included in the bundle) |
| Linux run | `bash`, `tar` |
| `init-portable.sh` | `rsync` (only when copying an existing `~/.dsh`) |
| Build | `node`, `npm`, `tar`, access to the npm registry |
| Windows bundle build | `zip` in `PATH` (the step is skipped with a message otherwise) |

## 🔄 Updating the bundle

Your data — sessions, settings, API keys — lives in `dsh-home/` and is **not**
touched by replacing the app:

```bash
# 0. Prudent: back up dsh-home/ (sessions, .credentials.yaml, settings.yaml)

# 1. Build the new bundle (pin the version for reproducibility)
bash make-portable.sh 0.1.5-rc.1

# 2. Unpack it to a temp folder
tar -xzf release/dsh-portable-linux-x64.tar.gz -C /tmp/dsh-new

# 3. On the stick: keep dsh-home, replace the app and the launchers
rm -rf /media/usb/dsh-portable/dsh
cp -a /tmp/dsh-new/dsh /media/usb/dsh-portable/dsh
cp /tmp/dsh-new/launch.* /media/usb/dsh-portable/
```

Notes:

- `make-portable.sh` wipes `release/` on every build — don't keep anything
  valuable there.
- You can also carry settings into a fresh bundle in one step:
  `bash make-portable.sh 0.1.5-rc.1 /path/to/.dsh`.
- Bundles are built from the npm version you pass; a "latest" build silently
  gets old over time — pin versions for reproducibility.

## 💽 Choosing a filesystem for the USB drive

| Filesystem | Symlinks | POSIX perms | Verdict |
|---|:---:|:---:|---|
| **exFAT** | ❌ | ❌ | ✅ **Recommended** — the bundle is designed for it; readable on Windows, Linux and macOS |
| **FAT32** | ❌ | ❌ | ⚠️ Works, but a 4 GB per-file cap can bite with long sessions or caches |
| **NTFS** | via driver | emulated | ⚠️ Fine for a Windows-only stick; on Linux (ntfs-3g) permission mapping is quirky |
| **ext4** | ✅ | ✅ | ✅ Best for Linux-only use; Windows can't read it natively |

Why exFAT is the default choice: it has no symlinks and no permission bits at
all, and the bundle is explicitly patched for that (see below). The flip side:
every file on the stick is readable by anyone holding it — including
`.credentials.yaml` (see [Security](#-security)).

## 📂 What's inside

The **repository** (what git holds) is the wrapper sources, not a ready bundle:

```
dsh-portable/
├── launch.sh            # Linux launcher
├── launch.cmd           # Windows launcher
├── make-portable.sh     # build the bundle from npm → release/
├── init-portable.sh     # copy ~/.dsh into dsh-home/
├── patch-js.mjs         # precise JS patches for exFAT (used by the build)
├── README.md            # ← you are here
├── README.ru.md         # Russian version
├── CHANGELOG.md         # release history
└── LICENSE
```

The **built bundle** (`release/dsh-portable-linux-x64.tar.gz` or
`release/dsh-portable-windows-x64.zip`) is what gets unpacked to the stick:

<details>
<summary>Click to expand the bundle layout</summary>

```
dsh-portable/
├── dsh/                     # @deepseek-ai/dsh and its dependencies (npm tree)
│   ├── lib/bin.js           # dsh entry point
│   └── node_modules/        # flat dependencies (patched for exFAT)
├── dsh-home/                # DSH_HOME — all dsh data
│   ├── settings.yaml        # providers and model settings
│   ├── .credentials.yaml    # API keys
│   ├── profiles/            # profiles (web, tui...)
│   │   └── node_modules/    # second copy of the dep tree (needed without symlinks)
│   ├── sessions/            # sessions
│   └── cache/ logs/ storages/
├── launch.sh                # Linux
├── launch.cmd               # Windows
├── README.md                # + README.ru.md
├── CHANGELOG.md
└── LICENSE
```

</details>

The repo deliberately contains no `dsh/node_modules/` and no `dsh-home/`
(see `.gitignore`): that's a hundreds-of-megabytes npm tree which
`make-portable.sh` always rebuilds. **Running `./launch.sh` from a fresh
checkout is therefore meaningless** — the launcher will tell you so and hint
what to do.

## ⚙️ How it works

```
launch.sh / launch.cmd
  ├─ DSH_HOME = <folder>/dsh-home   ← all data stays on the stick
  ├─ DSH_PORTABLE = true            ← signal for the patched dsh
  └─ node dsh/lib/bin.js "$@"       ← dsh reads $DSH_HOME, never touches ~/.dsh
```

Without `DSH_HOME` dsh would use `~/.dsh` — the launcher overrides that.

The build applies **three precise patches** to the dependency tree
(`patch-js.mjs` — exactly one replacement per file, otherwise the build fails):

<details>
<summary>Patch details</summary>

| File | What changes | Why |
|---|---|---|
| `@deepseek-ai/dsh-app-boot` | `ensureSymlink`: a real directory instead of a symlink is fine, not an error | in the bundle `node_modules` are real directories; exFAT has no symlinks |
| `@deepseek-ai/dsh-app-boot` | `symlinkSync` failing with `EPERM`/`ENOTSUP`/`EROFS` doesn't crash startup | FAT/exFAT can't create symlinks |
| `@deepseek-ai/dsh-credentials-local` | with `DSH_PORTABLE=true` the 0600 permission check is skipped | FAT/exFAT doesn't store permissions |

</details>

Patches are applied to **both** copies of the tree (`dsh/node_modules` and
`dsh-home/profiles/node_modules`) and verified after the build: marker presence
plus `node --check` on the unpacked archive.

## 🔐 Security

- `dsh-home/.credentials.yaml` is a **plain-text file with API keys**, not
  encrypted. Anyone with access to the stick can read it. `init-portable.sh`
  warns about this and can skip the keys: `bash init-portable.sh --no-creds`.
- Keys never get into git: the whole live home (`dsh-home/` — settings,
  profiles, sessions, `.credentials.yaml` and `.agent-presets/`) is ignored, and
  the repository contains no user data of its own.
- Never commit your `dsh-home/`: it is your data, not a source file. `git add -A`
  from a stick is safe — `.gitignore` covers the whole folder.
- Permissions: on FAT/exFAT every file is world-readable and `chmod 600` is
  impossible — that's why portable-mode dsh doesn't require 0600 (see
  [How it works](#-how-it-works)).

## 🛠 FAQ / Troubleshooting

<details>
<summary><b>launch.sh says "dsh/lib/bin.js not found"</b></summary>

You're in a source checkout, not a built bundle. Run `bash make-portable.sh`
and unpack the artifact from `release/` to the stick — see
[Build from source](#-build-from-source-developers).

</details>

<details>
<summary><b>Windows won't open the file I downloaded</b></summary>

Take the artifact that matches your OS: `-windows-x64.zip` for Windows,
`-linux-x64.tar.gz` for Linux/macOS. Each archive contains the launcher for its
own OS only. `.tar.gz` is not a Windows format — Windows 10+ can still unpack it
in PowerShell (`tar -xzf dsh-portable-linux-x64.tar.gz -C D:\dsh-portable`) or
with [7-Zip](https://7-zip.org), but that archive has no `launch.cmd`.

</details>

<details>
<summary><b>How do I add plugins or my own agent presets?</b></summary>

They are not bundled — on purpose. `dsh-home/` starts empty and belongs to you:
add plugins to a profile under `dsh-home/profiles/<profile>/`, drop agent presets
into `dsh-home/.agent-presets/`, and keep your own skills and settings there.
Everything you add stays on the stick, and `dsh-home/` is ignored by git, so
nothing leaks into the repository by accident.

</details>

<details>
<summary><b>The archive is 80 MB, but the unpacked folder is huge</b></summary>

That is normal for FAT/exFAT: those filesystems allocate storage in clusters, so
~57 000 small files (the dependency tree, stored twice) occupy several gigabytes
even though their real size is ~370 MB. A stick of 16 GB or more is comfortable;
NTFS/ext4 use space more efficiently if your workflow allows them.

</details>

<details>
<summary><b>"node not found in PATH"</b></summary>

Install Node.js ≥ 18 (from [nodejs.org](https://nodejs.org) or your package
manager). The bundle intentionally ships without Node.

</details>

<details>
<summary><b>tar prints "Cannot change ownership/permissions" while unpacking</b></summary>

Harmless on FAT/exFAT — these filesystems don't store POSIX permissions.
The files are extracted fine.

</details>

<details>
<summary><b>Where do my sessions and settings live?</b></summary>

In `dsh-home/` next to the launcher: `sessions/`, `settings.yaml`,
`.credentials.yaml`. Windows and Linux use the same folder, so sessions
survive an OS switch.

</details>

<details>
<summary><b>Why does the bundle contain two copies of node_modules? It's huge.</b></summary>

Deliberate: Node ESM doesn't walk up from the profile directory to
`dsh/node_modules`, and symlinks don't exist on exFAT. Doubling the tree is the
price for running without admin rights and without touching the filesystem —
see [Limitations](#-limitations).

</details>

<details>
<summary><b>The build failed with "pattern not found" / "шаблон не найден"</b></summary>

A new dsh version changed the code the patch expects, and the build refuses to
ship a silently unpatched bundle. Pin the previous dsh version
(`bash make-portable.sh 0.1.0-rc.7`) or wait for a DSH-Portable update.

</details>

<details>
<summary><b>Does anything get written outside the stick?</b></summary>

No. `DSH_HOME` points inside `dsh-home/`, so sessions, cache and logs all stay
on the stick. `~/.dsh` and `~/.config` are never touched.

</details>

## ⚠️ Limitations

- **Size**: the dependency tree is stored twice in the bundle
  (`dsh/node_modules` and `dsh-home/profiles/node_modules`) because Node ESM
  doesn't walk up from the profile into `dsh/node_modules` and there are no
  symlinks on exFAT. The price for no-admin, no-filesystem-hacks operation.
- **Windows bundle** is built on Linux: dsh has no native addons, but
  platform-dependent (native) dependencies would not get into such a bundle —
  `npm install` runs with `--no-optional --ignore-scripts`.
- dsh ≥ 0.1.5 changed the internal `ensureSymlink` code; the build handles
  both variants, but on the next template change it will fail with diagnostics
  instead of silently building a broken bundle.
- No hardlinks on exFAT: dsh tools that create files via `link(2)` (some
  atomic-write paths) may get `EPERM`. Launchers and the build never do that;
  if you hit it — use ext4.
- **No hardcoded version**: a bundle built from "latest" gets old over time;
  pin the version explicitly for reproducibility.

## 📝 Changelog

**1.0.0** — first stable release. Build, launchers and packaging are verified on a
real exFAT stick (build, unpack, run). Highlights:

- `make-portable.sh` actually works end to end (previously the script did not
  even parse) and validates every patch it applies.
- Built for FAT/exFAT: no symlinks, no POSIX permissions, no admin rights —
  `npm install --no-bin-links` and three precise patches to the dependency tree.
- `launch.sh` / `launch.cmd` set `DSH_HOME` and `DSH_PORTABLE`, check Node.js and
  the bundle, and explain what to do when something is missing.
- The repository no longer carries any user data: the live `dsh-home/`
  (settings, profiles, sessions, keys, personal agent presets) is ignored
  entirely.

Full history in [CHANGELOG.md](CHANGELOG.md) and in the
[commit log](https://github.com/Advokat-Babayki/DSH-Portable/commits/main).

## 📄 License

MIT — see [LICENSE](LICENSE).
DeepSeek Harness is distributed under its own license; npm package files
belong to their authors (see `dsh/LICENSE` inside the bundle).

<div align="center">
<sub>Made for carrying your AI cockpit in a pocket 🚀</sub>
</div>
