#!/usr/bin/env bash
# Собирает переносимый бандл dsh (DeepSeek Harness).
#
# Usage:
#   bash make-portable.sh [VERSION] [DSH_HOME_SOURCE]
#
# VERSION — версия @deepseek-ai/dsh (например 0.1.0-rc.7). Если не указана — берётся последняя.
# DSH_HOME_SOURCE — путь к существующему ~/.dsh для копирования профилей и ключей.
#                   Если не указан — создаётся минимальная заглушка.
#
# Требуется: node, npm, tar.
#   rsync — только если задан DSH_HOME_SOURCE
#   zip   — только для Windows-бандла (иначе он пропускается)
#
# Результат в release/:
#   dsh-portable-linux-x64.tar.gz
#   dsh-portable-windows-x64.zip   (если найден zip)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
VER="${1:-}"
DSH_SOURCE="${2:-}"
NPM_PKG="@deepseek-ai/dsh"
DL="$(mktemp -d)"
OUT="$ROOT/release"
PATCHER="$ROOT/patch-js.mjs"
# Маркеры идемпотентности — по одному на каждый патч (в одном файле их несколько).
MARK_DIR='dsh-portable: каталог вместо симлинка'
MARK_EPERM='dsh-portable: симлинки недоступны'
MARK_CREDS='dsh-portable: FAT/exFAT не хранит права 0600'

APP_BOOT="@deepseek-ai/dsh-app-boot/lib/index.js"
CREDS="@deepseek-ai/dsh-credentials-local/lib/index.js"

die() { echo "Ошибка: $*" >&2; exit 1; }

# ── зависимости ────────────────────────────────────────────────────────────
for tool in node npm tar; do
  command -v "$tool" >/dev/null 2>&1 || die "не найден $tool в PATH"
done
[ -f "$PATCHER" ] || die "не найден $PATCHER (нужен для патчей бандла)"
if [ -n "$DSH_SOURCE" ]; then
  command -v rsync >/dev/null 2>&1 || die "для копирования DSH_HOME_SOURCE нужен rsync"
fi

trap 'rm -rf "$DL"' EXIT

# ── resolve version ────────────────────────────────────────────────────────
if [ -z "$VER" ]; then
  echo "== Определяю последнюю версию $NPM_PKG =="
  if ! VER="$(npm view "$NPM_PKG" version 2>&1)"; then
    echo "$VER" >&2
    die "не удалось узнать версию $NPM_PKG (нет доступа к npm registry?). Укажи версию явно: bash make-portable.sh 0.1.0-rc.7"
  fi
  VER="$(printf '%s' "$VER" | tr -d '[:space:]')"
fi
[ -n "$VER" ] || die "пустая версия $NPM_PKG"
echo "== dsh $VER =="

# ── download ───────────────────────────────────────────────────────────────
echo "== Скачиваю $NPM_PKG@$VER и зависимости =="
mkdir -p "$DL/build"
cd "$DL/build"
npm init -y >/dev/null 2>&1
# --no-bin-links: npm создаёт node_modules/.bin/* симлинками, а FAT/exFAT их не
# умеет (EPERM) — установка падала бы прямо на этом. .bin бандлу не нужен:
# лаунчеры запускают node dsh/lib/bin.js напрямую. Бонусом в архиве не остаётся
# симлинков, иначе он не распаковался бы на флешке.
if ! npm install "$NPM_PKG@$VER" --no-optional --ignore-scripts --no-audit --no-fund --no-bin-links; then
  die "npm install $NPM_PKG@$VER не удался"
fi
for rel in "$APP_BOOT" "$CREDS"; do
  [ -f "$DL/build/node_modules/$rel" ] || die "в дереве $NPM_PKG@$VER нет $rel — патчить нечего"
done

# ── patch helpers ──────────────────────────────────────────────────────────

# Точная замена подстроки в JS-файле бандла.
# patch-js.mjs сам проверяет, что шаблон найден ровно один раз, и падает, если нет.
# В replacement последовательности \n и \t разворачиваются в перевод строки и таб.
# marker — строка-признак именно этого патча (в одном файле патчей несколько,
# поэтому общий маркер на файл не годится: он бы пропустил второй патч).
patch_js() {
  local f="$1" needle="$2" repl="$3" what="$4" marker="${5:-}"
  [ -n "$marker" ] || die "внутренняя ошибка: вызов patch_js без маркера ($what)"
  [ -f "$f" ] || die "$what: файл не найден: $f"
  if grep -qF "$marker" "$f"; then
    echo "   ok $what: уже пропатчен"
  else
    node "$PATCHER" "$f" "$needle" "$repl" "$what" || die "$what: патч не применён ($f)"
  fi
  grep -qF "$marker" "$f" || die "$what: маркер патча не появился в $f"
  node --check "$f" || die "$what: файл не парсится после патча ($f)"
}

