#!/bin/bash
# Counts the known tells of model-made pages across a results directory, per arm. Usage:
#   evals/tells.sh <results-dir> [prompt-name]
# A tell counts once per page. "tracked caps" is uppercase small type with positive letter-spacing in the same rule,
# which is the eyebrow; a caps headline tightened to -0.02em is not counted.
set -euo pipefail
DIR=${1:?results dir}; NAME=${2:-design}
python3 - "$DIR/$NAME" <<'PY'
import sys,re,glob,os,collections
root=sys.argv[1]
tells={
 'tracked caps':   lambda css,txt: any(re.search(r'text-transform:\s*uppercase',b) and re.search(r'letter-spacing:\s*\.?0*[1-9]',b) for b in re.findall(r'\{[^}]*\}',css)),
 'refusal copy':   lambda css,txt: re.search(r'\bno (streaks|badges|notifications|confetti|gamification)\b',txt,re.I) is not None,
 'gradient':       lambda css,txt: re.search(r'(?<!repeating-)(linear|radial|conic)-gradient\(',css) is not None,
 'soft shadow':    lambda css,txt: re.search(r'box-shadow:\s*[^;]*?(?:\d+px|0)\s+(?:\d+px|0)\s+[1-9]\d*px',css) is not None,
 'rounded corners':lambda css,txt: re.search(r'border-radius:\s*(?:[1-9]\d*|0?\.\d+)(px|rem|em|%)',css) is not None,
 'stat strip':     lambda css,txt: re.search(r'class="[^"]*\b(stat|stats|figures|specs|metrics)\b',txt) is not None,
 'photograph':     lambda css,txt: 'picsum.photos' in txt or re.search(r'<img\b',txt) is not None,
 'inline svg':     lambda css,txt: '<svg' in txt,
}
for arm in ['with','without']:
    pages=sorted(glob.glob(os.path.join(root,arm,'*','page.html')))
    if not pages: continue
    c=collections.Counter()
    for p in pages:
        html=open(p,errors='replace').read()
        css=' '.join(re.findall(r'<style[^>]*>(.*?)</style>',html,re.S))+' '.join(re.findall(r'style="([^"]*)"',html))
        for k,f in tells.items():
            if f(css,html): c[k]+=1
    print(f"{arm} ({len(pages)} pages)")
    for k in tells: print(f"  {k:<16}{c[k]:>3}")
PY
