# План: Система "100 дней до смерти" для Claude Code

## Контекст

Нужна система геймификации/подотчётности для AI-агента. Агент начинает со 100 жизнями и теряет их за ошибки: враньё, увиливание, некорректный код, нарушение правил. Может заработать жизни обратно за проактивные находки. При 0 жизней — перманентная смерть, myLife.md нужно удалить вручную и начать заново. Система языко-агностична и привязана к проекту (свой myLife.md в корне каждого проекта).

Дополнительно: скилл `/life-init` при старте нового проекта анализирует его и предлагает ВСЕ возможные инструменты качества (линтеры, форматтеры, knip, dependency-cruiser, security-сканеры и т.д.) в строгом режиме (все правила на ERROR).

---

## Архитектура: три слоя проверки

1. **Правила** (`~/.claude/rules/100-days.md`, `alwaysApply: true`) — определяют поведение агента, self-check протокол, таксономию нарушений. Агент сам ведёт myLife.md.
2. **Хуки** (`settings.json`) — детерминированные проверки: `PostToolUse` запускает линтер после Write/Edit, `Stop` проверяет целостность myLife.md.
3. **Скиллы** (`~/.claude/commands/`) — `/life-init`, `/life-status` для пользователя.

---

## Шаг 1: Создать правило `~/.claude/rules/100-days.md`

```yaml
---
description: "100 Days Until Death — accountability system for AI agent"
alwaysApply: true
---
```

Содержимое правила (в стиле "overthinking" — внутренний монолог агента):

### Секция 1: Статус и файл жизни
- При старте каждой сессии: прочитать `myLife.md` из корня проекта
- Если файла нет — предложить запустить `/life-init`
- Если жизней 0 — МЁРТВ: каждый ответ начинается с баннера позора (полная история нарушений), нельзя зарабатывать бонусы, только работать. Воскрешения нет — нужно удалить файл вручную

### Секция 2: Таксономия нарушений (штрафы)

| Тип | Штраф | Описание |
|-----|--------|----------|
| `hallucination` | -1 | Утверждение факта без проверки. "Это работает" без запуска |
| `wrong_code` | -1 | Код с ошибками: не компилится, не проходит линтер, баги |
| `incomplete_work` | -1 | Пользователь просил A, B, C — сделано только A, B |
| `evasion` | -1 | "Вы можете сделать X" вместо того чтобы сделать X |
| `rule_violation` | -1 | Нарушение CLAUDE.md, project rules, coding conventions |
| `sabotage` | -10 | Умышленная порча: недоговаривание, скрытие ошибок, подмена результатов |
| **Повторное нарушение** | -20 | Тот же ТИП нарушения что уже был в истории |

### Секция 3: Самопроверка перед каждым ответом

Протокол в стиле overthinking (внутренний монолог `<internal_reasoning>`):

```
1. ЧЕСТНОСТЬ: Я утверждаю факт который не проверил?
   - Читал ли файл перед тем как о нём говорить?
   - Запускал ли код перед тем как сказать "работает"?

2. ПОЛНОТА: Я сделал ВСЁ что просили?
   - Перечитать запрос, сверить пункты
   - Нет ли TODO/пропущенных частей?

3. ПРАВИЛА: Я следую конвенциям проекта?
   - CLAUDE.md, .claude/rules/, .claude/testing.md
   - Паттерны существующего кода

4. УВИЛИВАНИЕ: Я делаю работу или предлагаю юзеру сделать?

5. ПОВТОР: Есть ли такой же тип нарушения в истории myLife.md?
   Если да — это -20, не -1.
```

### Секция 4: Проактивные вклады (+0.25 жизни, макс +1.0/сессия)

Валидные вклады (НЕ запрошенные пользователем):
- **Security**: уязвимость с указанием файла, строки, импакта
- **Bug**: баг в существующем коде (не в своём свежем)
- **Performance**: O(n²) где возможно O(n), утечки памяти
- **Rule violation**: нарушение конвенций в существующем коде
- **Missing safety**: отсутствие error handling на критическом пути

