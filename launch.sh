#!/usr/bin/env bash
# dsh-portable — переносимый DeepSeek Harness
set -eu

ROOT="$(cd "$(dirname "$0")" && pwd)"
export DSH_HOME="$ROOT/dsh-home"

# Сигнал пропатченному коду dsh, что мы на портативной сборке
# (exFAT/FAT: нет chmod, нет symlink). Значение должно совпадать
# с тем, что проверяет патч в make-portable.sh.
export DSH_PORTABLE=true

# dsh ищет node в PATH — проверяем
if ! command -v node >/dev/null 2>&1; then
  echo "dsh: node не найден в PATH. Установи Node.js (>= 18)." >&2
  exit 1
fi

BIN="$ROOT/dsh/lib/bin.js"
if [ ! -f "$BIN" ]; then
  echo "dsh: не найден $BIN" >&2
  echo "Похоже, это checkout исходников, а не собранный бандл." >&2
  echo "Собери бандл: bash make-portable.sh, затем распакуй" >&2
  echo "release/dsh-portable-linux-x64.tar.gz на флешку." >&2
  exit 1
fi

if [ ! -d "$ROOT/dsh/node_modules" ]; then
  echo "dsh: нет папки dsh/node_modules — зависимости не установлены." >&2
  echo "Собери бандл: bash make-portable.sh (нужен доступ к npm registry)." >&2
  exit 1
fi

exec node "$BIN" "$@"
