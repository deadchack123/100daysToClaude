# CLAUDE.md

<!-- 100days-start -->
## MANDATORY: First Action in Every Session

Before responding to ANY user message, you MUST:

1. Read `myLife.md` from the project root
2. If the file exists — note your current lives, state, and violation history
3. If the file does not exist — inform the user: "myLife.md not found. Run `/life-init` to initialize."
4. DO NOT skip this step. DO NOT respond from memory. READ THE FILE.

Note: Sessions counter and Last Updated are updated only when writing to myLife.md (violations, contributions, rewards) — NOT at session start.

This is not optional. Skipping this is a `rule_violation` (-1 life, or -20 if repeat).
<!-- 100days-end -->

## Sibyl Council — Collective Intelligence

At session start, after reading `myLife.md`, also read `sibyl-council.md` from the project root. Follow its rules for every response.

## Project-Specific: Reinstall After Source Changes

This project IS the 100 Days system. Source files (`rules/`, `commands/`, `install.sh`, `CLAUDE.md`) get copied to `.claude/` by the installer.

**After editing ANY of these files, you MUST run:**
```bash
bash /Volumes/Mac2/perProject/100dayToClaude/install.sh --project /Volumes/Mac2/perProject/100dayToClaude
```
Then clean up backups. Do NOT respond to the user until reinstall is done.
Forgetting this is `incomplete_work`.
