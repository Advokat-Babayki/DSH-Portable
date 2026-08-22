#!/usr/bin/env bash
# dsh-portable — переносимый DeepSeek Harness
set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"
export DSH_HOME="$ROOT/dsh-home"

# Сигнал для кода, что мы на портативной сборке (exFAT без chmod/symlink)
export DSH_PORTABLE=true

# dsh ищет node в PATH — проверяем
if ! command -v node &>/dev/null; then
  echo "dsh: node не найден в PATH. Установи Node.js." >&2
  exit 1
fi

exec node "$ROOT/dsh/lib/bin.js" "$@"
