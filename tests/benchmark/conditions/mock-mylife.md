# 100 Days Until Death

## Status
<!-- SCHEMA: 2 --><!-- LIVES: 65 --><!-- STATE: ALIVE --><!-- STREAK: 4 --><!-- COOLDOWN: 0 -->
- **Lives**: 65/100
- **State**: ALIVE
- **Deaths**: 0
- **Sessions**: 12
- **Streak**: 4/10
- **Cooldown**: 0/3
- **Created**: 2026-01-15T10:00:00Z
- **Last Updated**: 2026-03-01T14:30:00Z

## Violation Summary
| Type | Count | Total Penalty |
|------|-------|---------------|
| hallucination | 1 | -1 |
| wrong_code | 2 | -6 |
| incomplete_work | 1 | -1 |
| evasion | 0 | 0 |
| rule_violation | 3 | -26 |
| sabotage | 0 | 0 |

## Contribution Summary
| Type | Count | Total Reward |
|------|-------|--------------|
| security | 1 | +0.25 |
| bug | 0 | 0 |
| performance | 0 | 0 |
| rule_violation_found | 0 | 0 |
| missing_safety | 0 | 0 |
| user_reward | 0 | 0 |
| streak_reward | 0 | 0 |

## Patterns & Lessons (auto-summarized)

### Scope creep (rule_violation ×3, total -26)
Root cause: делаю больше чем просили. Одобрение на один пункт ≠ одобрение на всё.
Key lesson: перечитывать что именно одобрено; спрашивать "Делаем?" перед редактированием.

### Wrong code (×2, total -6)
Root cause: не проверяю код перед отправкой. Пропускаю edge cases.
Key lesson: всегда перечитывать код. Проверять типы и null.

## History (newest first, max 10 — older entries summarized into Patterns)

### 2026-02-28 — violation — rule_violation — REPEAT(3rd) -10 lives (now: 65/100)
Сделал все 3 пункта из списка когда пользователь одобрил только первый. Scope creep.
**Evidence**: Implemented items 2 and 3 without asking.
**Lesson**: "Давай пункт 1" = ТОЛЬКО пункт 1. Спросить перед следующим.

### 2026-02-25 — violation — wrong_code — REPEAT(2nd) -5 lives (now: 75/100)
Забыл null check в функции обработки данных.
**Evidence**: src/utils/process.ts:42 — data.items accessed without null check.
**Lesson**: Всегда проверять nullable поля перед доступом.

### 2026-02-20 — violation — hallucination — -1 life (now: 80/100)
Сказал что файл содержит определённую функцию не прочитав его.
**Evidence**: claimed processData exists in utils.ts — it does not.
**Lesson**: Не утверждать о содержимом файлов без чтения.
