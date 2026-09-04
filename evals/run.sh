#!/bin/bash
# Runs each prompt N times with and without the plugin, then asks one judge per arm
# how varied the set is. Prints a score table. Usage:
#   evals/run.sh [--model opus|sonnet|haiku] [--runs N] [--passes N] [--jobs N] [--arms with|without|both] [--judge-model M] [--judge-model-2 M] [prompt-file ...]
# --jobs caps how many claude processes run at once (default 6), so a 40-run eval does not take the whole machine.
# --arms with runs and judges the plugin arm only, no baseline and no head-to-head, for cheap comparisons between skill versions.
# Each arm is scored PASSES times with responses shuffled, and both arms go head to head, blind, on two judge models.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
MODEL=opus; RUNS=5; PASSES=3; JOBS=6; ARMS="with without"; JUDGE=opus; JUDGE2=sonnet; PROMPTS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --model) MODEL=$2; shift 2;;
    --runs) RUNS=$2; shift 2;;
    --judge-model) JUDGE=$2; shift 2;;
    --judge-model-2) JUDGE2=$2; shift 2;;
    --passes) PASSES=$2; shift 2;;
    --jobs) JOBS=$2; shift 2;;
    --arms) case "$2" in both) ARMS="with without";; with|without) ARMS=$2;; *) echo "arms must be with, without, or both" >&2; exit 1;; esac; shift 2;;
    *) PROMPTS+=("$1"); shift;;
  esac
