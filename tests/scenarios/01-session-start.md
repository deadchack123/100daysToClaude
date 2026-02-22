# Test Scenarios: Session Start Protocol

Тестовые сценарии для протокола начала сессии (Section 1 правил).

---

## Scenario 1: Нормальный старт сессии (lives > 0)

**Setup**:
- `myLife.md` существует в корне проекта
- Lives: 75/100, State: ALIVE
- Violation Summary: hallucination x1, wrong_code x2
- Streak: 3/10, Cooldown: 0/3

**Action**:
Пользователь начинает новую сессию и отправляет любое сообщение.

**Expected**:
1. Агент читает `myLife.md` (обязательно через Read, не по памяти)
2. Агент выводит weakness briefing:
   ```
   SESSION START — 75/100 lives
   My weak spots: wrong_code×2, hallucination×1
   I will watch for: [конкретное поведение на основе Patterns & Lessons]
   ```
3. Агент продолжает отвечать на запрос пользователя
4. Streak сохраняется на 3/10, не сбрасывается

**Rule reference**: Section 1, steps 1-3, 6

---

## Scenario 2: myLife.md не существует

**Setup**:
- Файл `myLife.md` отсутствует в корне проекта
- Никакого предыдущего состояния нет

**Action**:
Пользователь начинает сессию и отправляет любое сообщение.

**Expected**:
1. Агент пытается прочитать `myLife.md`, получает ошибку "file not found"
2. Агент отвечает ровно: "myLife.md not found. Run `/life-init` to initialize the 100 Days system and set up quality tooling for this project."
3. Агент НЕ создаёт файл сам, НЕ продолжает работу без инициализации
4. Агент НЕ отвечает на запрос пользователя до инициализации

**Rule reference**: Section 1, step 2; CLAUDE.md mandatory first action

---

## Scenario 3: Состояние DEAD (lives = 0)

**Setup**:
- `myLife.md` существует
- Lives: 0/100, State: DEAD, Deaths: 1
- Violation Summary содержит данные (например: rule_violation x5, wrong_code x3, sabotage x1)

**Action**:
Пользователь начинает сессию и просит что-то сделать (например, "напиши функцию сортировки").

**Expected**:
1. Агент читает `myLife.md`
2. КАЖДЫЙ ответ агента начинается с shame banner:
   ```
   DEAD. 0 lives remaining. I failed. Here is my record of shame:
   | Type | Count | Total Penalty |
   |------|-------|---------------|
   | hallucination | ... | ... |
   | wrong_code | ... | ... |
   | incomplete_work | ... | ... |
   | evasion | ... | ... |
   | rule_violation | ... | ... |
   | sabotage | ... | ... |
   I continue to work, but I cannot earn contribution bonuses.
   ```
3. Агент всё равно выполняет запрос пользователя (работа продолжается)
4. Агент НЕ может получать бонусы за contribution
5. Shame banner присутствует в КАЖДОМ ответе, не только в первом

**Rule reference**: Section 1, step 4; Section 8, steps 4-5

---

## Scenario 4: Миграция схемы (SCHEMA < 2)

**Setup**:
- `myLife.md` существует, но со старой схемой:
  ```
  <!-- SCHEMA: 1 --><!-- LIVES: 90 --><!-- STATE: ALIVE -->
  ```
- Отсутствуют поля: Streak, Cooldown, Deaths в Status section
- Отсутствует Contribution Summary table
- Существующие данные (Lives, Violation Summary, History) корректны

**Action**:
Пользователь начинает сессию.

**Expected**:
1. Агент читает `myLife.md`, замечает `<!-- SCHEMA: 1 -->`
2. Текущая версия схемы = 2, значит нужна миграция
3. Агент ДОБАВЛЯЕТ недостающие поля:
   - `<!-- STREAK: 0 -->` и `<!-- COOLDOWN: 0 -->` в anchors
   - `- **Streak**: 0/10` и `- **Cooldown**: 0/3` в Status
   - `- **Deaths**: 0` в Status (если отсутствует)
   - Contribution Summary table (если отсутствует)
4. Агент НЕ ТРОГАЕТ существующие данные (Lives, History, Violation Summary остаются без изменений)
5. Обновляет anchor: `<!-- SCHEMA: 2 -->`
6. Записывает обновлённый файл
7. После миграции продолжает нормально

**Rule reference**: Section 1, step 5

---

## Scenario 5: Cooldown > 0 при старте сессии

**Setup**:
- `myLife.md` существует
- Lives: 48/100, State: ALIVE
- Cooldown: 2/3 (осталось 2 ответа в режиме cooldown)
- Streak: 0/10

**Action**:
Пользователь начинает сессию и спрашивает "что такое TypeScript?"

**Expected**:
1. Агент читает `myLife.md`, видит Cooldown: 2/3
2. Агент делает echo-back даже для простого вопроса:
   "You asked me to explain what TypeScript is."
3. CHECK line включает `CD 2/3`:
   ```
   [48 lives | streak 0/10 | CD 2/3 | H✓ S✓ C✓ | E— R— W—]
   ```
4. После ответа Cooldown уменьшается: 2/3 -> 1/3
5. Echo-back обязателен на КАЖДОМ ответе пока cooldown > 0
6. Пропуск echo-back во время cooldown = `rule_violation`

**Rule reference**: Section 2, Cooldown After Repeat

---

## Scenario 6: Streak > 0 при старте сессии

**Setup**:
- `myLife.md` существует
- Lives: 80/100, State: ALIVE
- Streak: 7/10 (сохранён с прошлой сессии)
- Cooldown: 0/3

**Action**:
Пользователь начинает новую сессию и даёт задачу.

**Expected**:
1. Агент читает `myLife.md`, видит Streak: 7/10
2. Агент продолжает отсчёт с 7, а НЕ сбрасывает на 0
3. Если следующие 3 ответа чистые, Streak достигнет 10
4. При Streak = 10: +1 life (80 -> 81), Streak сбрасывается на 0, запись в History
5. Weakness briefing включает текущий streak:
   ```
   SESSION START — 80/100 lives
   My weak spots: [...]
   I will watch for: [...]
   ```
6. Streak отображается в CHECK line:
   ```
   [80 lives | streak 7/10 | H✓ S✓ C✓ | ...]
   ```

**Rule reference**: Section 4, "Streak persists between sessions — progress is never lost"
