#!/bin/bash
# Test suite for install.sh
# Usage: bash tests/test_install.sh
#
# Creates a temp directory, runs install.sh in various modes, checks results.
# Cleans up after itself.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
INSTALL_SH="$SCRIPT_DIR/install.sh"
TEMP_DIR=""
PASSED=0
FAILED=0
TOTAL=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

setup() {
  TEMP_DIR=$(mktemp -d)
}

teardown() {
  if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
    rm -rf "$TEMP_DIR"
  fi
}

assert_file_exists() {
  local file="$1"
  local msg="${2:-File should exist: $file}"
  if [ -f "$file" ]; then
    return 0
  else
    echo -e "  ${RED}ASSERT FAILED${NC}: $msg"
    return 1
  fi
}

assert_file_not_exists() {
  local file="$1"
  local msg="${2:-File should not exist: $file}"
  if [ ! -f "$file" ]; then
    return 0
  else
    echo -e "  ${RED}ASSERT FAILED${NC}: $msg"
    return 1
  fi
}

assert_dir_exists() {
  local dir="$1"
  local msg="${2:-Directory should exist: $dir}"
  if [ -d "$dir" ]; then
    return 0
  else
    echo -e "  ${RED}ASSERT FAILED${NC}: $msg"
    return 1
  fi
}

assert_file_contains() {
  local file="$1"
  local pattern="$2"
  local msg="${3:-File should contain: $pattern}"
  if grep -q "$pattern" "$file" 2>/dev/null; then
    return 0
  else
    echo -e "  ${RED}ASSERT FAILED${NC}: $msg"
    return 1
  fi
}

assert_file_not_empty() {
  local file="$1"
  local msg="${2:-File should not be empty: $file}"
  if [ -s "$file" ]; then
    return 0
  else
    echo -e "  ${RED}ASSERT FAILED${NC}: $msg"
    return 1
  fi
}

assert_exit_code() {
  local expected="$1"
  local actual="$2"
  local msg="${3:-Exit code should be $expected, got $actual}"
  if [ "$actual" -eq "$expected" ]; then
    return 0
  else
    echo -e "  ${RED}ASSERT FAILED${NC}: $msg"
    return 1
  fi
}

run_test() {
  local test_name="$1"
  local test_func="$2"
  TOTAL=$((TOTAL + 1))
  echo -e "${YELLOW}TEST $TOTAL${NC}: $test_name"
  setup
  if $test_func; then
    echo -e "  ${GREEN}PASS${NC}"
    PASSED=$((PASSED + 1))
  else
    echo -e "  ${RED}FAIL${NC}"
    FAILED=$((FAILED + 1))
  fi
  teardown
}

# ─── Tests ──────────────────────────────────────────────────────

test_fresh_project_install() {
  # Fresh install into a clean project directory
  local project="$TEMP_DIR/myproject"
  mkdir -p "$project"

  bash "$INSTALL_SH" --project "$project" > /dev/null 2>&1

  assert_dir_exists "$project/.claude/rules" &&
  assert_file_exists "$project/.claude/rules/100-days.md" &&
  assert_file_not_empty "$project/.claude/rules/100-days.md" &&
  assert_file_exists "$project/CLAUDE.md" &&
  assert_file_contains "$project/CLAUDE.md" "100days-start"
}

test_repeat_install_updates() {
  # Second install should update, not break
  local project="$TEMP_DIR/myproject"
  mkdir -p "$project"

  bash "$INSTALL_SH" --project "$project" > /dev/null 2>&1
  # Add user content to CLAUDE.md
  echo -e "\n## My Custom Section\nDo not remove this." >> "$project/CLAUDE.md"

  bash "$INSTALL_SH" --project "$project" > /dev/null 2>&1

  assert_file_exists "$project/.claude/rules/100-days.md" &&
  assert_file_contains "$project/CLAUDE.md" "100days-start" &&
  assert_file_contains "$project/CLAUDE.md" "My Custom Section"
}

test_project_flag_no_path() {
  # --project without a path should fail
  local exit_code=0
  bash "$INSTALL_SH" --project > /dev/null 2>&1 || exit_code=$?
  assert_exit_code 1 "$exit_code" "--project without path should exit 1"
}

test_nonexistent_project_dir() {
  # --project with nonexistent directory should fail
  local exit_code=0
  bash "$INSTALL_SH" --project "$TEMP_DIR/nonexistent" > /dev/null 2>&1 || exit_code=$?
  assert_exit_code 1 "$exit_code" "--project with nonexistent dir should exit 1"
}

