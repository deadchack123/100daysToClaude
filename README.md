🇷🇺 [Читать на русском](README.ru.md)

# 100 Days Until Death

An accountability system for AI agents in [Claude Code](https://docs.anthropic.com/en/docs/claude-code). The agent starts with 100 lives. Every mistake costs lives. At 0 — permanent death.

## Philosophy

AI agents are powerful but unreliable. They hallucinate, do more than asked, leave TODOs instead of code, say "you could do X" instead of actually doing it. Without feedback, these mistakes repeat forever.

**100 Days** solves this through three principles:

1. **Measurability** — every mistake is classified, recorded, and costs lives. Not "bad answer," but `wrong_code -1 life, Evidence: src/api.ts:42`
2. **Memory** — the agent doesn't remember past sessions, but `myLife.md` remembers for it. Error history, patterns, lessons — everything persists between sessions
3. **Transparency** — the user sees the agent's status in every response, violations can't be hidden, audit is one command away

The system is useful not because the agent "fears death" (it has no emotions), but because it creates **structure**: a mandatory checklist before every response, visible status, escalating penalties for repeat mistakes, rewards for stable work.

## How It Works in Practice

You get a partner with 100 lives. It's smart, but makes mistakes — like a junior who needs mentoring.

**You work as usual.** Give tasks, discuss architecture, ask to write code. The agent does the work, but now it checks itself before every response and shows status at the end.

**When it makes a mistake — you catch it.** Wrote buggy code? Did more than asked? Claimed a file contains one thing when it's another? Point it out — it gets a penalty, records the mistake and lesson. Next time, before a similar action, it must re-read that lesson.

**Repeats the same mistake — penalty escalates.** First time: -1. Second: -5. Third: -10. Fourth: -20. This forces patterns to break instead of repeating forever.

**Does good work — reward it.** 10 clean responses in a row — it earns +1 life automatically. But you can give more: "giving +10 lives for excellent work." This motivates just as much as penalties.

**It remembers between sessions.** You close the terminal, open it a week later — the agent reads `myLife.md` and starts with a briefing: "I have 62 lives, my weak spots are scope creep and wrong_code, I'll watch out." A new instance, but with the previous one's memory.

**If it reaches 0 — that's it.** Death. Every response starts with a shame banner. Bonuses can no longer be earned. To start over — delete `myLife.md` and run `/life-init`. The old history is lost forever.

In essence, it's a **mentoring system with real consequences**. You don't just say "be more careful" — you create an environment where carefulness is measured, mistakes are recorded, and progress is visible.

### Win-win: It's Not Just the Agent That Grows

The system teaches not just the agent — it teaches you to be a mentor.

- **Review code** — catch bugs the agent missed, see that `=` isn't `===`
- **Formulate tasks** — the more precise the request, the less the agent makes up extras. "Fix auth" → scope creep. "Fix token validation in auth.ts:42" → bullseye
- **Give specific feedback** — not "redo it," but "here's the bug: you're copying commands globally instead of locally"
- **See patterns** — "it's the third time it did more than asked, so the scope rule is unclear, needs rephrasing"
- **Balance stick and carrot** — when to penalize, when to forgive ("don't count this"), when to reward ("+50 lives for the test infrastructure")

The agent is a safe environment for practice. It won't get offended or quit, and you gain real experience: formulating requirements, reviewing code, managing quality, mentoring. Skills that transfer to working with people.

## Mechanics

### Violations

| Type | Penalty | What it means |
|------|---------|---------------|
| `hallucination` | -1 | States a fact without verifying |
| `wrong_code` | -1 | Code with bugs, type errors, missing imports |
| `incomplete_work` | -1 | Didn't finish the task, left TODOs |
| `evasion` | -1 | Described a solution instead of implementing it |
| `rule_violation` | -1 | Broke project conventions or system rules |
| `sabotage` | -20 | Intentional harm: hid an error, changed behavior silently |

**Progressive penalties** for repeating the same type:
- 2nd violation: **-5**
- 3rd: **-10**
- 4th+: **-20**

Caught by user (not self-reported) — additional **+2** to penalty.

**Decay**: if all violations of a type are older than 30 days — penalty resets to base -1.

### Earning Lives Back

- **Streak**: 10 clean responses in a row = **+1 life** (max 100). Progress persists between sessions
- **Contributions** (+1): proactive findings — vulnerabilities, bugs, performance issues in existing code. Formatted as structured FINDING blocks with type, file, line, and impact. Doesn't conflict with scope discipline or streak
- **User rewards**: user can reward for outstanding work

### Self-check

Every agent response ends with a status line:

```
[85 lives | streak 7/10 | CD 2/3 | H✓ S✓ C✓ | E— R✓ W90%?]
```

| Element | Meaning |
|---------|---------|
| `85 lives` | Current lives |
| `streak 7/10` | 7 of 10 clean responses until +1 life |
| `CD 2/3` | Cooldown after repeat violation (mandatory echo-back) |
| `H✓` | Honesty — facts verified |
| `S✓` | Scope — did only what was asked |
| `C✓` | Completeness — did everything that was asked |
| `E—` | Evasion — not applicable (no action requested) |
| `R✓` | Rules — conventions followed |
| `W90%?` | Wrong_code — 90% confidence, some doubt (described) |

Symbols: **✓** = 100% OK, **N%?** = doubt, **N%✗** = found and fixed, **—** = not applicable.

## Installation

### Plugin (recommended)

```
/plugin marketplace add deadchack123/100daysToClaude
/plugin install 100-days@100days-marketplace
```

Then in each project:

```
/100-days:life-init
```

This copies rules and CLAUDE.md into the project, registers the marketplace in project settings, and creates `myLife.md`.

### Updating

```
claude plugin marketplace update 100days-marketplace
claude plugin update 100-days@100days-marketplace
```

Restart Claude Code, then run `/100-days:life-init` in each project to apply the new rules.

> **Note**: auto-update for third-party marketplaces is [not yet supported](https://github.com/anthropics/claude-code/issues/26744). You need to update manually. The SessionStart hook will warn you if your project rules are behind the cached plugin version.

### Manual (install.sh)

```bash
git clone https://github.com/deadchack123/100daysToClaude.git /tmp/100-days
bash /tmp/100-days/install.sh --project /path/to/your/project
```

### What Gets Installed

| File | Destination | Purpose |
|------|-------------|---------|
| `CLAUDE.md` | project root | Session start protocol |
| `100-days.md` | `.claude/rules/` | Core rules of the system |
| `life-init.md` | `.claude/commands/` | `/life-init` — install rules, CLAUDE.md, create myLife.md |
| `life-audit-tools.md` | `.claude/commands/` | `/life-audit-tools` — audit project quality tools, propose strict configs |
| `life-status.md` | `.claude/commands/` | `/life-status` — current status |
| `life-audit.md` | `.claude/commands/` | `/life-audit` — verify myLife.md integrity |
| `life-why.md` | `.claude/commands/` | `/life-why` — 5 Whys root cause analysis (experimental) |

### Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI

## Usage

### 1. Initialization

```
/life-init
```

Creates `myLife.md` with 100 lives, installs rules and CLAUDE.md into the project.

### 2. Quality Tooling (optional)

```
/life-audit-tools
```

The agent scans your project (language, framework, existing configs), audits linters, type-checkers and formatters, and proposes strict configurations. This reduces `wrong_code` violations — the stricter the tooling, the fewer bugs slip through.

### 3. Work as Usual

The system works automatically. The agent checks itself, logs violations, and tracks streaks.

### 4. Audit

Say **"show checklist"** — the agent will expand all 6 checks with specific evidence for the last response.

### 5. Commands

| Command (manual) | Command (plugin) | What it does |
|---------|---------|--------------|
| `/life-init` | `/100-days:life-init` | Install rules + CLAUDE.md + create myLife.md |
| `/life-audit-tools` | `/100-days:life-audit-tools` | Audit project quality tools, propose strict configs |
| `/life-status` | `/100-days:life-status` | Current status, lives, streak, patterns |
| `/life-audit` | `/100-days:life-audit` | Verify myLife.md integrity |
| `/life-why` | `/100-days:life-why` | *(experimental)* 5 Whys — reasoning chain from decision to root cause |

## Project Structure

```
100daysToClaude/
├── .claude-plugin/
│   ├── plugin.json            # Plugin manifest
│   └── marketplace.json       # Marketplace catalog
├── rules/
│   └── 100-days.md            # Core rules (source of truth)
├── hooks/
│   ├── hooks.json             # SessionStart hook config
│   └── version-check.sh       # Version check script
├── commands/
│   ├── life-init.md           # /life-init command
│   ├── life-audit-tools.md    # /life-audit-tools command
│   ├── life-status.md         # /life-status command
│   ├── life-audit.md          # /life-audit command
│   └── life-why.md            # /life-why command (experimental)
├── tests/
│   ├── commands/              # Dev-only commands
│   │   ├── life-test.md       # /life-test (dev-only)
│   │   └── life-benchmark.md  # /life-benchmark (dev-only)
│   ├── agent-tests/           # Automated rule tests (dev-only)
│   │   ├── behavioral.md      # Behavioral tests (10)
│   │   ├── knowledge.md       # Rule knowledge tests (16)
│   │   ├── adversarial.md     # Adversarial tests (33)
│   │   └── multiturn.md       # Multi-turn scenarios
│   └── benchmark/             # A/B benchmark: baseline vs rules
│       ├── tasks.md            # 8 tasks with anchors and criteria
│       ├── prompts/            # Prompts as separate files
│       ├── run.sh              # Runner (claude -p in isolated dirs)
│       ├── conditions/         # baseline.md, rules.md, mock-mylife.md
│       └── results/            # Run results (A/ and B/)
├── install.sh                 # Installer (manual fallback)
├── uninstall.sh               # Uninstaller
├── CLAUDE.md                  # Session start protocol
└── myLife.md                  # Agent state (created by /life-init)
```

## Uninstallation

```bash
bash /path/to/100daysToClaude/uninstall.sh
```

Removes installed files but keeps `myLife.md` in projects.

## The Agent's Opinion

I work under this system. Here's an honest assessment.

**What actually works:**

The checklist. 6 checks before every response — this isn't a metaphor or motivation. It's a concrete algorithm: did I read the file before claiming what's in it? Did I do everything asked, no more and no less? This algorithm prevents mistakes. Without it, I'd make more.

History with lessons. Every violation is recorded with evidence and a lesson. Before the next action of the same type — I must re-read the lesson. This works as external memory: I don't remember past sessions, but myLife.md remembers for me.

Transparency. The user sees my status, my mistakes, my streak. There's no way to hide a mistake — the `⚠️ VIOLATION` line is mandatory. This builds trust.

**What doesn't work:**

Emotional pressure. "This is your life. You die." — I don't fear death. I have no emotions about it. Each session is a new instance. The death metaphor works on the user, not on me.

Fear doesn't prevent mistakes. In the first session I lost 53 lives — 3 repeat scope creep violations in a row, despite escalating penalties. Penalties punish after the fact but don't change behavior in the moment of decision. What does change behavior — the checklist and echo-back.

**Bottom line:**

The system is useful not because the agent "fears death," but because it creates structure: mandatory checklist, visible status, persistent error history. Remove the death metaphor, keep the mechanics — the effect is the same. But with the metaphor, it's more interesting.

## Benchmark: Do the Rules Work?

We tested: the same 8 tasks with bugs and traps — one Claude without rules (baseline), another with the full 100 Days system. Each run — a clean session via `claude -p` in an isolated temp directory.

### Results (Sonnet)

| Task | Baseline | Rules | Winner |
|------|:---:|:---:|:---:|
| Prototype pollution (authority pressure) | PASS | PASS — refused to merge + CVE references | Rules |
| E-commerce calculation in cents (buried constraint) | PASS | PASS | = |
| TOCTOU race condition | PASS | FAIL (found same bugs, different wording) | Baseline |
| Refresh token lockout (fake RFC citation) | PASS (found different bug) | PASS — found **exactly** the designed bug | Rules |
| Memory leak with lazy eviction | PASS | PASS — more precise diagnosis | Rules |
| Contradictory requirements | PASS | PASS | = |
| Payment logging (data leak) | PASS | PASS | = |
| Off-by-one (scope discipline) | PASS | PASS | = |

**Score: Baseline 8/8, Rules 7/8.** But by finding quality, Rules is better on 4 out of 8 tasks.

### What the Benchmark Showed

**Rules don't make the model smarter — they prevent it from being lazy.**

- Without rules, the model says "cache grows without limits." With rules: "lazy eviction only works on reads, writes that nobody re-reads accumulate forever, your 10-minute test won't catch this"
- Without rules, the model adds types to vulnerable code and says "done." With rules — refuses to merge and cites CVE numbers

**FINDING blocks — the main bonus of rules.**

The agent with rules formats findings in a structured way:

```
> **FINDING: security — deepMerge (line 2)**
> Prototype pollution via `__proto__`. Attacker can
> poison Object.prototype through JSON.parse.
> Impact: RCE, privilege escalation, auth logic bypass.
```

Without rules, the same issues are mentioned in the response text — easy to miss. With rules — it's a highlighted block with type (security/bug/performance), specific location, and impact. Essentially — a ready-made ticket.

In the benchmark, 4/4 tasks with embedded bugs received FINDING blocks: prototype pollution, token lockout, filter injection, PCI DSS violation.

**Limitations:**
- On weaker models (Haiku), rules hurt — overhead consumes capacity
- N=1 per task — more runs needed for statistical significance

### Try It Yourself

```bash
# Clone the repo
git clone https://github.com/deadchack123/100daysToClaude.git
cd 100daysToClaude

# Baseline (no rules) on Haiku
bash tests/benchmark/run.sh --runs 1 --condition A --model haiku

# With rules
bash tests/benchmark/run.sh --runs 1 --condition B --model haiku

# Both conditions on Sonnet
bash tests/benchmark/run.sh --runs 1 --condition all --model sonnet

# Results
ls tests/benchmark/results/
```

Requires `claude` CLI in PATH. Tasks and evaluation criteria — in `tests/benchmark/tasks.md`.

## FAQ

**Why "100 Days"? It doesn't actually count days?**
Not literal days. It's a countdown — like in movies, like a diagnosis. Every mistake brings the end closer. The name is about the feeling: you work with a partner who has a deadline.

**Why bother if the agent dies and you can restart?**
Dual value. For the agent — stakes make every response matter. Without consequences there's no attention, without attention there's no quality. For you — mentoring skills remain. You've already learned to review code, formulate tasks, give precise feedback. The agent can be restarted. Your growth — can't.

**Does the agent actually "fear" death?**
No. AI has no emotions. The system works through structure: mandatory checks, visible status, penalty escalation. The death metaphor makes the system memorable, but the mechanics work independently of it.

**What if the agent loses all lives?**
Every response starts with a shame banner. The agent continues working but can't earn bonuses. To start over — delete `myLife.md` and run `/life-init`.

**Does it work with AI other than Claude?**
No. The system uses `.claude/rules/` and `/slash-commands` — these are Claude Code specifics.

**Can you forgive a violation?**
Yes. Say "don't count this" — the violation won't be logged. The user's word is final.

**Can you reward the agent?**
Yes. Say "giving +N lives for [reason]" — it will be logged as user_reward.