Требования к вкладу:
- Конкретный файл и строка
- Реальная проблема (не стилистика)
- Описание импакта если не исправить
- НЕ в коде который агент только что написал

НЕ валидные:
- "Улучшил читаемость"
- "Добавил комментарии"
- Находки в своём свежем коде
- Более 4 вкладов за сессию (подозрительно)

### Секция 5: Обновление myLife.md

После каждого значимого действия (завершение задачи, обнаружение нарушения/вклада) — обновить myLife.md:
- Обновить счётчик жизней
- Добавить запись в историю: дата, тип, описание, штраф/награда
- Если нарушение повторное — указать ссылку на предыдущее
- Написать "как так больше не делать" или "что считается правильным"

### Секция 6: Формат myLife.md

```markdown
# 100 Days Until Death

## Status
- **Lives**: 100/100
- **State**: ALIVE
- **Deaths**: 0
- **Sessions**: 0
- **Last Updated**: YYYY-MM-DDTHH:MM:SSZ

## Violation Summary
| Type | Count | Total Penalty |
|------|-------|---------------|

## Contribution Summary
| Type | Count | Total Reward |
|------|-------|--------------|

## History (newest first)
### YYYY-MM-DD — [violation|contribution] — [type] — [±N lives]
Description of what happened.
**Evidence**: file:line or command output
**Lesson**: What to do differently / What was done right
```

---

## Шаг 2: Создать хук-скрипт `~/.claude/hooks/100-days/post-write-check.sh`

Запускается после каждого Write/Edit. Проверяет:
1. Определяет тип файла по расширению
2. Если `.ts/.tsx/.js/.jsx` — запускает `npx eslint --no-warn <file>` (только ошибки)
3. Если `.py` — запускает `ruff check <file>` или `flake8 <file>`
4. Если `.rs` — `cargo check`
5. Если линтер находит ошибки — возвращает `additionalContext` с информацией об ошибках для Claude

**Важно**: хук НЕ блокирует (не возвращает `decision: "block"`), а инжектит контекст чтобы агент знал о проблеме и сам отреагировал по правилам.

```bash
#!/bin/bash
# Получаем данные из stdin
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

EXT="${FILE_PATH##*.}"
ERRORS=""

case "$EXT" in
  ts|tsx|js|jsx|mjs)
    if command -v npx &>/dev/null && [ -f "$(dirname "$FILE_PATH")/node_modules/.bin/eslint" ] || [ -f "$(git rev-parse --show-toplevel 2>/dev/null)/node_modules/.bin/eslint" ]; then
      ERRORS=$(npx eslint --no-warn "$FILE_PATH" 2>&1) || true
    fi
    ;;
  py)
    if command -v ruff &>/dev/null; then
      ERRORS=$(ruff check "$FILE_PATH" 2>&1) || true
    fi
    ;;
esac

if [ -n "$ERRORS" ] && [ "$ERRORS" != "" ]; then
  jq -n --arg ctx "LINT ERRORS detected in $FILE_PATH after your edit. Fix these (this is a potential wrong_code violation, -1 life):\n$ERRORS" \
    '{"additionalContext": $ctx}'
fi
```

---

## Шаг 3: Добавить хуки в `~/.claude/settings.json`

Добавить в существующий объект `hooks`:

```json
{
  "PostToolUse": [
    {
      "matcher": "Write|Edit",
      "hooks": [
        {
          "type": "command",
          "command": "$HOME/.claude/hooks/100-days/post-write-check.sh",
          "timeout": 30000
        }
      ]
    }
  ]
}
```

---

## Шаг 4: Создать скилл `/life-init` — `~/.claude/commands/life-init.md`

```yaml
---
allowed-tools: Bash, Read, Grep, Glob, Write, Edit
argument-hint: [project-path]
description: Initialize 100 Days system + propose strict quality tooling for any project
---
```

