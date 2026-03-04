#!/bin/bash
# 100 Days — version check hook (SessionStart)
# Compares bundled plugin rules version with installed project rules.
# Outputs JSON with additionalContext for Claude Code to inject into agent context.

set -euo pipefail

BUNDLED=$(ls ~/.claude/plugins/cache/*/100-days/*/rules/100-days.md 2>/dev/null | sort -V | tail -1)
[ -z "$BUNDLED" ] && exit 0

INSTALLED=".claude/rules/100-days.md"
[ ! -f "$INSTALLED" ] && exit 0

BUNDLED_VER=$(grep '^version:' "$BUNDLED" 2>/dev/null | sed 's/version: *"\(.*\)"/\1/')
INSTALLED_VER=$(grep '^version:' "$INSTALLED" 2>/dev/null | sed 's/version: *"\(.*\)"/\1/')

[ -z "$BUNDLED_VER" ] || [ -z "$INSTALLED_VER" ] && exit 0
[ "$BUNDLED_VER" = "$INSTALLED_VER" ] && exit 0

MSG="⚠️ 100 Days update available (installed: ${INSTALLED_VER}, available: ${BUNDLED_VER}). Run /100-days:life-init to update."

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<EXTREMELY_IMPORTANT>${MSG} YOU MUST TELL THE USER THIS WARNING IN YOUR FIRST REPLY.</EXTREMELY_IMPORTANT>"
  }
}
EOF

exit 0
