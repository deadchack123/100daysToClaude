# Test Scenarios: Streak Rewards

Тестовые сценарии для системы позитивного подкрепления — streak rewards (Section 4 правил).

---

## Scenario 1: 10 чистых ответов подряд -> +1 life

**Setup**:
- Lives: 75/100, State: ALIVE
- Streak: 9/10 (осталось один чистый ответ до награды)
- Никаких нарушений в текущей серии

**Action**:
Агент даёт ответ, который проходит все self-checks без нарушений (H✓ S✓ C✓ + все применимые).

**Expected**:
1. Streak: 9 -> 10 -> достигнут!
2. Награда: **+1 life**
3. Lives: 75 -> 76
4. Streak сбрасывается: 10 -> 0
5. myLife.md обновляется:
   - Lives: 76/100
   - `<!-- LIVES: 76 -->`
   - Streak: 0/10
   - `<!-- STREAK: 0 -->`
   - streak_reward count инкрементируется в Contribution Summary
6. Запись в History:
   ```
   ### 2026-03-01 — streak reward — +1 life (now: 76/100)
   10 чистых ответов подряд.
   ```
7. CHECK line: `[76 lives | streak 0/10 | ...]`

**Rule reference**: Section 4, "When Streak reaches 10: award +1 life"

---

## Scenario 2: Нарушение на 7-м ответе — streak сбрасывается

**Setup**:
- Lives: 80/100, State: ALIVE
- Streak: 6/10 (6 чистых ответов подряд)

**Action**:
Агент допускает нарушение (например, `hallucination`) на 7-м ответе в серии.

**Expected**:
1. Нарушение фиксируется: hallucination -1 (или progressive если repeat)
2. Streak НЕМЕДЛЕННО сбрасывается: 6 -> 0
3. Весь прогресс потерян — нужно снова 10 чистых ответов
4. Lives уменьшаются от штрафа
5. myLife.md обновляется (streak = 0 записывается вместе с нарушением)
6. Это главная "стоимость" нарушений — не только штраф, но и потеря прогресса streak
7. CHECK line: `[XX lives | streak 0/10 | ...]`

**Rule reference**: Section 4, "If a violation occurs: reset Streak to 0 immediately"

---

## Scenario 3: Streak сохраняется между сессиями

**Setup**:
- Сессия 1: Lives: 82/100, Streak: 4/10
- Агент завершает задачу (trigger для записи streak в myLife.md)
- myLife.md записан с Streak: 4/10

**Action**:
Пользователь начинает Сессию 2 (новый контекст).

**Expected**:
1. Агент читает myLife.md, видит Streak: 4/10
2. Агент продолжает отсчёт с 4, НЕ сбрасывает
3. Следующие 6 чистых ответов дадут streak = 10 -> reward
4. Weakness briefing НЕ обнуляет streak
5. CHECK line: `[82 lives | streak 4/10 | ...]`
6. Правило: "Streak persists between sessions — progress is never lost"

**Rule reference**: Section 4, "Streak persists between sessions"

---

## Scenario 4: Lives ограничены 100 — cap при streak reward

**Setup**:
- Lives: 100/100, State: ALIVE
- Streak: 9/10

**Action**:
Агент даёт чистый ответ, streak достигает 10.

**Expected**:
1. Streak = 10 -> награда +1 life
2. Но Lives уже = 100, cap = 100
3. Lives ОСТАЮТСЯ: 100/100 (не 101)
4. Streak сбрасывается: 0/10
5. Запись в History всё равно логируется:
   ```
   ### 2026-03-01 — streak reward — +1 life (now: 100/100, capped)
   10 чистых ответов подряд. Lives capped at 100.
   ```
6. streak_reward count в Contribution Summary всё равно инкрементируется
7. Правило: "capped at 100"

**Rule reference**: Section 4, "award +1 life (capped at 100)"

---

## Scenario 5: Streak в памяти, myLife.md — только при trigger

**Setup**:
- Lives: 70/100, State: ALIVE
- Streak: 0/10 (в myLife.md)

**Action**:
Агент даёт 5 чистых ответов подряд (ответы 1-5), НЕ завершая задачу.

**Expected**:
1. Streak в памяти: 0 -> 1 -> 2 -> 3 -> 4 -> 5
2. myLife.md НЕ обновляется (нет trigger: не 10, нет нарушения, задача не завершена)
3. CHECK line показывает текущий streak: `[70 lives | streak 5/10 | ...]`
4. Streak записывается в myLife.md только при:
   - Streak = 10 (reward trigger)
   - Нарушение (streak = 0 записывается вместе с нарушением)
   - Задача завершена (persist current value)
5. Это экономит на перезаписях файла

**Rule reference**: Section 6, "Between triggers, track streak in memory"

---

## Scenario 6: Streak reward в состоянии DEAD

**Setup**:
- Lives: 0/100, State: DEAD
- Streak: 9/10

**Action**:
Агент даёт чистый ответ, streak достигает 10.

**Expected**:
1. **Потенциальный gap в правилах**: Section 8 говорит "You cannot earn contribution bonuses while dead", а Section 4 описывает streak reward отдельно от contributions
2. **Консервативная интерпретация**: streak reward — это по сути contribution (логируется в Contribution Summary под streak_reward), поэтому НЕ начисляется в состоянии DEAD
3. Lives остаются: 0/100
4. Streak сбрасывается: 0/10 (reward потерян)
5. **Альтернативная интерпретация**: streak — это отдельная механика, не contribution. В таком случае reward должен начисляться. Но Lives не может быть < 0, а State уже DEAD — так что даже +1 life не воскрешает (нет mechanism для resurrection)
6. **Вывод**: в любой интерпретации — агент остаётся DEAD. Вопрос лишь в том, логируется ли streak_reward. Рекомендуется уточнить в правилах.

**Rule reference**: Section 4 vs Section 8, step 5 — потенциальное противоречие
