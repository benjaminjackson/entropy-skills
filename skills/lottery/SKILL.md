---
name: lottery
description: Run /entropy:inject many times for one task, have a judge name what the strategies share, ban it, draw again, and hand back the strategies that sit farthest from the crowd. Use when the user runs /entropy:lottery, wants to see the model's habits for a task, or wants the least usual take on a brief rather than one random take.
argument-hint: "[--n N] [--rounds R] [--keep K] [--build] [--model M] [--judge-model M] [--headless] [--seed <string>] <task>"
---

# Entropy: lottery

One word from `/entropy:inject` gives one strategy that is not the default. It does not tell you what the default was. Run the draw twenty-four times in twenty-four separate contexts and what recurs is the model's habit for this task, whether or not anyone could have named it in advance. A judge can name it, because naming what a set shares is the one thing a judge does well, and it can score how far each strategy sits from the rest. The survivors are the farthest. Banning the habits and drawing again does not spread the field; it moves the whole field to the model's next default, so a second round is a map of that layer, not a better pick.

This skill runs that loop with the Workflow tool. Running this skill is the user's opt-in to it.

## Arguments

Flags first, task after. `--n` words per round, default 24. `--rounds`, default 1; a second round bans the three most shared habits and draws again, which maps the model's next layer and does not spread the field. `--keep`, default 6. `--build` renders the kept strategies before the pick; off by default, the user picks from strategies. `--model` for the strategy and build agents, default opus. `--judge-model`, default opus. `--headless` never stops. `--seed <string>` replaces the random seed.

The strategies must come from the model that will build, because the habits found are that model's habits. Do not lower `--model` to save quota; a strategy is a hundred tokens.

## Procedure

### 1. Brief

Exactly as in `/entropy:inject` step 2: what the user has already fixed, one line each, in their words, one test per line; house style and active skills count; `brief: none` if nothing.

### 2. Draw

```bash
SEED=$(openssl rand -base64 48); TS=$(date -u +%Y%m%dT%H%M%SZ); DIR=.entropy/lottery/$TS; mkdir -p "$DIR"
W=$(grep -Ex '[a-z]{4,9}' /usr/share/dict/words); C=$(printf '%s\n' "$W" | wc -l | tr -d ' ')
for k in $(seq 1 $(( (N*R)/6 + 2 ))); do s=$SEED; [ "$k" -gt 1 ] && s=$SEED$k; printf '%s' "$s" | shasum -a 256 | cut -c1-48 | fold -w8 | while read h; do printf '%s\n' "$W" | sed -n "$((16#$h % C + 1))p"; done; done | perl -ne 'print unless $seen{$_}++' | head -n $((N*R)) > "$DIR/words.txt"
```

The same draw as inject, repeated with round numbers appended to the seed, duplicates dropped. No dollar sign followed by a digit anywhere in the command: the skill runner replaces those with words from the arguments. If the dictionary file is missing, say so and stop.

### 3. Run

Call the Workflow tool with `scriptPath` set to `lottery.js` in this skill's directory and these `args`, as JSON values, not a string:

```json
{"task": "<task>", "brief": "<brief lines>", "words": ["<from words.txt>"], "n": N, "keep": K, "ts": "<TS>", "seed": "<SEED>", "dir": "<DIR>", "model": "<model>", "judgeModel": "<judge model>", "bans": []}
```

The script runs one agent per word, each a fresh context running `/entropy:inject --headless --strategy --word <word>`, and each writes its own reply to `round-<r>/<NN>.md` under the run directory. One judge per round reads those files, names every feature three or more of the finished results would share, gives each a ban a writer can obey and a test that runs on the result, scores each strategy's distance from the crowd, marks brief failures, and writes `round-<r>/judge.json`. The three most shared habits become brief lines for the next round; more than that and the next round's strategies turn into a walk through the list. At the end the script drops brief failures, sorts by distance with fewer shared habits as the tiebreak, and returns the top K with the bans and each round's verdict. Nothing is copied; the files the agents wrote are the record.

### 4. Log the habits

```bash
for j in "$DIR"/round-*/judge.json; do r=${j%/judge.json}; r=${r##*round-}; jq -c --arg ts "$TS" --arg task "$TASK" --argjson r "$r" --argjson n "$N" '.shared[] | select(.members | length >= 3) | {ts:$ts, task:$task, round:$r, habit, test, members, n:$n}' "$j"; done >> .entropy/habits.jsonl
```

Append only. This file is the atlas of what the model reaches for, task by task.

### 5. Show

**Held constant.** The brief in plain sentences.

**What recurred.** One line per habit, per round: the habit, then its count over N. Round two's list is what survived the round-one bans.

**Survivors.** Each kept strategy under its number: the chain on one line, the strategy under it, its distance, and its file.

Then, one line: pick a number to build it, or say more for another round. One small line with the seed and the run directory. Under `--headless`, do not stop; the reply ends with the survivors.

### 6. Pick, more, or build

A number: build that strategy here, the way inject step 7 does, with the brief and the strategy pasted whole and the read-back run before showing.

`more`: draw the next N words with the next round numbers, call the script again with the same run directory and the bans so far in `bans`, and show again. Numbering continues.

`--build`, or the user asking to see them first: call the script again with `"mode": "build"` and `"survivors"` set to the kept list. Each build lands under `build/<NN>/`. Render pages the way inject does and show the paths.

## Rules

- Every strategy comes from its own context. Never write several in one call; a model that can see the others avoids repeating them, and the habit hides.
- The judge names what is shared and scores distance. It never says which is best. If the user wants best, that is their call to make from the survivors.
- A ban is one negative imperative the judge wrote, with a test on the result, nothing more. It forbids the habit and names no substitute; in the first run, a ban that said what to do instead put all six next-round strategies in the first person with a house key in hand. Three per round at most.
- The inject rules hold inside every agent: the user's standing rules and the brief win, the chain words stay out of the result, nothing is softened without saying so.
