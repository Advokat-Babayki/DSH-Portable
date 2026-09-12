<div align="center">

# 💾 DSH-Portable

**Portable [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (dsh) — runs straight from a USB drive, no installation.**

[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20Windows-blue.svg)](#-quick-start)
[![Node](https://img.shields.io/badge/node-%E2%89%A5%2018-brightgreen.svg)](#-requirements)
[![dsh](https://img.shields.io/npm/v/@deepseek-ai/dsh?label=dsh&color=orange)](https://www.npmjs.com/package/@deepseek-ai/dsh)

**English** | [Русский](README.ru.md)

*Config, sessions, cache and profiles live next to the launcher — nothing is
written to `~/.dsh` or `~/.config`. Windows and Linux share **one dsh-home**:
switch the OS, keep your sessions.*

</div>

## 📑 Contents

- [Features](#-features)
- [Quick start](#-quick-start)
- [Download](#-download)
- [Usage](#-usage)
- [Requirements](#-requirements)
- [Updating the bundle](#-updating-the-bundle)
- [Choosing a filesystem for the USB drive](#-choosing-a-filesystem-for-the-usb-drive)
- [What's inside](#-whats-inside)
- [How it works](#-how-it-works)
- [Security](#-security)
- [FAQ / Troubleshooting](#-faq--troubleshooting)
- [Limitations](#-limitations)
- [License](#-license)

## ✨ Features

- ⚡ **No installation** — only Node.js must be on the system, everything else lives on the stick
- 🔑 **Your API keys** — stored in `dsh-home/.credentials.yaml` on the stick
- 🧭 **Path-independent** — works from any mount point or drive letter; launcher paths are relative to itself
- 🖥️ **Windows (`launch.cmd`) and Linux (`launch.sh`)** from the same bundle
- 🧩 **Works on exFAT/FAT** — no symlinks, no POSIX permissions, no admin rights
- 🔄 **One dsh-home for both OSes** — sessions and settings follow you across systems

## 🚀 Quick start

```bash
# 1. Build the bundle (needs access to the npm registry)
git clone https://github.com/Advokat-Babayki/DSH-Portable.git
cd DSH-Portable
bash make-portable.sh              # latest @deepseek-ai/dsh
bash make-portable.sh 0.1.0-rc.7   # or a pinned version (reproducible)

# 2. Unpack to the USB drive
tar -xzf release/dsh-portable-linux-x64.tar.gz -C /media/usb/dsh-portable

# 3. Optional: bring your existing ~/.dsh (profiles, settings, sessions)
cd /media/usb/dsh-portable
bash init-portable.sh              # copies keys too; use --no-creds to skip them

# 4. Run
./launch.sh --profile web          # web UI (usually on :3080)
```

**Windows:** double-click `X:\dsh-portable\launch.cmd`.

> 💡 First run creates `dsh-home/profiles/web/` with a default profile.
> If you skipped the keys, add them to `dsh-home/.credentials.yaml`:
> ```yaml
> OPENROUTER_API_KEY: sk-or-v1-...
> ```

## 📦 Download

Pre-built bundles are published on the
[**Releases**](https://github.com/Advokat-Babayki/DSH-Portable/releases) page —
grab `dsh-portable-linux-x64.tar.gz` or `dsh-portable-windows-x64.zip` and
unpack it to the stick. No release available yet? Build it yourself — it's one
command, see [Quick start](#-quick-start).

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
├── README.md
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
- Keys never get into git: `dsh-home/.credentials.yaml` and
  `dsh-home/.agent-presets/` are listed in `.gitignore`.
- Permissions: on FAT/exFAT every file is world-readable and `chmod 600` is
  impossible — that's why portable-mode dsh doesn't require 0600 (see
  [How it works](#-how-it-works)).

## 🛠 FAQ / Troubleshooting

<details>
<summary><b>launch.sh says "dsh/lib/bin.js not found"</b></summary>

You're in a source checkout, not a built bundle. Run `bash make-portable.sh`
and unpack the artifact from `release/` to the stick — see
[Quick start](#-quick-start).

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

## 📄 License

MIT — see [LICENSE](LICENSE).
DeepSeek Harness is distributed under its own license; npm package files
belong to their authors (see `dsh/LICENSE` inside the bundle).

<div align="center">
<sub>Made for carrying your AI cockpit in a pocket 🚀</sub>
</div>
