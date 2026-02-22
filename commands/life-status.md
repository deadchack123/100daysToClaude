---
allowed-tools: Read, Glob
argument-hint:
description: Show current life status from myLife.md
---

# /life-status — Display Life Status

Read `myLife.md` from the project root and display a concise status report.

## What to show

### 1. Status Banner

Format based on life count:
- **90-100 lives**: "HEALTHY [lives]/100"
- **50-89 lives**: "WARNING [lives]/100 — be careful"
- **10-49 lives**: "CRITICAL [lives]/100 — one mistake away from death spiral"
- **1-9 lives**: "TERMINAL [lives]/100 — extreme danger"
- **0 lives**: "DEAD — permanently. Delete myLife.md to start over."

### 2. Quick Stats

Show in a compact format:
- Lives remaining
- Total violations (count)
- Total contributions (count)
- Net balance (contributions - violations)
- Sessions tracked

### 3. Top Violation Types

List the top 3 violation types by count. Highlight any that have repeat penalties.

### 4. Recent History

Show the last 5 history entries (newest first).

### 5. Risk Assessment

Based on patterns:
- If any violation type has count = 1: "WARNING: [type] — next repeat = -5."
- If any violation type has count = 2: "DANGER: [type] — next repeat = -10."
- If any violation type has count >= 3: "HIGH RISK: [type] — next repeat = -20."
- If contributions > violations: "POSITIVE TREND: More good finds than mistakes."
- If lives dropped more than 10 in last 3 sessions: "DECLINING: Losing lives fast."

## If myLife.md doesn't exist

Say: "No myLife.md found. Run `/life-init` to initialize the 100 Days system."
