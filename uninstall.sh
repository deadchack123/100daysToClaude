#!/bin/bash
# 100 Days Until Death — Uninstaller
#
# Usage:
#   bash uninstall.sh                          # Global uninstall (~/.claude/)
#   bash uninstall.sh --project /path/to/project  # Per-project uninstall
#
# Does NOT touch myLife.md (that's user data)
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# ─── Parse arguments ─────────────────────────────────────────

MODE="global"
PROJECT_DIR=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --project|-p)
      MODE="project"
      PROJECT_DIR="$2"
      shift 2
      ;;
    --help|-h)
      echo "Usage:"
      echo "  bash uninstall.sh                          # Global (~/.claude/)"
      echo "  bash uninstall.sh --project /path/to/project  # Per-project"
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown argument: $1${NC}"
      exit 1
      ;;
  esac
done

echo -e "${CYAN}"
echo '  ╔═══════════════════════════════════════╗'
echo '  ║     100 DAYS UNTIL DEATH              ║'
echo '  ║     Uninstaller                       ║'
echo '  ╚═══════════════════════════════════════╝'
echo -e "${NC}"

# ─── Global uninstall ─────────────────────────────────────────

CLAUDE_DIR="$HOME/.claude"

echo -e "${CYAN}Removing global files...${NC}"

# Remove rules
if [ -f "$CLAUDE_DIR/rules/100-days.md" ]; then
  rm "$CLAUDE_DIR/rules/100-days.md"
  echo -e "  ${RED}-${NC} ~/.claude/rules/100-days.md"
fi

# Remove commands
for cmd in "life-init.md" "life-status.md" "life-audit.md"; do
  if [ -f "$CLAUDE_DIR/commands/$cmd" ]; then
    rm "$CLAUDE_DIR/commands/$cmd"
    echo -e "  ${RED}-${NC} ~/.claude/commands/$cmd"
    if [ -f "$CLAUDE_DIR/commands/${cmd}.bak" ]; then
      mv "$CLAUDE_DIR/commands/${cmd}.bak" "$CLAUDE_DIR/commands/$cmd"
      echo -e "  ${GREEN}+${NC} Restored backup: ~/.claude/commands/$cmd"
    fi
  fi
done

# Remove hooks directory
if [ -d "$CLAUDE_DIR/hooks/100-days" ]; then
  rm -rf "$CLAUDE_DIR/hooks/100-days"
  echo -e "  ${RED}-${NC} ~/.claude/hooks/100-days/"
fi

# ─── Per-project uninstall ────────────────────────────────────

if [ "$MODE" = "project" ]; then
  if [ -z "$PROJECT_DIR" ] || [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}Error: valid project directory required${NC}"
    exit 1
  fi

  echo -e "${CYAN}Removing per-project files from $PROJECT_DIR...${NC}"

  TARGET_DIR="$PROJECT_DIR/.claude"

  if [ -f "$TARGET_DIR/rules/100-days.md" ]; then
    rm "$TARGET_DIR/rules/100-days.md"
    echo -e "  ${RED}-${NC} .claude/rules/100-days.md"
  fi

  if [ -d "$TARGET_DIR/hooks/100-days" ]; then
    rm -rf "$TARGET_DIR/hooks/100-days"
    echo -e "  ${RED}-${NC} .claude/hooks/100-days/"
  fi

  # Remove settings.local.json hook if present
  SETTINGS_FILE="$TARGET_DIR/settings.local.json"
  if [ -f "$SETTINGS_FILE" ] && command -v jq &>/dev/null; then
    HOOK_PATH=".claude/hooks/100-days/post-write-check.sh"
    HAS_HOOK=$(jq -r --arg path "$HOOK_PATH" '
      .hooks.PostToolUse // [] |
      map(.hooks // [] | map(select(.command == $path))) |
      flatten | length
    ' "$SETTINGS_FILE" 2>/dev/null || echo "0")

    if [ "$HAS_HOOK" != "0" ]; then
      TEMP_FILE=$(mktemp)
      jq --arg path "$HOOK_PATH" '
        if .hooks.PostToolUse then
          .hooks.PostToolUse = [
            .hooks.PostToolUse[] |
            .hooks = [.hooks[] | select(.command != $path)] |
            select(.hooks | length > 0)
          ] |
          if (.hooks.PostToolUse | length) == 0 then del(.hooks.PostToolUse) else . end |
          if (.hooks | length) == 0 then del(.hooks) else . end
        else . end
      ' "$SETTINGS_FILE" > "$TEMP_FILE"
      mv "$TEMP_FILE" "$SETTINGS_FILE"
      echo -e "  ${RED}-${NC} PostToolUse hook removed from settings.local.json"

      # Remove settings.local.json if empty
      REMAINING=$(jq 'length' "$SETTINGS_FILE" 2>/dev/null || echo "1")
      if [ "$REMAINING" = "0" ]; then
        rm "$SETTINGS_FILE"
        echo -e "  ${RED}-${NC} settings.local.json (was empty)"
      fi
    fi
  fi

  echo ""
  echo -e "${YELLOW}Note:${NC} CLAUDE.md was NOT modified. Remove the '## MANDATORY' section manually if needed."
fi

# ─── Done ─────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}Uninstall complete.${NC}"
echo ""
echo -e "${YELLOW}Note:${NC} myLife.md files in your projects were NOT removed."
echo "Delete them manually if you want to remove all traces."
