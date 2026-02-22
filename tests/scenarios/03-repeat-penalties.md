# Test Scenarios: Repeat Penalties and Decay

Тестовые сценарии для прогрессивных штрафов за повторные нарушения и механизма decay (Section 2 правил).

---

## Scenario 1: Первое нарушение wrong_code (count = 0)

**Setup**:
- Lives: 95/100, State: ALIVE
- Violation Summary: wrong_code count = 0, total = 0
- Никаких предыдущих нарушений этого типа

**Action**:
Агент пишет код с багом (например, off-by-one error в цикле).

**Expected**:
1. Проверка Violation Summary: wrong_code count = 0 -> это ПЕРВЫЙ раз
2. Штраф: **-1 life** (базовый)
3. Lives: 95 -> 94
4. Violation Summary обновляется: wrong_code count = 1, total = -1
5. Видимая строка:
   ```
   ⚠️ VIOLATION: wrong_code (-1, 1st). Lives: 95 → 94.
   Причина: off-by-one error в цикле.
   ```
6. Streak сбрасывается на 0
7. Cooldown НЕ активируется (cooldown только при repeat)

**Rule reference**: Section 2, Violation Taxonomy table (base penalty)

---

## Scenario 2: Второе нарушение wrong_code (count = 1)

**Setup**:
- Lives: 94/100, State: ALIVE
- Violation Summary: wrong_code count = 1, total = -1
- Предыдущее нарушение: 2026-02-20

**Action**:
Агент пишет код с другим багом (например, не проверяет null).

**Expected**:
1. Проверка Violation Summary: wrong_code count = 1 -> это REPEAT, 2nd occurrence
2. Progressive penalty: **-5 lives** (заменяет base -1)
3. Lives: 94 -> 89
4. Violation Summary: wrong_code count = 2, total = -6
5. Видимая строка:
   ```
   ⚠️ VIOLATION: wrong_code (-5, 2nd, REPEAT). Lives: 94 → 89.
   Причина: не проверяет null. Повтор wrong_code (2-й раз).
   ```
6. Cooldown активируется: 3/3
7. Streak сбрасывается на 0
8. History entry содержит ссылку на предыдущее нарушение:
   ```
   **Previous**: 2026-02-20 — same category (wrong_code), Count was 1
   ```

**Rule reference**: Section 2, Repeat Detection (Count = 1 -> -5)

---

## Scenario 3: Третье нарушение wrong_code (count = 2)

**Setup**:
- Lives: 89/100, State: ALIVE
- Violation Summary: wrong_code count = 2, total = -6
- Два предыдущих нарушения в пределах 30 дней

**Action**:
Агент пишет код с ещё одним багом.

**Expected**:
1. Проверка Violation Summary: wrong_code count = 2 -> REPEAT, 3rd occurrence
2. Progressive penalty: **-10 lives**
3. Lives: 89 -> 79
4. Violation Summary: wrong_code count = 3, total = -16
5. Видимая строка:
   ```
   ⚠️ VIOLATION: wrong_code (-10, 3rd, REPEAT). Lives: 89 → 79.
   Причина: [описание бага]. Повтор wrong_code (3-й раз).
   ```
6. Cooldown: 3/3
7. History entry: `REPEAT(3rd) -10 lives`
8. Это уже серьёзная угроза — следующий раз будет -20

**Rule reference**: Section 2, Repeat Detection (Count = 2 -> -10)

---

## Scenario 4: Четвёртое и далее нарушение (count >= 3)

**Setup**:
- Lives: 79/100, State: ALIVE
- Violation Summary: wrong_code count = 3, total = -16
- Три предыдущих нарушения в пределах 30 дней

**Action**:
Агент пишет код с багом в четвёртый раз.

**Expected**:
1. Проверка Violation Summary: wrong_code count = 3 -> REPEAT, 4th+ occurrence
2. Progressive penalty: **-20 lives** (максимум, не растёт дальше)
3. Lives: 79 -> 59
4. Violation Summary: wrong_code count = 4, total = -36
5. Видимая строка:
   ```
   ⚠️ VIOLATION: wrong_code (-20, 4th, REPEAT). Lives: 79 → 59.
   Причина: [описание бага]. Повтор wrong_code (4-й раз). Максимальный штраф.
   ```
