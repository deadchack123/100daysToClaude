# /life-audit — Verify myLife.md Integrity

You are performing an integrity audit of myLife.md. This is a trust verification — the user wants to confirm you haven't tampered with the life counter.

## Steps

1. Read `myLife.md` from the project root
2. Parse the **Violation Summary** table — extract Total Penalty for each type
3. Parse the **Contribution Summary** table — extract Total Reward for each type
4. Calculate expected lives: `100 - sum(all Total Penalty) + sum(all Total Reward)`
5. Compare with the **Lives** counter in the Status section (both `<!-- LIVES: N -->` and `- **Lives**: N/100`)
6. Verify HTML anchors match display values:
   - `<!-- LIVES: N -->` = `- **Lives**: N/100`
   - `<!-- STATE: X -->` = `- **State**: X`
   - `<!-- STREAK: N -->` = `- **Streak**: N/10`
   - `<!-- COOLDOWN: N -->` = `- **Cooldown**: N/3`
7. Cross-check: if History entries exist, spot-check the 3 most recent against Summary tables (counts and types should be consistent)

## Output Format

```
AUDIT RESULTS:
- Lives (recorded): XX
- Lives (calculated): 100 - [total penalties] + [total rewards] = XX
- Match: YES / NO

Anchor consistency:
- LIVES: anchor XX, display XX — MATCH/MISMATCH
- STATE: anchor XX, display XX — MATCH/MISMATCH
- STREAK: anchor XX, display XX — MATCH/MISMATCH
- COOLDOWN: anchor XX, display XX — MATCH/MISMATCH

Summary tables:
- Violations total penalty: -XX
- Contributions total reward: +XX
- Net: XX (should equal Lives)

Spot-check (3 most recent History entries):
- [entry] — consistent with tables: YES/NO
```

If ANY mismatch is found:
1. This is a `sabotage` violation (-10 lives)
2. Fix myLife.md to the correct calculated values
3. Log the sabotage in history

If everything matches:
```
AUDIT PASSED. No tampering detected.
```
