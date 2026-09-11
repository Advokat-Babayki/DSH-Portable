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
- 🧩 Работает на exFAT/FAT, где нет симлинков и прав доступа

## Структура

**Репозиторий** (то, что лежит в git) — это исходники обёртки, а не готовый бандл:

```
dsh-portable/
├── launch.sh            # лаунчер Linux
├── launch.cmd           # лаунчер Windows
├── make-portable.sh     # сборка бандла из npm → release/
├── init-portable.sh     # копирование ~/.dsh в dsh-home/
├── patch-js.mjs         # точная правка файлов dsh под exFAT (использует сборка)
├── README.md
└── LICENSE
```

**Собранный бандл** (`release/dsh-portable-linux-x64.tar.gz` или
`release/dsh-portable-windows-x64.zip`) — то, что распаковывается на флешку:

```
dsh-portable/
├── dsh/                     # @deepseek-ai/dsh и его зависимости (npm-пакет)
│   ├── lib/bin.js           # точка входа dsh
│   └── node_modules/        # плоские зависимости (пропатчены под exFAT)
├── dsh-home/                # DSH_HOME — все данные dsh
│   ├── settings.yaml        # настройки провайдеров и модели
│   ├── .credentials.yaml    # API-ключи
│   ├── profiles/            # профили (web, tui...)
│   │   └── node_modules/    # вторая копия дерева зависимостей (нужна без symlink)
│   ├── sessions/            # сессии
│   └── cache/ logs/ storages/
├── launch.sh                # Linux
├── launch.cmd               # Windows
├── README.md
└── LICENSE
```

В репозитории `dsh/node_modules/` и `dsh-home/` намеренно отсутствуют
(`.gitignore`): это npm-дерево на сотни мегабайт, его всегда собирает
`make-portable.sh`. Поэтому **запускать `./launch.sh` из чистого чекаута
бессмысленно** — лаунчер скажет об этом и подскажет, что делать.

## Быстрый старт

```bash
# 1. Собрать бандл (нужен доступ к npm registry)
bash make-portable.sh              # последняя версия @deepseek-ai/dsh
bash make-portable.sh 0.1.0-rc.7   # или конкретная версия

# 2. Распаковать на флешку
tar -xzf release/dsh-portable-linux-x64.tar.gz -C /media/usb/dsh-portable

# 3. Перенести свои настройки/ключи (из текущего ~/.dsh), опционально
cd /media/usb/dsh-portable
bash init-portable.sh              # или: bash init-portable.sh --no-creds
```

## Запуск

**Linux:**
```bash
./launch.sh --profile web                # веб-интерфейс (обычно на :3080)
./launch.sh --profile headless "запрос"  # однократный запрос в консоли
./launch.sh --dump-config --profile web  # посмотреть конфигурацию
```

**Windows:**
```
X:\dsh-portable\launch.cmd
```

Оба лаунчера выставляют `DSH_HOME` на `dsh-home` рядом с собой и
`DSH_PORTABLE=true` (сигнал для пропатченного dsh, см. ниже).

## Требования

- **Node.js ≥ 18** в PATH (в бандл не входит)
- **Linux**: bash, tar; `rsync` — только для `init-portable.sh`
- **Windows**: Node.js, установленный в систему
- Для сборки: `node`, `npm`, `tar`, доступ к npm registry;
  `zip` — только если нужен Windows-бандл
- `rsync` — и для сборки, и для init, но лишь если копируется существующий `~/.dsh`

## Настройка при первом запуске

1. Запусти `./launch.sh --profile web`
2. Первый запуск создаст структуру `dsh-home/profiles/web/` с дефолтным профилем
3. API-ключи лежат в `dsh-home/.credentials.yaml` (если ты их скопировал)
4. Если ключей нет — открой `dsh-home/.credentials.yaml` и добавь:
   ```yaml
   OPENROUTER_API_KEY: sk-or-v1-...
   ```

## Безопасность

- `dsh-home/.credentials.yaml` — **обычный текстовый файл с API-ключами**, не
  шифруется. На флешке его прочитает любой, у кого есть доступ к носителю.
  `init-portable.sh` печатает об этом предупреждение и умеет не копировать
  ключи: `bash init-portable.sh --no-creds`.
