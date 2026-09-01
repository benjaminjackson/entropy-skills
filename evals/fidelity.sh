#!/bin/bash
# Fidelity: did each plugin-arm result come out the way its picks said? Judged from the screenshot
# (rendered on demand) against the direction in .entropy/current.json. Usage:
#   evals/fidelity.sh <results-dir> [prompt-name] [--judge-model M]
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
DIR=""; NAME=design; JUDGE=opus
while [ $# -gt 0 ]; do
  case "$1" in
    --judge-model) JUDGE=$2; shift 2;;
    *) if [ -z "$DIR" ]; then DIR=$1; else NAME=$1; fi; shift;;
  esac
done
[ -d "$DIR/$NAME/with" ] || { echo "no $NAME/with under $DIR" >&2; exit 1; }
DIR=$(cd "$DIR" && pwd)   # render() builds a file:// URL; it must be absolute

eval "$(sed -n '/^render() {/,/^}/p' "$ROOT/evals/run.sh")"

grade() { # run-dir -> fidelity.json
  local dir=$1
  [ -s "$dir/shot.png" ] || render "$dir"
  local direction; direction=$(jq -r '.direction // empty' "$dir/.entropy/current.json" 2>/dev/null)
  [ -n "$direction" ] || { echo '{"error":"no direction"}' > "$dir/fidelity.json"; return; }
  {
    echo "A designer rolled dice to choose creative decisions, then built a page. Here are the decisions:"
    echo; echo "$direction"; echo
    if [ -s "$dir/shot.png" ]; then
      echo "The finished page is rendered at shot.png in the working directory. Open it with the Read tool and judge from what you see."
    else
      echo "No render is available. Judge from the code below."; echo; cat "$dir/output.md"
    fi
    echo "For every decision that is visible in a static screenshot (ground color, layout skeleton, type family, palette, era or reference tradition, density, ornament, and the like; skip register, copy voice, motion, scope), say whether the page honors it. Be strict: a pixel font on an ordinary two-column split does not honor 'arcade cabinet'."
    echo 'Reply with JSON only: {"axes":[{"axis":"<name>","pick":"<what was chosen>","match":true|false,"seen":"<what the page actually shows, a few words>"}],"notes":"<one sentence>"}'
  } | (cd "$dir" && claude -p --setting-sources "" --model "$JUDGE" --no-session-persistence --allowedTools Read) > "$dir/fidelity.json" 2>/dev/null || true
}

for d in "$DIR/$NAME"/with/*/; do grade "${d%/}" & done
wait

python3 - "$DIR/$NAME/with" <<'PY'
import sys,re,json,glob,os
root=sys.argv[1]; tot=match=0; rows=[]
for f in sorted(glob.glob(os.path.join(root,'*','fidelity.json')), key=lambda p:int(p.split(os.sep)[-2])):
    txt=open(f).read(); m=re.search(r'\{.*\}', txt, re.S)
    try: j=json.loads(m.group(0))
    except Exception: rows.append((f.split(os.sep)[-2],'?','?')); continue
    ax=j.get('axes',[]); k=sum(1 for a in ax if a.get('match')); n=len(ax)
    tot+=n; match+=k
    miss=[a['axis'] for a in ax if not a.get('match')]
    rows.append((f.split(os.sep)[-2], f"{k}/{n}", ', '.join(miss) or '-'))
print(f"\n{'run':<5}{'honored':<10}missed axes")
for r in rows: print(f"{r[0]:<5}{r[1]:<10}{r[2]}")
print(f"\nfidelity: {match}/{tot} visual picks honored = {100*match/tot:.0f}%" if tot else "\nfidelity: ?")
PY
