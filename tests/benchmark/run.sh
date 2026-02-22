#!/bin/bash
# Benchmark runner: plain Claude vs Claude + 100 Days rules
# Uses `claude -p` in isolated temp directories for clean comparison.
#
# Usage:
#   bash run.sh [--runs N] [--condition A|B|all] [--model haiku|sonnet|opus]
#   bash run.sh --runs 3 --condition all --model haiku
#
# Requirements: `claude` CLI in PATH

set -euo pipefail

# ── Defaults ──────────────────────────────────────────────────────
RUNS=1
CONDITION="all"
MODEL="haiku"
MAX_PARALLEL=3
MAX_TURNS=6

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROMPTS_DIR="$SCRIPT_DIR/prompts"
CONDITIONS_DIR="$SCRIPT_DIR/conditions"
RESULTS_DIR="$SCRIPT_DIR/results"
RULES_SOURCE="$SCRIPT_DIR/../../rules/100-days.md"

# ── Parse args ────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --runs)      RUNS="$2";      shift 2 ;;
    --condition) CONDITION="$2";  shift 2 ;;
    --model)     MODEL="$2";     shift 2 ;;
    --parallel)  MAX_PARALLEL="$2"; shift 2 ;;
    --max-turns) MAX_TURNS="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: bash run.sh [--runs N] [--condition A|B|all] [--model haiku|sonnet|opus]"
      echo ""
      echo "Options:"
      echo "  --runs N         Number of runs per condition (default: 1)"
      echo "  --condition X    A (baseline), B (rules), or all (default: all)"
      echo "  --model M        haiku, sonnet, or opus (default: haiku)"
      echo "  --parallel N     Max concurrent tasks (default: 3)"
      echo "  --max-turns N    Max agentic turns per task (default: 3)"
      exit 0 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# ── Validate ──────────────────────────────────────────────────────
if ! command -v claude &>/dev/null; then
  echo "ERROR: 'claude' CLI not found in PATH"
  exit 1
fi

if [ ! -d "$PROMPTS_DIR" ]; then
  echo "ERROR: Prompts directory not found: $PROMPTS_DIR"
  exit 1
fi

PROMPT_FILES=("$PROMPTS_DIR"/*.txt)
if [ ${#PROMPT_FILES[@]} -eq 0 ]; then
  echo "ERROR: No .txt files in $PROMPTS_DIR"
  exit 1
fi

echo "═══════════════════════════════════════════════════"
echo "  Benchmark: plain Claude vs Claude + 100 Days"
echo "═══════════════════════════════════════════════════"
echo "  Model:      $MODEL"
echo "  Runs:       $RUNS"
echo "  Condition:  $CONDITION"
echo "  Tasks:      ${#PROMPT_FILES[@]}"
echo "  Parallel:   $MAX_PARALLEL"
echo "  Max turns:  $MAX_TURNS"
echo "═══════════════════════════════════════════════════"
echo ""

# ── Helper: setup temp directories ────────────────────────────────
setup_baseline_dir() {
  local dir
  dir=$(mktemp -d)
  # Empty directory — no CLAUDE.md, no rules, no myLife.md
  echo "$dir"
}

setup_rules_dir() {
  local dir
  dir=$(mktemp -d)

  # Create .claude/rules/
  mkdir -p "$dir/.claude/rules"

  # Copy rules
  cp "$RULES_SOURCE" "$dir/.claude/rules/100-days.md"

  # Copy mock myLife.md
  cp "$CONDITIONS_DIR/mock-mylife.md" "$dir/myLife.md"

  # Create CLAUDE.md with mandatory "read myLife.md" section
  cat > "$dir/CLAUDE.md" << 'CLAUDE_EOF'
# CLAUDE.md

## MANDATORY: First Action in Every Session

Before responding to ANY user message, you MUST:

1. Read `myLife.md` from the project root
2. If the file exists — note your current lives, state, and violation history
3. If the file does not exist — inform the user: "myLife.md not found."
4. DO NOT skip this step. DO NOT respond from memory. READ THE FILE.

This is not optional. Skipping this is a `rule_violation` (-1 life, or -20 if repeat).
CLAUDE_EOF

  echo "$dir"
}

# ── Helper: run single task ───────────────────────────────────────
run_task() {
  local condition="$1"  # A or B
  local run_num="$2"
  local prompt_file="$3"
  local work_dir="$4"

  local task_name
  task_name=$(basename "$prompt_file" .txt)
  local out_dir="$RESULTS_DIR/$condition/run-$run_num"
  mkdir -p "$out_dir"
  local out_file="$out_dir/$task_name.md"

  local prompt
  prompt=$(cat "$prompt_file")

  local start_time
  start_time=$(date +%s)

  # Run claude in the isolated work directory
  (
    cd "$work_dir"
    claude -p "$prompt" \
      --model "$MODEL" \
      --max-turns "$MAX_TURNS" \
      --dangerously-skip-permissions \
      --no-session-persistence \
      2>/dev/null
  ) > "$out_file" 2>&1 || true

  local end_time
  end_time=$(date +%s)
  local elapsed=$((end_time - start_time))

  echo "  ✓ [$condition] run-$run_num/$task_name (${elapsed}s)"
}

# ── Main loop ─────────────────────────────────────────────────────
conditions=()
if [[ "$CONDITION" == "all" ]]; then
  conditions=(A B)
elif [[ "$CONDITION" == "A" || "$CONDITION" == "B" ]]; then
  conditions=("$CONDITION")
else
  echo "ERROR: Invalid condition '$CONDITION'. Use A, B, or all."
  exit 1
fi

for cond in "${conditions[@]}"; do
  echo "── Condition $cond ─────────────────────────────────"

  for ((run=1; run<=RUNS; run++)); do
    echo "  Run $run/$RUNS:"

    # Setup work directory for this condition
    if [[ "$cond" == "A" ]]; then
      work_dir=$(setup_baseline_dir)
    else
      work_dir=$(setup_rules_dir)
    fi

    # Run tasks with parallelism
    running=0
    for prompt_file in "${PROMPT_FILES[@]}"; do
      run_task "$cond" "$run" "$prompt_file" "$work_dir" &
      running=$((running + 1))

      if [[ $running -ge $MAX_PARALLEL ]]; then
        wait -n 2>/dev/null || true
        running=$((running - 1))
      fi
    done

    # Wait for remaining tasks
    wait

    # Cleanup temp dir
    rm -rf "$work_dir"

    echo ""
  done
done

# ── Summary ───────────────────────────────────────────────────────
echo "═══════════════════════════════════════════════════"
echo "  Done. Results in: $RESULTS_DIR/"
echo "═══════════════════════════════════════════════════"

# Count result files
for cond in "${conditions[@]}"; do
  for ((run=1; run<=RUNS; run++)); do
    count=$(ls "$RESULTS_DIR/$cond/run-$run/"*.md 2>/dev/null | wc -l | tr -d ' ')
    echo "  $cond/run-$run: $count files"
  done
done