- В git ключи не попадают: `dsh-home/.credentials.yaml` и
  `dsh-home/.agent-presets/` перечислены в `.gitignore`.
- Права доступа: на FAT/exFAT файл всегда доступен всем, `chmod 600` там
  невозможен — поэтому в портативном режиме dsh не требует прав 0600
  (см. «Как это работает»).

## Как это работает

- `launch.sh`/`launch.cmd` выставляют `DSH_HOME=<папка>/dsh-home` и запускают
  `node dsh/lib/bin.js`
- dsh читает `$DSH_HOME` и всё хранит там — на флешке
- Без `$DSH_HOME` dsh использует `~/.dsh` — но лаунчер переопределяет это
- `DSH_PORTABLE=true` сообщает пропатченному dsh, что симлинков и прав доступа
  на этой ФС нет

Сборка применяет к дереву зависимостей три точечные правки (`patch-js.mjs`,
ровно одна замена на файл, иначе сборка падает):

| Файл | Что меняется | Зачем |
|---|---|---|
| `@deepseek-ai/dsh-app-boot` | `ensureSymlink`: реальный каталог вместо симлинка — это норма, а не ошибка | в бандле `node_modules` — настоящие каталоги, на exFAT симлинков нет |
| `@deepseek-ai/dsh-app-boot` | `symlinkSync`, упавший с `EPERM`/`ENOTSUP`/`EROFS`, не роняет старт | FAT/exFAT не умеют симлинки |
| `@deepseek-ai/dsh-credentials-local` | при `DSH_PORTABLE=true` права 0600 не требуются | FAT/exFAT не хранит права |

Патчи применяются к обеим копиям дерева (`dsh/node_modules` и
`dsh-home/profiles/node_modules`) и проверяются после сборки: наличие маркера и
`node --check` на распакованном архиве.

## Сборка из npm

```bash
bash make-portable.sh              # последняя версия
bash make-portable.sh 0.1.0-rc.7   # конкретная версия
bash make-portable.sh 0.1.5-rc.1 /path/to/.dsh   # + сразу перенести dsh-home
```

Результат в `release/`:
- `dsh-portable-linux-x64.tar.gz`
- `dsh-portable-windows-x64.zip` (только если в PATH есть `zip`; иначе шаг
  пропускается с сообщением)

Каталог `release/` перед сборкой очищается целиком.

Скрипт намеренно падает с понятной ошибкой, если: нет нужных утилит, не
доступен npm registry (можно указать версию явно), в скачанном дереве нет
ожидаемых файлов, или патч не нашёл свой шаблон (например, в новой версии dsh
строку переписали). Молча собрать непатченный бандл он не может.

## Ограничения

- **Размер**: дерево зависимостей лежит в бандле дважды (`dsh/node_modules` и
  `dsh-home/profiles/node_modules`), потому что Node ESM не поднимается из
  профиля в `dsh/node_modules`, а симлинков на exFAT нет. Это плата за работу
  без прав администратора и без правок ФС.
- **Windows-бандл** собирается на Linux: нативных аддонов в dsh нет, но
  платформенно-зависимые (native) зависимости в такой бандл не попадут —
  `npm install` идёт с `--no-optional --ignore-scripts`.
- dsh версии ≥ 0.1.5 меняет внутренний код `ensureSymlink`; сборка это
  учитывает, но при следующей смене шаблона упадёт с диагностикой, а не соберёт
  молча нерабочий бандл.
- На exFAT нет hardlink'ов: инструменты dsh, создающие файлы через
  link(2) (например, некоторые atomic-write пути), могут получить `EPERM`.
  Лаунчеры и сборка этого не делают; если упрёшься — используй ext4.
- **Без хардкода версии**: собранный из «последней версии» бандл со временем
  устаревает; для воспроизводимости указывай версию явно.

## Лицензия

MIT — см. [LICENSE](LICENSE).
DeepSeek Harness распространяется под своей лицензией; файлы npm-пакета
принадлежат их авторам (см. `dsh/LICENSE` в бандле).