#!/usr/bin/env bash
# Инициализирует dsh-home для портативной сборки из текущего ~/.dsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
SRC="${1:-$HOME/.dsh}"
DST="$ROOT/dsh-home"

if [ ! -d "$SRC" ]; then
  echo "Ошибка: исходная папка $SRC не найдена."
  echo "Укажи путь: bash init-portable.sh /путь/к/.dsh"
  exit 1
fi

echo "Копируем dsh-home из $SRC в $DST..."
rsync -a --no-links --info=progress2 "$SRC/" "$DST/" 2>/dev/null
echo "Готово!"
