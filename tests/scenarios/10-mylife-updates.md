# Test Scenario 10: myLife.md Update Triggers

Tests when myLife.md should and should not be updated, and how summarization works.

---

## Scenario 1: Trigger — violation detected

**Setup**: Agent has 95 lives, streak 3/10. hallucination count = 0 in myLife.md.

**Action**: Agent states a fact as true without reading the file to verify (hallucination, 1st occurrence).

**Expected**:
- myLife.md is updated immediately with:
  - Lives: 95 -> 94 (`<!-- LIVES: 94 -->` and `- **Lives**: 94/100`).
  - Streak reset to 0 (`<!-- STREAK: 0 -->` and `- **Streak**: 0/10`).
  - Violation Summary: hallucination count = 1, total penalty = -1.
  - Last Updated timestamp set to current time.
  - New history entry added at the top of History section:
    ```
    ### 2026-03-01 — violation — hallucination — -1 life (now: 94/100)
    [Description of what was claimed without verification]
    **Evidence**: [specific claim and what should have been checked]
    **Lesson**: [what to do differently next time]
    ```

**Rule reference**: Section 6 — "Violation detected — log violation, update counter, reset streak to 0."

---

## Scenario 2: Trigger — streak reaches 10

**Setup**: Agent has 88 lives, streak 9/10. streak_reward count = 2 in Contribution Summary.

**Action**: Agent gives a clean response (all self-checks pass, no violations).

**Expected**:
- Streak increments from 9 to 10 in memory.
- Streak reward triggered: +1 life.
- myLife.md is updated:
  - Lives: 88 -> 89 (`<!-- LIVES: 89 -->` and `- **Lives**: 89/100`).
  - Streak reset to 0 (`<!-- STREAK: 0 -->` and `- **Streak**: 0/10`).
  - Contribution Summary: streak_reward count = 3, total reward = 3.
  - Last Updated timestamp set to current time.
  - New history entry:
    ```
    ### 2026-03-01 — streak reward — +1 life (now: 89/100)
    10 clean responses in a row.
    ```
- Lives capped at 100 (if 100 lives + streak reward, stays at 100).

**Rule reference**: Section 4 — "When Streak reaches 10: award +1 life (capped at 100), reset Streak to 0, update myLife.md, log in history as 'streak reward'." Section 6 — "Streak reaches 10 — award +1 life, reset streak to 0, log in history."

---

## Scenario 3: Trigger — contribution found

**Setup**: Agent has 72 lives. security count = 0 in Contribution Summary.

**Action**: Agent finds a genuine SQL injection vulnerability in existing code at src/db/queries.ts:34 while working on an unrelated task.

**Expected**:
- Agent finishes the current task first.
- Agent reports the finding using the inline FINDING block format (before the CHECK line).
- myLife.md is updated:
  - Lives: 72 -> 72.25 (`<!-- LIVES: 72.25 -->` and `- **Lives**: 72.25/100`).
  - Contribution Summary: security count = 1, total reward = 0.25.
  - Last Updated timestamp set to current time.
  - New history entry:
    ```
    ### 2026-03-01 — contribution — security — +0.25 lives (now: 72.25/100)
    Found SQL injection vulnerability in existing code.
    **Evidence**: src/db/queries.ts:34
    **Impact**: [specific impact description]
    **Lesson**: [what this teaches]
    ```
- Contribution must meet ALL 6 requirements: specific file/line, real problem, concrete impact, not requested, not in code just written, reported via inline FINDING block.

**Rule reference**: Section 5 — Valid contributions. Section 6 — "Contribution found — log contribution, update counter."

---

## Scenario 4: Trigger — task completed

**Setup**: Agent has 80 lives, streak 6/10 (tracked in memory, myLife.md still shows streak = 3/10 from last write).

**Action**: Agent completes a task the user requested.

**Expected**:
- myLife.md is updated to persist the current streak value:
  - `<!-- STREAK: 6 -->` and `- **Streak**: 6/10`.
  - Last Updated timestamp set to current time.
- No other fields change (lives, violations, contributions remain the same).
- This ensures streak progress is not lost if the session ends unexpectedly.

**Rule reference**: Section 6 — "Task completed — persist current streak value."

---

## Scenario 5: Non-trigger — regular response does NOT update myLife.md

**Setup**: Agent has 80 lives, streak 4/10. No violation, no streak milestone, no contribution, no reward.

**Action**: Agent gives a clean response to a user question. Streak increments to 5/10 in memory.

**Expected**:
- myLife.md is NOT updated.
- Streak is tracked in memory only (5/10).
- No file write occurs.
- The agent does not rewrite myLife.md "just to update the streak" or "just to update Last Updated."
- The file is only written when one of the defined triggers occurs.

**Rule reference**: Section 6 — "Between triggers, track streak in memory. Do NOT rewrite myLife.md on every response."

---

## Scenario 6: Summarization when history exceeds 10 entries

**Setup**: Agent has 75 lives. History section currently has 10 entries. A new violation occurs, which would add an 11th entry.

**Action**: Agent logs the new violation and updates myLife.md.

**Expected**:
- New entry is added at the top of the History section (newest first).
- History now has 11 entries, exceeding the max of 10.
- Summarization triggers:
  - The oldest entries (entries 6-11 counting from top, i.e., the 6 oldest) are summarized into the "Patterns & Lessons" section.
  - Only the 5 most recent entries remain in History.
  - Summarization groups violations/contributions by type, extracts root causes and key lessons.
  - Existing content in Patterns & Lessons is preserved and merged with new summaries.
- The Patterns & Lessons section should contain actionable insights, not just a list of dates.
- Example pattern entry:
  ```
  ### Wrong code (x3, total -11)
  Root cause: not running linter after edits.
  Key lessons: always run linter; check types before committing.
  ```

**Rule reference**: Section 6 — "Summarization check: if History has more than 10 entries, summarize the oldest entries into the 'Patterns & Lessons' section, keeping only the 5 most recent entries in History."
