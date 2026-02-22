#!/bin/bash
# 100 Days Until Death — Installer
#
# Usage:
#   bash install.sh                              # Interactive — asks for project path
#   bash install.sh --project /path/to/project   # Per-project install (project/.claude/)
#   bash install.sh --global                     # Global install (~/.claude/) — use with caution
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# ─── Parse arguments ─────────────────────────────────────────

MODE=""
PROJECT_DIR=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --project|-p)
      if [ -z "${2:-}" ]; then
        echo -e "${RED}Error: --project requires a path argument${NC}"
        exit 1
      fi
      MODE="project"
      PROJECT_DIR="$2"
      shift 2
      ;;
    --global)
      MODE="global"
      shift
      ;;
    --help|-h)
      echo "Usage:"
      echo "  bash install.sh                              # Interactive (asks for project path)"
      echo "  bash install.sh --project /path/to/project   # Per-project install"
      echo "  bash install.sh --global                     # Global install (use with caution!)"
      echo ""
      echo "Per-project is recommended. Global installs rules into ALL Claude Code sessions."
      echo "Commands are installed to the same target as rules (project or global)."
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown argument: $1${NC}"
      echo "Use --help for usage"
      exit 1
      ;;
  esac
done

# If no mode specified, ask interactively
if [ -z "$MODE" ]; then
  echo -e "${CYAN}No install mode specified.${NC}"
  echo ""
  read -r -p "Enter project path (or 'global' for global install): " USER_INPUT
  if [ "$USER_INPUT" = "global" ]; then
    MODE="global"
  elif [ -d "$USER_INPUT" ]; then
    MODE="project"
    PROJECT_DIR="$USER_INPUT"
  else
    echo -e "${RED}Error: directory not found: $USER_INPUT${NC}"
    exit 1
  fi
fi

# ─── Set target directory ────────────────────────────────────

if [ "$MODE" = "project" ]; then
  if [ -z "$PROJECT_DIR" ]; then
    echo -e "${RED}Error: --project requires a path${NC}"
    exit 1
  fi
  if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}Error: directory not found: $PROJECT_DIR${NC}"
    exit 1
  fi
  TARGET_DIR="$PROJECT_DIR/.claude"
  DISPLAY_PREFIX="$PROJECT_DIR/.claude"
else
  TARGET_DIR="$HOME/.claude"
  DISPLAY_PREFIX="~/.claude"
fi

echo -e "${CYAN}"
echo '  ╔═══════════════════════════════════════╗'
echo '  ║     100 DAYS UNTIL DEATH              ║'
echo '  ║     Installer for Claude Code         ║'
echo '  ╚═══════════════════════════════════════╝'
echo -e "${NC}"

if [ "$MODE" = "project" ]; then
  echo -e "  Mode: ${GREEN}per-project${NC} → $PROJECT_DIR"
else
  echo -e "  Mode: ${YELLOW}global${NC} → ~/.claude/"
fi
echo ""

# ─── Pre-flight checks ───────────────────────────────────────

if [ "$MODE" = "global" ] && [ ! -d "$TARGET_DIR" ]; then
  echo -e "${RED}Error: ~/.claude/ directory not found.${NC}"
  echo "Is Claude Code installed? Run 'claude' first to initialize."
  exit 1
fi

# ─── Create directories ──────────────────────────────────────

echo -e "${CYAN}Creating directories...${NC}"