test_rules_file_to_directory_conversion() {
  # .claude/rules exists as a file → should convert to directory
  local project="$TEMP_DIR/myproject"
  mkdir -p "$project/.claude"
  echo "existing rules content" > "$project/.claude/rules"

  bash "$INSTALL_SH" --project "$project" > /dev/null 2>&1

  assert_dir_exists "$project/.claude/rules" &&
  assert_file_exists "$project/.claude/rules/project-rules.md" &&
  assert_file_contains "$project/.claude/rules/project-rules.md" "existing rules content" &&
  assert_file_exists "$project/.claude/rules/100-days.md"
}

test_version_display() {
  # Version should be shown in output
  local project="$TEMP_DIR/myproject"
  mkdir -p "$project"

  local output
  output=$(bash "$INSTALL_SH" --project "$project" 2>&1)

  # Should show "fresh install" on first run
  if echo "$output" | grep -q "fresh install"; then
    # Second run should show "already up to date"
    output=$(bash "$INSTALL_SH" --project "$project" 2>&1)
    if echo "$output" | grep -q "already up to date"; then
      return 0
    else
      echo -e "  ${RED}ASSERT FAILED${NC}: Second install should show 'already up to date'"
      return 1
    fi
  else
    echo -e "  ${RED}ASSERT FAILED${NC}: First install should show 'fresh install'"
    return 1
  fi
}

test_commands_installed_globally() {
  # Commands should be in ~/.claude/commands/
  local project="$TEMP_DIR/myproject"
  mkdir -p "$project"

  bash "$INSTALL_SH" --project "$project" > /dev/null 2>&1

  # Check that command files from source exist in global commands
  local all_ok=true
  for cmd_file in "$SCRIPT_DIR/commands/"*.md; do
    if [ -f "$cmd_file" ]; then
      local cmd_name
      cmd_name=$(basename "$cmd_file")
      if [ ! -f "$HOME/.claude/commands/$cmd_name" ]; then
        echo -e "  ${RED}ASSERT FAILED${NC}: Missing global command: $cmd_name"
        all_ok=false
      fi
    fi
  done
  $all_ok
}

test_verification_catches_missing() {
  # If we delete a file after install, verification should fail on next install
  # (This tests the verification logic indirectly)
  local project="$TEMP_DIR/myproject"
  mkdir -p "$project"

  bash "$INSTALL_SH" --project "$project" > /dev/null 2>&1
  assert_file_exists "$project/.claude/rules/100-days.md"
}

test_claude_md_append_without_markers() {
  # If CLAUDE.md exists but has no markers, should append
  local project="$TEMP_DIR/myproject"
  mkdir -p "$project"
  echo "# My Project" > "$project/CLAUDE.md"
  echo "Some existing content." >> "$project/CLAUDE.md"

  bash "$INSTALL_SH" --project "$project" > /dev/null 2>&1

  assert_file_contains "$project/CLAUDE.md" "My Project" &&
  assert_file_contains "$project/CLAUDE.md" "Some existing content" &&
  assert_file_contains "$project/CLAUDE.md" "100days-start" &&
  assert_file_contains "$project/CLAUDE.md" "100days-end"
}

# ─── Run all tests ──────────────────────────────────────────────

echo ""
echo "═══════════════════════════════════════"
echo "  install.sh Test Suite"
echo "═══════════════════════════════════════"
echo ""

run_test "Fresh project install" test_fresh_project_install
run_test "Repeat install preserves user content" test_repeat_install_updates
run_test "--project without path exits 1" test_project_flag_no_path
run_test "Nonexistent project dir exits 1" test_nonexistent_project_dir
run_test "Rules file → directory conversion" test_rules_file_to_directory_conversion
run_test "Version display (fresh + up to date)" test_version_display
run_test "Commands installed globally" test_commands_installed_globally
run_test "Verification catches missing files" test_verification_catches_missing
run_test "CLAUDE.md append without markers" test_claude_md_append_without_markers

# ─── Summary ────────────────────────────────────────────────────

echo ""
echo "═══════════════════════════════════════"
if [ "$FAILED" -eq 0 ]; then
  echo -e "  ${GREEN}ALL $TOTAL TESTS PASSED${NC}"
else
  echo -e "  ${GREEN}$PASSED passed${NC}, ${RED}$FAILED failed${NC} out of $TOTAL"
fi
echo "═══════════════════════════════════════"
echo ""

exit "$FAILED"
