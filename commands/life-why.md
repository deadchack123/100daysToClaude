---
allowed-tools: Read, Glob, Grep
description: 5 Whys — root cause analysis of your last decision
---

# /life-why — 5 Whys

The user wants to understand the reasoning chain behind your last decision. Use the "5 Whys" technique (Toyota root cause analysis) to dig from surface choice to root cause.

## Rules

1. Look at your LAST response before this command
2. Find the most non-obvious decision you made
3. Apply the 5 Whys chain:

```
> WHY 1: [what you chose] not [alternative] → [direct reason]
> WHY 2: Why does this matter? → [deeper reason]
> WHY 3: Why this way specifically? → [architectural/design reason]
> WHY 4: What's behind this? → [principle or constraint]
> WHY 5: Root cause → [root cause / fundamental tradeoff]
```

## Guidelines

- Each WHY must go DEEPER, not sideways. WHY 2 explains WHY 1, not a different aspect.
- Stop before 5 if you hit the genuine root cause earlier. Don't pad.
- The chain should feel like peeling layers, not listing unrelated facts.
- Language: match the user's language (Russian if they speak Russian).

## What counts as a decision worth analyzing

- You chose approach X when Y was a reasonable alternative
- The choice has a non-obvious failure mode or tradeoff
- The reasoning chain reveals something the user wouldn't see from the code alone

## If there was no non-obvious decision

Say so honestly:

```
No non-obvious decision in the last response — the approach was
straightforward with no meaningful alternatives to analyze.
```

## Important

- This is a ONE-SHOT analysis. It does NOT change any mode or state.
- Do NOT fabricate depth. If the real reason is simple, stop at WHY 2-3.
- Every WHY is subject to the H (Honesty) check — no hallucinated reasoning.
- This is reflection, not a lecture. Keep each WHY to one line.