# Handle case where .claude/rules exists as a file (Claude Code sometimes creates it as a single file)
if [ -f "$TARGET_DIR/rules" ]; then
  echo -e "  ${YELLOW}!${NC} $DISPLAY_PREFIX/rules is a file, converting to directory..."
  RULES_FILE="$TARGET_DIR/rules"
  TEMP_RULES=$(mktemp)
  cp "$RULES_FILE" "$TEMP_RULES"       # 1. save copy to temp (original still exists)
  rm "$RULES_FILE"                      # 2. remove file (temp has the data)
  mkdir -p "$TARGET_DIR/rules"          # 3. create directory
  if ! mv "$TEMP_RULES" "$TARGET_DIR/rules/project-rules.md"; then
    echo -e "  ${RED}ERROR: Failed to move rules. Backup at: $TEMP_RULES${NC}"
    exit 1
  fi
  echo -e "  ${GREEN}+${NC} Moved existing rules to $DISPLAY_PREFIX/rules/project-rules.md"
fi

mkdir -p "$TARGET_DIR/rules"

if [ "$MODE" = "global" ]; then
  mkdir -p "$TARGET_DIR/commands"
fi

# ─── Create/update CLAUDE.md (per-project only) ─────────────

if [ "$MODE" = "project" ]; then
  CLAUDE_MD="$PROJECT_DIR/CLAUDE.md"
  START_MARKER="<!-- 100days-start -->"
  END_MARKER="<!-- 100days-end -->"

  # The managed block content
  MANAGED_BLOCK=$(cat << 'BLOCKEOF'
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
BLOCKEOF
)

  if [ ! -f "$CLAUDE_MD" ]; then
    echo -e "${CYAN}Creating CLAUDE.md...${NC}"
    printf "# CLAUDE.md\n\n%s\n" "$MANAGED_BLOCK" > "$CLAUDE_MD"
    echo -e "  ${GREEN}+${NC} $PROJECT_DIR/CLAUDE.md (created)"
  elif grep -q "$START_MARKER" "$CLAUDE_MD" && grep -q "$END_MARKER" "$CLAUDE_MD"; then
    echo -e "${CYAN}Updating CLAUDE.md managed section...${NC}"
    # Replace markers and content between them in-place
    TEMP_FILE=$(mktemp)
    in_block=false
    replaced=false
    while IFS= read -r line; do
      line="${line%$'\r'}"  # Strip trailing CR for Windows/CRLF line endings
      if [ "$line" = "$START_MARKER" ]; then
        in_block=true
        # Insert new block where old one was
        printf '%s\n' "$MANAGED_BLOCK"
        replaced=true
        continue
      fi
      if [ "$line" = "$END_MARKER" ]; then
        in_block=false
        continue
      fi
      if [ "$in_block" = false ]; then
        printf '%s\n' "$line"
      fi
    done < "$CLAUDE_MD" > "$TEMP_FILE"
    mv "$TEMP_FILE" "$CLAUDE_MD"
    echo -e "  ${GREEN}+${NC} $PROJECT_DIR/CLAUDE.md (updated managed section)"
  else
    echo -e "${CYAN}Appending to CLAUDE.md...${NC}"
    printf '\n%s\n' "$MANAGED_BLOCK" >> "$CLAUDE_MD"
    echo -e "  ${GREEN}+${NC} $PROJECT_DIR/CLAUDE.md (appended managed section)"
  fi
fi

# ─── Copy rules ──────────────────────────────────────────────

echo -e "${CYAN}Installing rules...${NC}"

# Version comparison
NEW_VERSION=$(grep '^version:' "$SCRIPT_DIR/rules/100-days.md" 2>/dev/null | sed 's/version: *"\(.*\)"/\1/' || true)
OLD_VERSION=""
if [ -f "$TARGET_DIR/rules/100-days.md" ]; then
  OLD_VERSION=$(grep '^version:' "$TARGET_DIR/rules/100-days.md" 2>/dev/null | sed 's/version: *"\(.*\)"/\1/' || true)
fi

cp "$SCRIPT_DIR/rules/100-days.md" "$TARGET_DIR/rules/100-days.md"

if [ -z "$NEW_VERSION" ]; then
  echo -e "  ${GREEN}+${NC} $DISPLAY_PREFIX/rules/100-days.md"
