# dsh-portable — портативный DeepSeek Harness (DSH)

Переносимая сборка [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (dsh).
Запускается прямо с флешки **без установки в систему**: конфиг, сессии, кэш и
профили лежат рядом с лаунчером. Ничего не пишется в `~/.dsh`, `~/.config` и т.д.

Windows и Linux пользуются **одним dsh-home и одними сессиями** — переключился
на другую ОС, сессии на месте.

## Возможности

- ⚡ **Без установки** — Node.js нужен на системе, всё остальное на флешке
- 🔑 **Твой API-ключ** — хранится в `dsh-home/.credentials.yaml` на флешке
- 🧭 Работает при любом пути/букве диска — пути в лаунчерах относительно себя
- 🖥️ Windows (`launch.cmd`) и Linux (`launch.sh`)

## Структура

```
dsh-portable/
├── dsh/                     # @deepseek-ai/dsh и его зависимости (npm-пакет)
│   ├── lib/bin.js           # точка входа dsh
│   └── node_modules/        # плоские зависимости
├── dsh-home/                # DSH_HOME — все данные dsh
│   ├── settings.yaml        # настройки провайдеров и модели
│   ├── .credentials.yaml    # API-ключи
│   ├── profiles/            # профили (web, tui...)
│   ├── sessions/            # сессии
│   └── cache/ logs/ storages/
├── launch.sh                # Linux
├── launch.cmd               # Windows
├── make-portable.sh         # скрипт сборки из npm
└── README.md
```

## Запуск

**Linux:**
```bash
cd /путь/к/dsh-portable
./launch.sh --profile web          # веб-интерфейс (обычно работает на :3080)
./launch.sh --profile headless "запрос"  # однократный запрос в консоли
./launch.sh --dump-config --profile web  # посмотреть конфигурацию
```

**Windows:**
```
X:\dsh-portable\launch.cmd
```

## Требования

- **Node.js ≥ 18** — должен быть в PATH (не входит в портативную сборку)
- **Linux**: bash, glibc (для Node.js бинарников)
- **Windows**: Node.js установленный в систему

## Настройка при первом запуске

1. Запусти `./launch.sh --profile web`
2. Первый запуск создаст структуру `dsh-home/profiles/web/` с дефолтным профилем
3. API-ключи уже лежат в `dsh-home/.credentials.yaml` (если ты скопировал свои)
4. Если ключей нет — открой `dsh-home/.credentials.yaml` и добавь:
   ```yaml
   OPENROUTER_API_KEY: sk-or-v1-...
   ```

## Как это работает

- `launch.sh` ставит `$DSH_HOME=<папка>/dsh-home` и запускает `node dsh/lib/bin.js`
- DSH читает `$DSH_HOME` и всё хранит там — на флешке
- Без `$DSH_HOME` dsh использует `~/.dsh` — но лаунчер переопределяет это

## Сборка из npm

```bash
bash make-portable.sh          # последняя версия
bash make-portable.sh 0.1.0-rc.7  # конкретная версия
```

Результат в `release/`:
- `dsh-portable-linux-x64.tar.gz`
- `dsh-portable-windows-x64.zip` (требуется zip)

## Лицензия

MIT — см. [LICENSE](LICENSE).
DeepSeek Harness распространяется под MIT; бинарные файлы принадлежат их авторам.