# Патчи для exFAT/FAT: в портативном бандле node_modules — настоящие каталоги,
# симлинки и права 0600 недоступны.
patch_portable() {
  local base="$1"
  local boot="$base/$APP_BOOT"
  local creds="$base/$CREDS"

  # 1a. ensureSymlink: реальный каталог вместо симлинка — это норма для бандла.
  #     Набор строк зависит от версии dsh-app-boot.
  if grep -qF 'if (!stat.isSymbolicLink()) throw new Error(`dsh: ${link} exists and is not a symlink;' "$boot"; then
    # dsh-app-boot <= 0.1.0-rc.7
    patch_js "$boot" \
      'if (!stat.isSymbolicLink()) throw new Error(`dsh: ${link} exists and is not a symlink; remove it so dsh can manage the installation fallback`);' \
      'if (!stat.isSymbolicLink()) { /* dsh-portable: каталог вместо симлинка */ if (stat.isDirectory()) return; throw new Error(`dsh: ${link} exists and is not a symlink; remove it so dsh can manage the installation fallback`); }' \
      "app-boot ensureSymlink (каталог вместо симлинка)" "$MARK_DIR"
  else
    # dsh-app-boot >= 0.1.5-rc.1
    patch_js "$boot" \
      'if ((stat.isDirectory() ? readModuleProxyRecord(link) : void 0)?.dsh?.moduleFallback?.targets === void 0) throw new Error(`dsh: ${link} exists and is not a symlink or dsh-managed module proxy; remove it so dsh can manage the installation fallback`);' \
      'if ((stat.isDirectory() ? readModuleProxyRecord(link) : void 0)?.dsh?.moduleFallback?.targets === void 0) { /* dsh-portable: каталог вместо симлинка */ if (process.env.DSH_PORTABLE === "true" && stat.isDirectory()) return; throw new Error(`dsh: ${link} exists and is not a symlink or dsh-managed module proxy; remove it so dsh can manage the installation fallback`); }' \
      "app-boot ensureSymlink (каталог вместо симлинка)" "$MARK_DIR"
  fi

  # 1b. symlinkSync: FAT/exFAT не умеют симлинки — EPERM/ENOTSUP не должен валить старт.
  patch_js "$boot" \
    'if (error.code !== "EEXIST"' \
    'if (error.code === "EPERM" || error.code === "EACCES" || error.code === "ENOTSUP" || error.code === "ENOSYS" || error.code === "EROFS") return; /* dsh-portable: симлинки недоступны */\n\t\tif (error.code !== "EEXIST"' \
    "app-boot symlinkSync (EPERM/ENOTSUP)" "$MARK_EPERM"

  # 2. credentials-local: права 0600 на FAT/exFAT не существуют — в портативном
  #    режиме не требуем их (сам файл всё равно остаётся открытым, см. README).
  patch_js "$creds" \
    'if ((mode & GROUP_OTHER_BITS) === 0) return;' \
    'if (process.env.DSH_PORTABLE === "true") return; /* dsh-portable: FAT/exFAT не хранит права 0600 */\n\tif ((mode & GROUP_OTHER_BITS) === 0) return;' \
    "credentials-local owner-only" "$MARK_CREDS"
}

# Проверка, что патчи реально на месте и файлы парсятся.
verify_tree() {
  local root="$1" f
  for f in "$root/dsh/node_modules/$APP_BOOT" "$root/dsh-home/profiles/node_modules/$APP_BOOT"; do
    [ -f "$f" ] || die "в бандле нет $f"
    grep -qF "$MARK_DIR" "$f" || die "патч ensureSymlink не применён: $f"
    grep -qF "$MARK_EPERM" "$f" || die "патч symlinkSync (EPERM) не применён: $f"
    node --check "$f" || die "файл не парсится: $f"
  done
  for f in "$root/dsh/node_modules/$CREDS" "$root/dsh-home/profiles/node_modules/$CREDS"; do
    [ -f "$f" ] || die "в бандле нет $f"
    grep -qF "$MARK_CREDS" "$f" || die "патч credentials-local не применён: $f"
    node --check "$f" || die "файл не парсится: $f"
  done
  # Симлинки в бандле: на FAT/exFAT симлинк создать нельзя, архив с ними
  # не распакуется на флешке (tar падает с EPERM).
  local links
  links="$(find "$root" -type l | wc -l)"
  if [ "$links" -ne 0 ]; then
    die "в бандле $links симлинк(ов), например: $(find "$root" -type l | head -5 | tr '\n' ' ')— такой архив не распакуется на FAT/exFAT"
  fi
  echo "   ok патчи, синтаксис и отсутствие симлинков проверены"
}