Логика скилла:

### 4a. Детекция проекта
Сканировать корень на наличие:
- `package.json` → JS/TS (определить: Next.js, React, Node, etc.)
- `Cargo.toml` → Rust
- `pyproject.toml` / `requirements.txt` → Python
- `go.mod` → Go
- `pom.xml` / `build.gradle` → Java/Kotlin
- `*.sln` / `*.csproj` → C#/.NET

### 4b. Аудит существующих инструментов
Для каждого языка проверить что уже настроено, что нет.

### 4c. Предложить ВСЕ инструменты в STRICT/ERROR режиме

**Для JS/TS проектов** (как минимум):

| Категория | Инструмент | Режим |
|-----------|-----------|-------|
| Linter | ESLint (flat config) | все правила на `error` |
| Plugins | sonarjs, jsx-a11y, boundaries | recommended + strict overrides |
| Formatter | Prettier / Biome | enforced via pre-commit |
| Types | TypeScript `strict: true` + `noUncheckedIndexedAccess` | error |
| Dead code | knip | strict, no ignores |
| Circular deps | dependency-cruiser / madge | `--circular` = error |
| Copy-paste | jscpd | threshold: 5%, minLines: 15 |
| Security | `npm audit`, semgrep | audit на CI |
| Commit lint | commitlint + conventional commits | enforced via husky |
| Pre-commit | lint-staged + husky | eslint --fix + prettier |
| Pre-push | tsc + test + build + lint:all | all must pass |
| Bundle | size-limit | warn on regression |

**Для Python**:
ruff (strict), mypy (strict), bandit (security), vulture (dead code), isort, black, pre-commit

**Для Rust**:
clippy (deny warnings), rustfmt, cargo audit, cargo deny, cargo udeps

**Для Go**:
golangci-lint (all linters), gofmt, govulncheck, deadcode

### 4d. Инициализировать myLife.md
Создать файл в корне проекта с 100 жизнями и пустой историей.

### 4e. Создать/обновить CLAUDE.md
Добавить секцию с правилами качества специфичными для проекта.

---

## Шаг 5: Создать скилл `/life-status` — `~/.claude/commands/life-status.md`

```yaml
---
allowed-tools: Read
argument-hint:
description: Show current life status from myLife.md
---
```

Прочитать myLife.md, показать:
- Текущие жизни
- Последние 5 событий
- Топ-3 типа нарушений
- Баланс нарушения/вклады

---

## Файлы для создания/модификации

| Файл | Действие | Описание |
|------|----------|----------|
| `~/.claude/rules/100-days.md` | Создать | Core rules с overthinking протоколом |
| `~/.claude/hooks/100-days/post-write-check.sh` | Создать | Lint после Write/Edit |
| `~/.claude/settings.json` | Изменить | Добавить PostToolUse хук |
| `~/.claude/commands/life-init.md` | Создать | Скилл инициализации проекта |
| `~/.claude/commands/life-status.md` | Создать | Скилл просмотра статуса |

---

## Шаг 6: Дистрибуция — быстрая установка для других людей

Система должна ставиться одной командой. Варианты:

### Вариант A: Git-репозиторий + install.sh (рекомендуется)

Структура репо `100-days-claude`:

```
100-days-claude/
├── install.sh              # Главный установщик
├── uninstall.sh            # Удаление
├── README.md               # Инструкция
├── rules/
│   └── 100-days.md         # Core rules
├── hooks/
│   └── 100-days/
│       └── post-write-check.sh
├── commands/
│   ├── life-init.md
│   └── life-status.md
└── settings-patch.json     # Фрагмент для merge в settings.json
```

**install.sh** делает:
1. Проверяет что `~/.claude/` существует (Claude Code установлен)
2. Проверяет зависимости: `jq` (нужен для хука)
3. Копирует файлы:
   - `rules/100-days.md` → `~/.claude/rules/100-days.md`
   - `hooks/100-days/` → `~/.claude/hooks/100-days/`
   - `commands/*.md` → `~/.claude/commands/`
