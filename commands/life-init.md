---
allowed-tools: Bash, Read, Grep, Glob, Write, Edit
argument-hint: [project-path]
description: Initialize 100 Days system in a project
---

# /life-init — Initialize 100 Days Until Death

Set up the 100 Days accountability system in this project: install rules, inject CLAUDE.md section, create myLife.md.

## Phase 1: Install Rules from Plugin (if applicable)

If 100 Days is installed as a Claude Code plugin, copy rules into the project.

### Step 1: Detect plugin installation

Use Bash to find the bundled rules file:
```bash
ls ~/.claude/plugins/cache/*/100-days/*/rules/100-days.md 2>/dev/null | sort -t/ -k8 -V | tail -1
```

- If the command returns a path — this is a plugin install. Continue with Phase 1.
- If the command returns nothing — this is a manual install (install.sh). Skip to Phase 2.

### Step 2: Copy rules

Use Bash to copy the bundled rules file into the project. This is a **full replacement** — do NOT read, diff, or merge. Just copy:
```bash
mkdir -p .claude/rules && cp "BUNDLED_PATH" .claude/rules/100-days.md
```
(replace `BUNDLED_PATH` with the path from Step 1)

Then read the version from the copied file and inform the user: "Rules installed (vX.Y.Z)."

### Step 3: Inject CLAUDE.md section

The managed section is bounded by markers `<!-- 100days-start -->` and `<!-- 100days-end -->`.

The content to inject:
```markdown
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
```

Check if `CLAUDE.md` exists in the project root:
- If it doesn't exist — create it with `# CLAUDE.md` header followed by the managed section.
- If it exists — check for the markers:
  - If both `<!-- 100days-start -->` and `<!-- 100days-end -->` markers are present — replace everything between them (inclusive) with the new managed section.
  - If markers are not present — append the managed section to the end of the file.

Inform the user what was done ("CLAUDE.md created" / "CLAUDE.md updated" / "CLAUDE.md section appended").

## Phase 2: Register plugin marketplace in project settings

Add the 100 Days marketplace to `.claude/settings.json` so Claude Code auto-discovers the plugin for future updates.

### Step 1: Read or create `.claude/settings.json`

Use Bash to check if the file exists:
```bash
cat .claude/settings.json 2>/dev/null || echo "{}"
```

### Step 2: Merge marketplace config

Parse the existing JSON. Add (or overwrite) these keys, preserving all other existing settings:

```json
{
  "extraKnownMarketplaces": {
    "100days-marketplace": {
      "source": {
        "source": "github",
        "repo": "deadchack123/100daysToClaude"
      }
    }
  },
  "enabledPlugins": {
    "100-days@100days-marketplace": true
  }
}
```

- If `extraKnownMarketplaces` already has other entries — keep them, add ours.
- If `enabledPlugins` already has other entries — keep them, add ours.
- Do NOT remove or overwrite any existing keys.

Write the merged result back to `.claude/settings.json`.

Inform the user: "Plugin marketplace registered in project settings."

## Phase 3: Initialize myLife.md

If `myLife.md` already exists — inform the user and skip. Do NOT overwrite existing state.

If it doesn't exist:

1. Create `myLife.md` in the project root with the template from the 100-days rule (Section 7)
2. Set the Created and Last Updated timestamps to now
3. Inform the user: "100 Days Until Death initialized. You have 100 lives. The game begins now."
