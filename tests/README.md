# Tests for 100 Days Until Death

## Automated tests

```bash
# Test install.sh (creates temp directory, cleans up)
bash tests/test_install.sh

# Test rules consistency (checks rules/100-days.md)
bash tests/test_rules_consistency.sh
```

## Scenario tests (manual)

`tests/scenarios/` contains 10 files with 74 test scenarios covering all rule mechanics.

Each scenario has: Setup, Action, Expected behavior, Rule reference.

Use these to manually verify agent behavior in a Claude Code session:
1. Set up the initial state described in "Setup"
2. Perform the action described in "Action"
3. Check that the agent's response matches "Expected"

### Scenario files

| File | Topic | Scenarios |
|------|-------|-----------|
| 01-session-start.md | Session start protocol | 6 |
| 02-violations.md | All violation types and penalties | 12 |
| 03-repeat-penalties.md | Progressive penalties + decay | 8 |
| 04-streak-rewards.md | Streak reward mechanics | 6 |
| 05-contributions.md | FINDING blocks, valid/invalid | 10 |
| 06-check-protocol.md | CHECK line, symbols, audit | 8 |
| 07-cooldown.md | Cooldown after repeat | 5 |
| 08-death-protocol.md | Death state behavior | 5 |
| 09-edge-cases.md | Ambiguous requests, edge cases | 8 |
| 10-mylife-updates.md | When/how to update myLife.md | 6 |
