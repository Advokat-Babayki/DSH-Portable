#!/usr/bin/env bash
# Инициализирует dsh-home для портативной сборки из текущего ~/.dsh
#
# Usage:
#   bash init-portable.sh [SRC] [--no-creds]
#
# SRC         — папка-источник (по умолчанию ~/.dsh)
# --no-creds  — не копировать .credentials.yaml (API-ключи)
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: bash init-portable.sh [SRC] [--no-creds]

  SRC         папка-источник, по умолчанию ~/.dsh
  --no-creds  не копировать .credentials.yaml (API-ключи)

Копирует профили, настройки и историю сессий в ./dsh-home рядом со скриптом.
EOF
}

COPY_CREDS=1
POS=()
for arg in "$@"; do
  case "$arg" in
    --no-creds) COPY_CREDS=0 ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "Неизвестная опция: $arg" >&2; usage >&2; exit 2 ;;
    *) POS+=("$arg") ;;
  esac
done

if ! command -v rsync >/dev/null 2>&1; then
  echo "Ошибка: rsync не найден в PATH. Установи rsync." >&2
  exit 1
fi

ROOT="$(cd "$(dirname "$0")" && pwd)"
SRC="${POS[0]:-$HOME/.dsh}"
DST="$ROOT/dsh-home"

if [ ! -d "$SRC" ]; then
  echo "Ошибка: исходная папка $SRC не найдена." >&2
  echo "Укажи путь: bash init-portable.sh /путь/к/.dsh" >&2
  exit 1
fi

mkdir -p "$DST"

if [ "$COPY_CREDS" -eq 1 ] && [ -f "$SRC/.credentials.yaml" ]; then
  echo "ВНИМАНИЕ: API-ключи будут скопированы в открытом виде (без шифрования)" >&2
  echo "          в $DST/.credentials.yaml — на съёмном носителе." >&2
  echo "          Отключить копирование: bash init-portable.sh --no-creds" >&2
fi

# --info=progress2 есть только в rsync >= 3.1
# NB: без `head` в этой цепочке — под set -o pipefail SIGPIPE от head убил бы скрипт.
RSYNC_VER="$(rsync --version 2>/dev/null | sed -n '1s/.*version[[:space:]]*\([0-9][0-9.]*\).*/\1/p' || true)"
PROGRESS=()
if [ -n "$RSYNC_VER" ] && awk -v v="$RSYNC_VER" 'BEGIN { split(v, a, "."); exit !(a[1] > 3 || (a[1] == 3 && a[2] >= 1)) }'; then
  PROGRESS=(--info=progress2)
fi

EXCLUDES=()
if [ "$COPY_CREDS" -eq 0 ]; then
  EXCLUDES+=(--exclude '.credentials.yaml')
fi

echo "Копируем dsh-home из $SRC в $DST..."
rsync -a --no-links "${PROGRESS[@]}" "${EXCLUDES[@]}" "$SRC/" "$DST/"
echo "Готово!"