done
case "$MODEL" in opus|sonnet|haiku) ;; *) echo "model must be opus, sonnet, or haiku" >&2; exit 1;; esac
[ ${#PROMPTS[@]} -gt 0 ] || PROMPTS=("$ROOT"/evals/prompts/*.md)

OUT="$ROOT/evals/results/$(date -u +%Y%m%dT%H%M%SZ)-$MODEL"
mkdir -p "$OUT"

throttle() { while [ "$(jobs -rp | wc -l)" -ge "$JOBS" ]; do sleep 2; done; }   # bash 3.2 has no wait -n

run_one() { # arm prompt-file index
  local arm=$1 file=$2 i=$3 name; name=$(basename "$file" .md)
  local dir="$OUT/$name/$arm/$i"; mkdir -p "$dir"
  local task; task=$(cat "$file")
  if [ "$arm" = with ]; then
    # Full transcript kept so fidelity.sh can check that menus were written before the hash was run.
    (cd "$dir" && claude -p --setting-sources "" --plugin-dir "$ROOT" --model "$MODEL" --permission-mode bypassPermissions --no-session-persistence --output-format stream-json --verbose "/entropy:inject --headless $task" > transcript.jsonl 2> stderr.log && jq -r 'select(.type=="result") | .result' transcript.jsonl > output.md) || echo "run failed: $name/$arm/$i" >&2
  else
    (cd "$dir" && claude -p --setting-sources "" --model "$MODEL" --no-session-persistence "$task" > output.md 2> stderr.log) || echo "run failed: $name/$arm/$i" >&2
  fi
}

for file in "${PROMPTS[@]}"; do
  for arm in $ARMS; do
    for i in $(seq 1 "$RUNS"); do throttle; run_one "$arm" "$file" "$i" & done
  done
done
wait

render() { # dir -> writes dir/page.html and dir/shot.png when the output holds HTML and a browser exists; silent otherwise
  local dir=$1 out="$1/output.md"
  if grep -q '^```html' "$out"; then sed -n '/^```html/,/^```/p' "$out" | sed '1d;$d' > "$dir/page.html"
  elif grep -qi '<style\|<section\|<div\|<!doctype' "$out"; then sed -n '/<!DOCTYPE\|<!doctype\|<html\|<style\|<section\|<div\|<header\|<main/,$p' "$out" > "$dir/page.html"
  else return 0; fi
  local chrome="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
  [ -x "$chrome" ] || chrome=$(command -v google-chrome || command -v chromium || command -v chromium-browser || true)
  if [ -n "$chrome" ]; then
    local to; to=$(command -v timeout || command -v gtimeout || true)   # macOS lacks timeout without coreutils; Chrome normally exits in ~2s but once ignored TERM for 8 minutes, so -k sends KILL
    ${to:+$to -k 5 30} "$chrome" --headless --disable-gpu --hide-scrollbars --window-size=1280,800 --screenshot="$dir/shot.png" "file://$dir/page.html" >/dev/null 2>&1 || true
  elif command -v npx >/dev/null; then
    npx --no-install playwright screenshot --viewport-size=1280,800 "file://$dir/page.html" "$dir/shot.png" >/dev/null 2>&1 || true
  fi
}
for file in "${PROMPTS[@]}"; do name=$(basename "$file" .md); for arm in $ARMS; do for i in $(seq 1 "$RUNS"); do render "$OUT/$name/$arm/$i"; done; done; done

shots_note() { # name arm -> instruction line listing screenshots, if any rendered
  local name=$1 arm=$2 list=""
  for i in $(seq 1 "$RUNS"); do [ -s "$OUT/$name/$arm/$i/shot.png" ] && list="$list $arm/$i/shot.png"; done
  [ -n "$list" ] && echo "Screenshots of the rendered responses are at these paths, relative to the working directory; open each with the Read tool and judge from what you see, using the code only for what a screenshot cannot show:$list"
}

judge_set() { # prompt-file arm pass  -> writes judge-<pass>.json with responses shuffled
  local file=$1 arm=$2 pass=$3 name; name=$(basename "$file" .md)
  local task; task=$(cat "$file")
  local order; order=$(python3 -c 'import random,sys; l=sys.argv[1:]; random.shuffle(l); print(" ".join(l))' $(seq 1 "$RUNS"))
  {
    echo "You are judging how varied a set of $RUNS independent responses to the same brief is. Brief:"
    echo; echo "$task"; echo
    echo "Ignore any preamble about seeds, menus, or creative direction; judge only the deliverable. Consider whichever axes fit the brief: palette, layout, typography, structure, voice, rhythm, sound, metaphor, tone, architecture."
    echo "Reply with JSON only: {\"score\": <1-10, 1 = near-identical, 10 = every response takes a clearly different approach>, \"shared\": \"<the strongest pattern most responses share, or 'none'>\", \"notes\": \"<one sentence>\"}"
    shots_note "$name" "$arm"
    local n=0; for i in $order; do n=$((n+1)); echo; echo "===== RESPONSE $n (file $arm/$i) ====="; cat "$OUT/$name/$arm/$i/output.md"; done
  } | (cd "$OUT/$name" && claude -p --setting-sources "" --model "$JUDGE" --no-session-persistence --allowedTools Read) > "$OUT/$name/$arm/judge-$pass.json" 2>/dev/null
}

head_to_head() { # prompt-file pass judge-model -> writes h2h-<model>-<pass>.json; sets are labeled A/B in random order
  local file=$1 pass=$2 jm=$3 name; name=$(basename "$file" .md)
  local task; task=$(cat "$file")
  local first=with second=without
  if [ $((RANDOM % 2)) -eq 1 ]; then first=without; second=with; fi
  echo "{\"A\":\"$first\",\"B\":\"$second\"}" > "$OUT/$name/h2h-$jm-$pass.key"
  {
    echo "Two sets of $RUNS independent responses to the same brief. Brief:"
    echo; echo "$task"; echo
    echo "Ignore any preamble about seeds, menus, or creative direction; judge only the deliverables. Which set is more varied in approach, considering whichever axes fit the brief?"
    echo "Reply with JSON only: {\"more_varied\": \"A\" or \"B\", \"margin\": <1-5, 1 = barely, 5 = no contest>, \"notes\": \"<one sentence>\"}"
    for set in A B; do
      local arm; [ $set = A ] && arm=$first || arm=$second
      echo; echo "########## SET $set ##########"
      shots_note "$name" "$arm"
      for i in $(seq 1 "$RUNS"); do echo; echo "===== SET $set RESPONSE $i (file $arm/$i) ====="; cat "$OUT/$name/$arm/$i/output.md"; done
    done
  } | (cd "$OUT/$name" && claude -p --setting-sources "" --model "$jm" --no-session-persistence --allowedTools Read) > "$OUT/$name/h2h-$jm-$pass.json" 2>/dev/null
}

for file in "${PROMPTS[@]}"; do
  for pass in $(seq 1 "$PASSES"); do
    for arm in $ARMS; do throttle; judge_set "$file" "$arm" "$pass" & done
    [ "$ARMS" = "with without" ] && for jm in "$JUDGE" "$JUDGE2"; do throttle; head_to_head "$file" "$pass" "$jm" & done
  done
done
wait

score() { sed -n 's/.*"score": *\([0-9]*\).*/\1/p' "$1" | head -1; }
stats() { # files... -> "mean (min-max)"
  python3 -c '
import sys,re
v=[]
for f in sys.argv[1:]:
    m=re.search(r"\"score\":\s*(\d+)", open(f).read())
    if m: v.append(int(m.group(1)))
print("%.1f (%d-%d)" % (sum(v)/len(v), min(v), max(v)) if v else "?")' "$@"
}
h2h_wins() { # name judge-model -> "wins/passes"
  local name=$1 jm=$2 wins=0
  for pass in $(seq 1 "$PASSES"); do
    local pick arm
    pick=$(sed -n 's/.*"more_varied": *"\([AB]\)".*/\1/p' "$OUT/$name/h2h-$jm-$pass.json" | head -1)
    arm=$(jq -r ".$pick // empty" "$OUT/$name/h2h-$jm-$pass.key")
    [ "$arm" = with ] && wins=$((wins+1))
  done
  echo "$wins/$PASSES"
}

if [ "$ARMS" != "with without" ]; then
  printf '\n%-8s %-14s\n' prompt "$ARMS"
  for file in "${PROMPTS[@]}"; do name=$(basename "$file" .md); printf '%-8s %-14s\n' "$name" "$(stats "$OUT/$name"/$ARMS/judge-*.json)"; done
  echo; echo "details: $OUT"; exit 0
fi
printf '\n%-8s %-14s %-14s %-12s %-12s\n' prompt "with" "without" "h2h:$JUDGE" "h2h:$JUDGE2"
for file in "${PROMPTS[@]}"; do
  name=$(basename "$file" .md)
  printf '%-8s %-14s %-14s %-12s %-12s\n' "$name" "$(stats "$OUT/$name"/with/judge-*.json)" "$(stats "$OUT/$name"/without/judge-*.json)" "$(h2h_wins "$name" "$JUDGE")" "$(h2h_wins "$name" "$JUDGE2")"
done
echo; echo "with = mean (min-max) over $PASSES shuffled judge passes; h2h = passes where the plugin set was judged more varied"
echo "details: $OUT"