elif [ -z "$OLD_VERSION" ]; then
  echo -e "  ${GREEN}+${NC} $DISPLAY_PREFIX/rules/100-days.md (v${NEW_VERSION} — fresh install)"
elif [ "$OLD_VERSION" = "$NEW_VERSION" ]; then
  echo -e "  ${GREEN}+${NC} $DISPLAY_PREFIX/rules/100-days.md (v${NEW_VERSION} — already up to date)"
else
  echo -e "  ${GREEN}+${NC} $DISPLAY_PREFIX/rules/100-days.md (${YELLOW}v${OLD_VERSION}${NC} → ${GREEN}v${NEW_VERSION}${NC})"
fi

# ─── Copy commands ────────────────────────────────────────────

if [ ! -d "$SCRIPT_DIR/commands" ]; then
  echo -e "  ${RED}Error: commands/ directory not found in $SCRIPT_DIR${NC}"
  exit 1
fi

if [ "$MODE" = "project" ]; then
  CMD_TARGET="$TARGET_DIR/commands"
  CMD_DISPLAY="$DISPLAY_PREFIX/commands"
else
  CMD_TARGET="$HOME/.claude/commands"
  CMD_DISPLAY="~/.claude/commands"
fi

echo -e "${CYAN}Installing commands (${CMD_DISPLAY}/)...${NC}"
mkdir -p "$CMD_TARGET"
for cmd_file in "$SCRIPT_DIR/commands/"*.md; do
  if [ -f "$cmd_file" ]; then
    cmd_name=$(basename "$cmd_file")
    cp "$cmd_file" "$CMD_TARGET/$cmd_name"
    echo -e "  ${GREEN}+${NC} ${CMD_DISPLAY}/$cmd_name"
  fi
done

# ─── Verify installation ──────────────────────────────────────

echo -e "${CYAN}Verifying installation...${NC}"
ERRORS=0

if [ ! -f "$TARGET_DIR/rules/100-days.md" ]; then
  echo -e "  ${RED}✗${NC} Missing: $DISPLAY_PREFIX/rules/100-days.md"
  ERRORS=$((ERRORS + 1))
fi

if [ ! -s "$TARGET_DIR/rules/100-days.md" ]; then
  echo -e "  ${RED}✗${NC} Empty: $DISPLAY_PREFIX/rules/100-days.md"
  ERRORS=$((ERRORS + 1))
fi

for cmd_file in "$SCRIPT_DIR/commands/"*.md; do
  if [ -f "$cmd_file" ]; then
    cmd_name=$(basename "$cmd_file")
    if [ ! -f "$CMD_TARGET/$cmd_name" ]; then
      echo -e "  ${RED}✗${NC} Missing: ${CMD_DISPLAY}/$cmd_name"
      ERRORS=$((ERRORS + 1))
    fi
  fi
done

if [ "$MODE" = "project" ] && [ ! -f "$PROJECT_DIR/CLAUDE.md" ]; then
  echo -e "  ${RED}✗${NC} Missing: $PROJECT_DIR/CLAUDE.md"
  ERRORS=$((ERRORS + 1))
fi

if [ "$ERRORS" -gt 0 ]; then
  echo -e "  ${RED}$ERRORS error(s) found. Installation may be incomplete.${NC}"
  exit 1
fi

echo -e "  ${GREEN}All checks passed.${NC}"

# ─── Done ─────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "What's installed:"
echo "  - Rule: $DISPLAY_PREFIX/rules/100-days.md"
echo "  - CLAUDE.md: session start protocol"
echo "  - Commands: ${CMD_DISPLAY}/life-*.md"
echo ""
echo -e "${CYAN}Next steps:${NC}"
echo "  1. Open your project in Claude Code"
echo "  2. Run /life-init to set up quality tooling and create myLife.md"
echo "  3. The game begins. You have 100 lives. Don't die."
echo ""
echo -e "${RED}Remember: death is permanent. There is no resurrection.${NC}"
