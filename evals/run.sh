#!/bin/bash
# Runs each prompt N times with and without the plugin, then asks one judge per arm
# how varied the set is. Prints a score table. Usage:
#   evals/run.sh [--model opus|sonnet|haiku] [--runs N] [--judge-model M] [prompt-file ...]
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
MODEL=opus; RUNS=5; JUDGE=opus; PROMPTS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --model) MODEL=$2; shift 2;;
    --runs) RUNS=$2; shift 2;;
    --judge-model) JUDGE=$2; shift 2;;
    *) PROMPTS+=("$1"); shift;;
  esac
done
case "$MODEL" in opus|sonnet|haiku) ;; *) echo "model must be opus, sonnet, or haiku" >&2; exit 1;; esac
[ ${#PROMPTS[@]} -gt 0 ] || PROMPTS=("$ROOT"/evals/prompts/*.md)

OUT="$ROOT/evals/results/$(date -u +%Y%m%dT%H%M%SZ)-$MODEL"
mkdir -p "$OUT"

run_one() { # arm prompt-file index
  local arm=$1 file=$2 i=$3 name; name=$(basename "$file" .md)
  local dir="$OUT/$name/$arm/$i"; mkdir -p "$dir"
  local task; task=$(cat "$file")
  if [ "$arm" = with ]; then
    (cd "$dir" && claude -p --setting-sources "" --plugin-dir "$ROOT" --model "$MODEL" --permission-mode bypassPermissions --no-session-persistence "/entropy:inject --headless $task" > output.md 2> stderr.log) || echo "run failed: $name/$arm/$i" >&2
  else
    (cd "$dir" && claude -p --setting-sources "" --model "$MODEL" --no-session-persistence "$task" > output.md 2> stderr.log) || echo "run failed: $name/$arm/$i" >&2
  fi
}

for file in "${PROMPTS[@]}"; do
  for arm in with without; do
    for i in $(seq 1 "$RUNS"); do run_one "$arm" "$file" "$i" & done
  done
done
wait

judge() { # prompt-file arm
  local file=$1 arm=$2 name; name=$(basename "$file" .md)
  local task; task=$(cat "$file")
  {
    echo "You are judging how varied a set of $RUNS independent responses to the same brief is. Brief:"
    echo; echo "$task"; echo
    echo "Ignore any preamble about seeds or creative direction; judge only the deliverable. Consider whichever axes fit the brief: palette, layout, typography, structure, voice, rhythm, sound, metaphor, tone."
    echo "Reply with JSON only: {\"score\": <1-10, 1 = near-identical, 10 = every response takes a clearly different approach>, \"shared\": \"<the strongest pattern most responses share, or 'none'>\", \"notes\": \"<one sentence>\"}"
    for i in $(seq 1 "$RUNS"); do echo; echo "===== RESPONSE $i ====="; cat "$OUT/$name/$arm/$i/output.md"; done
  } | claude -p --setting-sources "" --model "$JUDGE" --no-session-persistence > "$OUT/$name/$arm/judge.json" 2>/dev/null
}
for file in "${PROMPTS[@]}"; do for arm in with without; do judge "$file" "$arm" & done; done
wait

printf '\n%-10s %-8s %-8s %s\n' prompt with without shared-pattern-with-plugin
for file in "${PROMPTS[@]}"; do
  name=$(basename "$file" .md)
  w=$(sed -n 's/.*"score": *\([0-9]*\).*/\1/p' "$OUT/$name/with/judge.json" | head -1)
  wo=$(sed -n 's/.*"score": *\([0-9]*\).*/\1/p' "$OUT/$name/without/judge.json" | head -1)
  sh=$(sed -n 's/.*"shared": *"\([^"]*\)".*/\1/p' "$OUT/$name/with/judge.json" | head -1)
  printf '%-10s %-8s %-8s %s\n' "$name" "${w:-?}" "${wo:-?}" "$sh"
done
echo; echo "details: $OUT"
