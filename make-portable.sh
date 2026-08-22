#!/usr/bin/env bash
# Собирает переносимый бандл dsh (DeepSeek Harness) для Linux.
#
# Usage:
#   bash make-portable.sh [VERSION] [DSH_HOME_SOURCE]
#
# VERSION — версия @deepseek-ai/dsh (например 0.1.0-rc.7). Если не указана — берётся последняя.
# DSH_HOME_SOURCE — путь к существующему ~/.dsh для копирования профилей и ключей.
#                   Если не указан — создаётся минимальная заглушка.
#
# Результат: release/dsh-portable-linux-x64.tar.gz
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
VER="${1:-}"
DSH_SOURCE="${2:-}"
NPM_PKG="@deepseek-ai/dsh"
DL="$(mktemp -d)"
OUT="$ROOT/release"

rm -rf "$OUT"
mkdir -p "$OUT"
trap 'rm -rf "$DL"' EXIT

# ── resolve version ────────────────────────────────────────────────────────
if [ -z "$VER" ]; then
  echo "== Resolving latest version from npm =="
  VER="$(npm view "$NPM_PKG" version 2>/dev/null)"
fi
echo "== dsh $VER =="

# ── download ───────────────────────────────────────────────────────────────
echo "== Downloading $NPM_PKG@$VER and dependencies =="
mkdir -p "$DL/build"
cd "$DL/build"
npm init -y >/dev/null 2>&1
npm install "$NPM_PKG@$VER" --no-optional --ignore-scripts --no-audit --no-fund 2>&1 | tail -5

echo "== Assembling bundle =="

make_bundle() {
  local dir="$1" launcher="$2"
  mkdir -p "$dir/dsh" "$dir/dsh-home/profiles" "$dir/bin"

  # ── copy dsh installation (the CLI app itself) ──────────────
  cp -a "$DL/build/node_modules/$NPM_PKG/" "$dir/dsh/"

  # ── copy entire node_modules flat tree ───────────────────────
  # On exFAT we can't create symlinks, so profiles need the full
  # dependency tree available via Node resolution.
  cp -a "$DL/build/node_modules/." "$dir/dsh/node_modules/"
  rm -rf "$dir/dsh/node_modules/@deepseek-ai/dsh" 2>/dev/null || true

  # ── copy the same node_modules to profiles fallback ──────────
  # Required because profile packages (like dsh-base, dsh-web-app)
  # are imported from the profile directory context, and Node ESM
  # won't walk up to dsh/node_modules.
  rsync -a "$DL/build/node_modules/" "$dir/dsh-home/profiles/node_modules/" 2>/dev/null
  rm -rf "$dir/dsh-home/profiles/node_modules/@deepseek-ai/dsh" 2>/dev/null || true

  # ── apply patches for exFAT compatibility ────────────────────
  # 1. ensureSymlink: allow regular directories (exFAT no symlinks)
  patch_ensure_symlink "$dir/dsh/node_modules/@deepseek-ai/dsh-app-boot/lib/index.js"
  patch_ensure_symlink "$dir/dsh-home/profiles/node_modules/@deepseek-ai/dsh-app-boot/lib/index.js"

  # 2. dsh-credentials-local: skip owner-only check on exFAT
  patch_credentials "$dir/dsh/node_modules/@deepseek-ai/dsh-credentials-local/lib/index.js"
  patch_credentials "$dir/dsh-home/profiles/node_modules/@deepseek-ai/dsh-credentials-local/lib/index.js"

  # ── launcher ─────────────────────────────────────────────────
  cp "$SCRIPT_DIR/launch.$launcher" "$dir/launch.$launcher"
  chmod +x "$dir/launch.$launcher" 2>/dev/null || true

  # ── README & LICENSE ─────────────────────────────────────────
  cp "$ROOT/LICENSE" "$dir/LICENSE" 2>/dev/null || true
  cp "$ROOT/README.md" "$dir/README.md" 2>/dev/null || true

  # ── dsh-home from source ──────────────────────────────────────
  if [ -n "$DSH_SOURCE" ] && [ -d "$DSH_SOURCE" ]; then
    echo "  Copying dsh-home from $DSH_SOURCE..."
    rsync -a --no-links "$DSH_SOURCE/" "$dir/dsh-home/" 2>/dev/null || true
  fi

  # always ensure dirs exist
  mkdir -p "$dir/dsh-home/cache" "$dir/dsh-home/logs" "$dir/dsh-home/storages"
  mkdir -p "$dir/dsh-home/sessions"

  echo "  Bundle prepared: $dir"
}

# ── patch helpers ──────────────────────────────────────────────────────────

patch_ensure_symlink() {
  local f="$1"
  if [ ! -f "$f" ]; then return; fi
  if grep -q "portable/read-only filesystem" "$f" 2>/dev/null; then return; fi
  sed -i 's/if (!stat.isSymbolicLink()) throw new Error.*/if (!stat.isSymbolicLink()) {\n\t\t\t\/\* portable \*\/ if (stat.isDirectory()) return;\n\t\t\tthrow new Error(...);\n\t\t}/' "$f"
  # more precise patch
  sed -i 's/if (!stat.isSymbolicLink()) throw new Error(`dsh: ${link} exists and is not a symlink; remove it so dsh can manage the installation fallback`);/if (!stat.isSymbolicLink()) { if (stat.isDirectory()) return; throw new Error(`dsh: ${link} exists and is not a symlink; remove it so dsh can manage the installation fallback`); }/' "$f"
  # allow EPERM/ENOTSUP on symlink
  sed -i 's|if (error.code !== "EEXIST"|if (error.code === "EPERM" || error.code === "ENOTSUP" || error.code === "EROFS") return;\n\t\tif (error.code !== "EEXIST"|' "$f"
}

patch_credentials() {
  local f="$1"
  if [ ! -f "$f" ]; then return; fi
  if grep -q "DSH_PORTABLE" "$f" 2>/dev/null; then return; fi
  sed -i 's|if ((mode \& GROUP_OTHER_BITS) === 0) return;|if ((mode \& GROUP_OTHER_BITS) === 0) return;\n\t\ttry { require("fs").chmodSync(filename, 0o600); return; } catch {}\n\t\tif (process.env.DSH_PORTABLE) return;|' "$f"
}

# ── build ──────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "== Building Linux bundle =="
make_bundle "$DL/dsh-portable" sh
( cd "$DL/dsh-portable" && tar -czf "$OUT/dsh-portable-linux-x64.tar.gz" . )
echo "  -> $OUT/dsh-portable-linux-x64.tar.gz"

# Windows (optional, requires zip)
if command -v zip &>/dev/null; then
  echo "== Building Windows bundle =="
  make_bundle "$DL/dsh-portable-win" cmd
  ( cd "$DL/dsh-portable-win" && zip -qr "$OUT/dsh-portable-windows-x64.zip" . )
  echo "  -> $OUT/dsh-portable-windows-x64.zip"
else
  echo "  zip not found — skipping Windows bundle"
fi

echo ""
echo "== Done =="
ls -lh "$OUT/"
echo ""
echo "To initialize dsh-home from your current ~/.dsh, run:"
echo "  bash init-portable.sh