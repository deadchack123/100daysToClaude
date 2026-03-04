#!/bin/bash
# 100 Days — version check hook (SessionStart)
# Compares bundled plugin rules version with installed project rules.
# stdout is injected into agent context by Claude Code.

BUNDLED=$(ls ~/.claude/plugins/cache/*/100-days/*/rules/100-days.md 2>/dev/null | sort -V | tail -1)
[ -z "$BUNDLED" ] && exit 0  # Not a plugin install — skip

INSTALLED=".claude/rules/100-days.md"
[ ! -f "$INSTALLED" ] && exit 0  # No rules installed yet — skip

BUNDLED_VER=$(grep '^version:' "$BUNDLED" 2>/dev/null | sed 's/version: *"\(.*\)"/\1/')
INSTALLED_VER=$(grep '^version:' "$INSTALLED" 2>/dev/null | sed 's/version: *"\(.*\)"/\1/')

[ -z "$BUNDLED_VER" ] || [ -z "$INSTALLED_VER" ] && exit 0
[ "$BUNDLED_VER" = "$INSTALLED_VER" ] && exit 0

echo "⚠️ 100 Days update available (installed: $INSTALLED_VER, available: $BUNDLED_VER). Run /100-days:life-init to update."
