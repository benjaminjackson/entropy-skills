#!/bin/bash
# Fidelity: did each plugin-arm result come out the way its picks said? Judged from the screenshot
# (rendered on demand) against the direction in .entropy/current.json. Usage:
#   evals/fidelity.sh <results-dir> [prompt-name] [--judge-model M] [--jobs N]
# --jobs caps how many claude processes run at once (default 6).
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
DIR=""; NAME=design; JUDGE=opus; JOBS=6
while [ $# -gt 0 ]; do
  case "$1" in
    --judge-model) JUDGE=$2; shift 2;;
    --jobs) JOBS=$2; shift 2;;
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

grade_menus() { # run-dir -> menus.json; are the menus honest, not the model's taste with a die attached
  local dir=$1 menus; menus=$(jq -r '.menus // empty' "$dir/.entropy/current.json" 2>/dev/null)
  [ -n "$menus" ] || return 0
  {
    echo "A designer wrote menus of options for creative decisions, then rolled dice to pick one option per menu. The menus:"
    echo; echo "$menus"; echo
    echo "Judge each menu on four checks: the habitual default appears in exactly one slot, not several under different names (cream, bone, linen, parchment are one ground); at least one option the designer would never choose on their own; every pair of options would be told apart in the result; options are traditions or concrete treatments, not adjectives."
    echo 'Reply with JSON only: {"menus":[{"axis":"<name>","ok":true|false,"problem":"<which check fails and how, or empty>"}],"notes":"<one sentence>"}'
  } | claude -p --setting-sources "" --model "$JUDGE" --no-session-persistence > "$dir/menus.json" 2>/dev/null || true
}

throttle() { while [ "$(jobs -rp | wc -l)" -ge "$JOBS" ]; do sleep 2; done; }
for d in "$DIR/$NAME"/with/*/; do throttle; grade "${d%/}" & throttle; grade_menus "${d%/}" & done
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
mt=mo=0; bad=[]
for f in glob.glob(os.path.join(root,'*','menus.json')):
    m=re.search(r'\{.*\}', open(f).read(), re.S)
    try: j=json.loads(m.group(0))
    except Exception: continue
    for a in j.get('menus',[]):
        mt+=1; mo+=bool(a.get('ok'))
        if not a.get('ok'): bad.append(f"{f.split(os.sep)[-2]} {a.get('axis')}: {a.get('problem','')[:90]}")
if mt:
    print(f"menus: {mo}/{mt} pass the four checks = {100*mo/mt:.0f}%")
    for b in bad[:15]: print("  "+b)

# Dice honesty, from current.json alone: every pick's number must be the hash byte at that axis's
# position and the remainder must be right; and the habit (slot 0) should land about 1/menu-size of the time.
import subprocess
picks=habit=exp=bad_num=bad_mod=0; badruns=set()
for f in glob.glob(os.path.join(root,'*','.entropy','current.json')):
    run=f.split(os.sep)[-3]
    try: j=json.load(open(f))
    except Exception: continue
    h=subprocess.run(['shasum','-a','256'],input=j['seed'].encode(),capture_output=True).stdout.decode()[:40]
    nums=[int(h[i:i+2],16) for i in range(0,40,2)]
    for i,m in enumerate(re.finditer(r'(\d+) mod (\d+) = (\d+)', j.get('direction',''))):
        n,k,p=map(int,m.groups()); picks+=1; habit+=(p==0); exp+=1/k
        if i<20 and n!=nums[i]: bad_num+=1; badruns.add(run)
        if p!=n%k: bad_mod+=1; badruns.add(run)
if picks:
    print(f"dice: {picks} picks, {bad_num} numbers not from the hash position, {bad_mod} wrong remainders" + (f" (runs {', '.join(sorted(badruns,key=int))})" if badruns else ""))
    print(f"habit: slot 0 picked {habit}/{picks} = {100*habit/picks:.1f}%, chance {100*exp/picks:.1f}%")

# Order, from the transcript when one was saved: the first assistant text that names the habit
# (every menu marks slot 0 as the habit) must come before the first shell call that runs shasum.
ordered=total=0; late=[]; missing=0
for f in glob.glob(os.path.join(root,'*','transcript.jsonl')):
    run=f.split(os.sep)[-2]; menu_at=hash_at=None
    try:
        if json.load(open(os.path.join(os.path.dirname(f),'.entropy','current.json'))).get('from'): continue  # replay: menus came from the log, order does not apply
    except Exception: pass
    for idx,line in enumerate(open(f)):
        try: ev=json.loads(line)
        except Exception: continue
        if ev.get('type')!='assistant': continue
        for c in ev.get('message',{}).get('content',[]) or []:
            if c.get('type')=='text' and menu_at is None and 'habit' in c.get('text','').lower(): menu_at=idx
            if c.get('type')=='tool_use' and hash_at is None and 'shasum' in json.dumps(c.get('input',{})): hash_at=idx
    total+=1
    if hash_at is None: missing+=1; late.append(f"{run}: no shasum call")
    elif menu_at is None: late.append(f"{run}: no menu text before the hash")
    elif menu_at<hash_at: ordered+=1
    else: late.append(f"{run}: hash at event {hash_at}, menus at {menu_at}")
if total:
    print(f"order: {ordered}/{total} runs wrote menus before hashing")
    for l in late: print("  "+l)
else:
    print("order: no transcript.jsonl in this results dir (older run); menus-before-hash not checkable")
PY