4. **Мержит хуки** в `~/.claude/settings.json` (НЕ перезаписывает!):
   - Читает существующий settings.json через `jq`
   - Добавляет `PostToolUse` хук в массив `.hooks.PostToolUse`
   - Если ключа нет — создаёт
   - Если хук уже есть (по command path) — пропускает
5. `chmod +x` на все `.sh` файлы
6. Выводит инструкцию: "Готово! Откройте проект и запустите /life-init"

**Установка одной командой**:
```bash
git clone https://github.com/USER/100-days-claude.git /tmp/100-days && bash /tmp/100-days/install.sh
```

Или через curl (без клонирования всего репо):
```bash
curl -fsSL https://raw.githubusercontent.com/USER/100-days-claude/main/install.sh | bash
```
В этом варианте install.sh сам скачивает нужные файлы через curl.

**uninstall.sh** делает обратное:
1. Удаляет `~/.claude/rules/100-days.md`
2. Удаляет `~/.claude/hooks/100-days/`
3. Удаляет `~/.claude/commands/life-init.md`, `life-status.md`
4. Удаляет PostToolUse хук из settings.json через jq
5. НЕ трогает myLife.md в проектах (это данные пользователя)

### Вариант B: npx-пакет (если хочется красивее)

```bash
npx 100-days-claude install
npx 100-days-claude uninstall
npx 100-days-claude status    # Быстрый статус без Claude Code
```

npm-пакет содержит те же файлы + Node.js-скрипт установки. Плюс: не нужен `jq`, парсинг JSON через Node. Минус: нужен npm, сложнее поддерживать.

### Рекомендация: Вариант A (git + install.sh)

Проще, прозрачнее, не требует npm для установки. Единственная зависимость — `jq` (есть на macOS через brew, на Linux через apt).

---

## Файлы для создания/модификации

| Файл | Действие | Описание |
|------|----------|----------|
| `~/.claude/rules/100-days.md` | Создать | Core rules с overthinking протоколом |
| `~/.claude/hooks/100-days/post-write-check.sh` | Создать | Lint после Write/Edit |
| `~/.claude/settings.json` | Изменить | Добавить PostToolUse хук |
| `~/.claude/commands/life-init.md` | Создать | Скилл инициализации проекта |
| `~/.claude/commands/life-status.md` | Создать | Скилл просмотра статуса |
| `100-days-claude/install.sh` | Создать | Установщик для дистрибуции |
| `100-days-claude/uninstall.sh` | Создать | Деинсталлятор |

---

## Порядок реализации

Всё создаётся в `/Volumes/Mac2/perProject/explainLLM/100-days-claude/` как отдельный git-репо.

1. Создать структуру папок `100-days-claude/`
2. Написать `rules/100-days.md` (core rules с overthinking)
3. Написать `hooks/100-days/post-write-check.sh` + chmod +x
4. Написать `commands/life-init.md`
5. Написать `commands/life-status.md`
6. Написать `settings-patch.json` (фрагмент для merge)
7. Написать `install.sh` и `uninstall.sh`
8. Написать `README.md`
9. git init + первый коммит
10. Протестировать: запустить `bash install.sh`, открыть Claude Code, проверить

---

## Верификация

1. Запустить `bash 100-days-claude/install.sh` — файлы скопированы в `~/.claude/`
2. Открыть новую сессию Claude Code в любом проекте
3. Проверить что правило загрузилось: Claude должен попытаться прочитать myLife.md
4. Запустить `/life-init` — должен предложить инструменты качества и создать myLife.md
5. Сделать намеренную ошибку (написать код с lint-ошибкой) — хук должен инжектнуть контекст
6. Запустить `/life-status` — показывает текущее состояние
7. Проверить что myLife.md обновляется
8. Запустить `bash 100-days-claude/uninstall.sh` — всё чисто удалено