# ── assembly ───────────────────────────────────────────────────────────────

make_bundle() {
  local dir="$1" launcher="$2"
  mkdir -p "$dir/dsh" "$dir/dsh-home/profiles" "$dir/bin"

  # ── copy dsh installation (the CLI app itself) ──────────────
  cp -a "$DL/build/node_modules/$NPM_PKG/." "$dir/dsh/"

  # ── copy entire node_modules flat tree ───────────────────────
  # On exFAT we can't create symlinks, so profiles need the full
  # dependency tree available via Node resolution.
  cp -a "$DL/build/node_modules/." "$dir/dsh/node_modules/"
  rm -rf "$dir/dsh/node_modules/@deepseek-ai/dsh"

  # ── copy the same node_modules to profiles fallback ──────────
  # Required because profile packages (like dsh-base, dsh-web-app)
  # are imported from the profile directory context, and Node ESM
  # won't walk up to dsh/node_modules.
  # NB: это вторая полная копия дерева — бандл занимает примерно вдвое
  # больше места, чем сама установка (осознанная плата за работу без symlink).
  cp -a "$DL/build/node_modules/." "$dir/dsh-home/profiles/node_modules/"
  rm -rf "$dir/dsh-home/profiles/node_modules/@deepseek-ai/dsh"

  # ── dsh-home from source (до патчей: копия может перезаписать profiles/) ──
  if [ -n "$DSH_SOURCE" ] && [ -d "$DSH_SOURCE" ]; then
    echo "  Copying dsh-home from $DSH_SOURCE..."
    rsync -a --no-links "$DSH_SOURCE/" "$dir/dsh-home/"
  fi

  # always ensure dirs exist
  mkdir -p "$dir/dsh-home/cache" "$dir/dsh-home/logs" "$dir/dsh-home/storages"
  mkdir -p "$dir/dsh-home/sessions"

  # ── apply patches for exFAT compatibility (после всех копирований) ──
  patch_portable "$dir/dsh/node_modules"
  patch_portable "$dir/dsh-home/profiles/node_modules"
  verify_tree "$dir"

  # ── launcher ─────────────────────────────────────────────────
  cp "$ROOT/launch.$launcher" "$dir/launch.$launcher"
  chmod +x "$dir/launch.$launcher" 2>/dev/null || true

  # ── README, CHANGELOG & LICENSE ──────────────────────────────
  # README.md бандла ссылается на README.ru.md и CHANGELOG.md, поэтому они
  # обязательны: без них в собранном бандле были бы битые ссылки.
  for doc in LICENSE README.md README.ru.md CHANGELOG.md; do
    [ -f "$ROOT/$doc" ] || die "в репозитории нет $doc"
    cp "$ROOT/$doc" "$dir/$doc"
  done

  echo "  Bundle prepared: $dir"
}

# ── build ──────────────────────────────────────────────────────────────────

if [ -e "$OUT" ]; then
  echo "== Очищаю $OUT =="
  rm -rf "$OUT"
fi
mkdir -p "$OUT"

echo "== Building Linux bundle =="
make_bundle "$DL/dsh-portable" sh
( cd "$DL/dsh-portable" && tar -czf "$OUT/dsh-portable-linux-x64.tar.gz" . )
echo "  -> $OUT/dsh-portable-linux-x64.tar.gz"

# Проверяем именно то, что попадёт к пользователю: распаковываем архив и патчим заново из него.
mkdir -p "$DL/verify-linux"
tar -xzf "$OUT/dsh-portable-linux-x64.tar.gz" -C "$DL/verify-linux"
verify_tree "$DL/verify-linux"

# Windows (optional, requires zip)
if command -v zip >/dev/null 2>&1; then
  echo "== Building Windows bundle =="
  echo "  NB: дерево зависимостей собрано на этой ОС (--no-optional/--ignore-scripts)."
  echo "      Нативные аддоны не поддерживаются: такой бандл годится для чисто-JS dsh."
  make_bundle "$DL/dsh-portable-win" cmd
  ( cd "$DL/dsh-portable-win" && zip -qr "$OUT/dsh-portable-windows-x64.zip" . )
  echo "  -> $OUT/dsh-portable-windows-x64.zip"
else
  echo "  zip не найден — Windows-бандл пропущен (установи zip и повтори)"
fi

echo ""
echo "== Done =="
ls -lh "$OUT/"
echo ""
echo "To initialize dsh-home from your current ~/.dsh, run:"
echo "  bash init-portable.sh"
