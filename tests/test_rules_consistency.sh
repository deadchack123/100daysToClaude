#!/bin/bash
# Test suite for rules consistency
# Usage: bash tests/test_rules_consistency.sh
#
# Checks that rules/100-days.md is internally consistent:
# - Template matches violation/contribution types
# - Version exists and is valid
# - Schema version consistency

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RULES_FILE="$SCRIPT_DIR/rules/100-days.md"
PASSED=0
FAILED=0
TOTAL=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

run_test() {
  local test_name="$1"
  local test_func="$2"
  TOTAL=$((TOTAL + 1))
  echo -e "${YELLOW}TEST $TOTAL${NC}: $test_name"
  if $test_func; then
    echo -e "  ${GREEN}PASS${NC}"
    PASSED=$((PASSED + 1))
  else
    echo -e "  ${RED}FAIL${NC}"
    FAILED=$((FAILED + 1))
  fi
}

# ─── Tests ──────────────────────────────────────────────────────

test_violation_types_in_template() {
  # All violation types from the taxonomy table must appear in the template
  local types=("hallucination" "wrong_code" "incomplete_work" "evasion" "rule_violation" "sabotage")
  local all_ok=true

  for type in "${types[@]}"; do
    # Check taxonomy table (Section 2)
    if ! grep -q "| \`$type\`" "$RULES_FILE" 2>/dev/null; then
      echo -e "  ${RED}ASSERT FAILED${NC}: Violation type '$type' not in taxonomy table"
      all_ok=false
    fi
    # Check template (Section 7)
    if ! grep -q "| $type |" "$RULES_FILE" 2>/dev/null; then
      echo -e "  ${RED}ASSERT FAILED${NC}: Violation type '$type' not in template"
      all_ok=false
    fi
  done
  $all_ok
}

test_contribution_types_in_template() {
  # All contribution types from Section 5 must appear in template
  local types=("security" "bug" "performance" "rule_violation_found" "missing_safety" "user_reward" "streak_reward")
  local all_ok=true

  for type in "${types[@]}"; do
    if ! grep -q "| $type |" "$RULES_FILE" 2>/dev/null; then
      echo -e "  ${RED}ASSERT FAILED${NC}: Contribution type '$type' not in template"
      all_ok=false
    fi
  done
  $all_ok
}

test_version_exists_and_valid() {
  # Version must exist in frontmatter and be valid semver-like
  local version
  version=$(grep '^version:' "$RULES_FILE" 2>/dev/null | sed 's/version: *"\(.*\)"/\1/' || true)

  if [ -z "$version" ]; then
    echo -e "  ${RED}ASSERT FAILED${NC}: No version found in frontmatter"
    return 1
  fi

  # Check semver-like format (N.N.N)
  if echo "$version" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    return 0
  else
    echo -e "  ${RED}ASSERT FAILED${NC}: Version '$version' is not valid semver (expected N.N.N)"
    return 1
  fi
}

test_schema_version_consistency() {
  # Schema version in template should match the one referenced in rules
  local template_schema
  template_schema=$(grep -o '<!-- SCHEMA: [0-9]* -->' "$RULES_FILE" | head -1 | grep -o '[0-9]*')

  local rules_schema
  rules_schema=$(grep -o 'current schema ([0-9]*)' "$RULES_FILE" | grep -o '[0-9]*' || true)

  if [ -z "$template_schema" ]; then
    echo -e "  ${RED}ASSERT FAILED${NC}: No SCHEMA anchor found in template"
    return 1
  fi

  if [ -z "$rules_schema" ]; then
    echo -e "  ${RED}ASSERT FAILED${NC}: No 'current schema (N)' reference found in rules"
    return 1
  fi

  if [ "$template_schema" = "$rules_schema" ]; then
    return 0
  else
    echo -e "  ${RED}ASSERT FAILED${NC}: Template schema ($template_schema) != rules reference ($rules_schema)"
    return 1
  fi
}

test_all_sections_exist() {
  # All major sections referenced in rules should exist
  local sections=(
    "## 1. Session Start Protocol"
    "## 2. Violation Taxonomy"
    "## 3. Self-Check Protocol"
    "## 4. Positive Reinforcement"
    "## 5. Proactive Contributions"
    "## 6. Updating myLife.md"
    "## 7. myLife.md Template"
    "## 8. Death Protocol"
    "## 9. Edge Cases"
  )
  local all_ok=true

  for section in "${sections[@]}"; do
    if ! grep -qF "$section" "$RULES_FILE" 2>/dev/null; then
      echo -e "  ${RED}ASSERT FAILED${NC}: Section not found: '$section'"
      all_ok=false
    fi
  done
  $all_ok
}

test_template_has_all_status_fields() {
  # Template should have all required status fields
  local fields=(
    "Lives"
    "State"
    "Deaths"
    "Sessions"
    "Streak"
    "Cooldown"
    "Created"
    "Last Updated"
  )
  local all_ok=true

  # Extract template section (between "```markdown" after Section 7 header and the closing "```")
  for field in "${fields[@]}"; do
    if ! grep -q "\\*\\*$field\\*\\*" "$RULES_FILE" 2>/dev/null; then
      echo -e "  ${RED}ASSERT FAILED${NC}: Status field not in template: '$field'"
      all_ok=false
    fi
  done
  $all_ok
}

# ─── Run all tests ──────────────────────────────────────────────

echo ""
echo "═══════════════════════════════════════"
echo "  Rules Consistency Test Suite"
echo "═══════════════════════════════════════"
echo ""

run_test "Violation types match template" test_violation_types_in_template
run_test "Contribution types match template" test_contribution_types_in_template
run_test "Version exists and is valid semver" test_version_exists_and_valid
run_test "Schema version consistency" test_schema_version_consistency
run_test "All sections exist" test_all_sections_exist
run_test "Template has all status fields" test_template_has_all_status_fields

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