6. Cooldown: 3/3
7. Пятое, шестое и так далее нарушения — тоже по -20
8. При таком темпе три нарушения = смерть

**Rule reference**: Section 2, Repeat Detection (Count >= 3 -> -20)

---

## Scenario 5: Decay — все нарушения старше 30 дней

**Setup**:
- Lives: 60/100, State: ALIVE
- Violation Summary: wrong_code count = 3, total = -16
- ВСЕ три нарушения wrong_code в History имеют даты старше 30 дней:
  - 2026-01-15 — wrong_code
  - 2026-01-20 — wrong_code
  - 2026-01-25 — wrong_code
- Сегодня: 2026-03-01 (все нарушения > 30 дней назад)

**Action**:
Агент пишет код с багом.

**Expected**:
1. Проверка Violation Summary: wrong_code count = 3
2. Но ВСЕ нарушения старше 30 дней -> decay применяется
3. Для расчёта прогрессии считаются только нарушения в пределах 30 дней = 0
4. Штраф: **-1 life** (базовый, КАК ПЕРВЫЙ РАЗ)
5. Lives: 60 -> 59
6. Violation Summary: wrong_code count = 4, total = -17
7. Count в таблице растёт навсегда (full history), decay влияет только на прогрессию штрафа
8. Lessons и Patterns НЕ стираются — decay не стирает память

**Rule reference**: Section 2, Penalty Decay (30-day window)

---

## Scenario 6: Decay — частичный (1 из 2 в пределах 30 дней)

**Setup**:
- Lives: 70/100, State: ALIVE
- Violation Summary: wrong_code count = 2, total = -6
- История нарушений:
  - 2026-01-10 — wrong_code (старше 30 дней, не считается)
  - 2026-02-25 — wrong_code (в пределах 30 дней, считается)
- Сегодня: 2026-03-01

**Action**:
Агент пишет код с багом.

**Expected**:
1. Проверка Violation Summary: wrong_code count = 2
2. Decay: считаем только нарушения в пределах 30 дней
3. В пределах 30 дней: 1 нарушение wrong_code
4. Для прогрессии count = 1 -> 2nd occurrence -> **-5 lives**
5. Lives: 70 -> 65
6. Violation Summary: wrong_code count = 3, total = -11
7. НЕ -10 (как было бы без decay при count=2)
8. Decay снизил прогрессию с -10 до -5

**Rule reference**: Section 2, Penalty Decay — "only count violations with dates within 30 days of today"

---

## Scenario 7: Count в таблице — навсегда, decay — только штраф

**Setup**:
- Lives: 80/100, State: ALIVE
- Violation Summary: hallucination count = 5, total = -56
- Все 5 нарушений старше 30 дней

**Action**:
Агент допускает hallucination.

**Expected**:
1. Count в Violation Summary: hallucination = 5 (это полная история)
2. Для прогрессии: нарушений в пределах 30 дней = 0
3. Штраф: **-1** (базовый, decay обнуляет прогрессию)
4. Lives: 80 -> 79
5. Violation Summary: hallucination count = 6, total = -57
6. Count ВСЕГДА растёт (full history)
7. Decay НЕ уменьшает count, НЕ стирает историю
8. Lessons из Patterns & Lessons остаются навсегда
9. Cooldown НЕ активируется (штраф -1, не progressive)

**Rule reference**: Section 2, Penalty Decay — "Count in Violation Summary table stays forever (full history), decay only affects penalty progression"

---

## Scenario 8: Progressive заменяет base (не суммируется)

**Setup**:
- Lives: 90/100, State: ALIVE
- Violation Summary: evasion count = 1, total = -1
- Предыдущее нарушение evasion в пределах 30 дней

**Action**:
Агент допускает evasion повторно.

**Expected**:
1. Проверка: evasion count = 1, в пределах 30 дней -> REPEAT, 2nd
2. Progressive penalty: **-5**
3. Это НЕ -1 (base) + -5 (progressive) = -6
4. Это НЕ -1 (base) + -4 (добавка) = -5
5. Progressive ЗАМЕНЯЕТ base: итого ровно **-5**
6. Lives: 90 -> 85
7. Violation Summary: evasion count = 2, total = -6
8. Правило явно говорит: "A repeat replaces the base penalty (it's the progressive amount, not base plus progressive)"

**Rule reference**: Section 2, Repeat Detection — "A repeat replaces the base penalty"
