---
name: inject
description: Inject a random seed into any creative task (visual design, prose, naming, code architecture, anything where variety beats the default) so the result does not regress to the mean. Use when the user runs /entropy:inject, asks for "something different", "surprise me", "not the usual", or wants several distinct takes on the same brief.
argument-hint: "[--log] [--headless] [--seed <string>] [task] | --current"
---

# Entropy: inject

A model cannot act randomly. Asked for "something unique", it predicts tokens that sound random and lands on the same purple gradient every time. Real variety has to come from outside the model. This skill pulls a random string from the shell, turns it into a word from the dictionary, and makes the model reason from that word to a strategy for the task.

Based on String Seed of Thought (Sakana AI): randomness enters as selection, never as interpretation. A model reading a random string sees the same thing in every string. A model reading the word "vespers" does not.

## Arguments

`$ARGUMENTS` is one of:

- Empty: new seed, one strategy shown, then stop and wait.
- `<task>`: new seed, one strategy, one result. For short work, a line, a name, a paragraph, a function, the result comes in the same reply. For long work, a page, a module, a document, stop after the strategy and wait: the user says go, or more.
- `<task>` asking for N variations: N words, N strategies, N results, one each.
- `--seed <string> [task]`: use the given string. The same words come out, so the same starting points; the strategy is written fresh.
- `--current`: do not generate. Read `.entropy/current.json` and re-state its brief and strategy. If the file is missing, say so and stop.
- `--log`: record the run in `.entropy/seeds.jsonl` and `.entropy/current.json`. Off by default. Stays on for the session.
- `--headless`: never stop and never ask. Build in the same reply. Turns `--log` on. Stays on for the session.

Flags come first. Text after the flags is the task.

## Procedure

### 1. Seed

```bash
openssl rand -base64 48
```

Do not invent, edit, or shorten it.

### 2. Brief

List what the user has already fixed, one line each, in their words: a length, a required word, a banned word, a voice or brand file, an example to match. Give each line a test that can be run on the result: a word count, a grep, a file to compare against. If nothing is fixed, write `brief: none`. The house style in CLAUDE.md and any active skill count as brief lines whether or not the user repeated them.

### 3. Words

Six words from the seed, one line:

```bash
printf '%s' "$SEED" | shasum -a 256 | cut -c1-48 | fold -w8 | while read h; do awk -v n=$((16#$h)) '/^[a-z]+$/ && length>=4 && length<=9 {a[++c]=$0} END{i=n%c+1; print i, a[i]}' /usr/share/dict/words; done
```

Each line is a position and a word, drawn from the lowercase words of four to nine letters. Use the first word. For N variations, use the first N. When the user says more, take the next unused word; past the sixth, draw six more from the seed with a round number appended, `printf '%s2' "$SEED"`, then `3`. Nothing already shown is discarded. If the dictionary file is missing, say so and stop; do not invent words.

### 4. Strategy

From the word, write a chain of three hops, one line: the word, what it brings to mind, what that brings to mind, what that brings to mind. Then, from the third hop only, a strategy for the task: three or four plain sentences saying what the result would be, the way you would tell a colleague across a desk. The strategy obeys every brief line. It does not obey your taste. If the third hop is a bad fit for the task, the strategy is still built from it; a bad fit made to work is the point. If you do not know the word, the first hop is what it looks or sounds like.

For several words, one chain and one strategy each, and read them back before showing them: if two would give results a reader could not tell apart, the later one is rewritten from its own third hop until they differ.

Under `--log` only, write the strategies to `.entropy/strategies.txt` with a heredoc after `mkdir -p .entropy`, numbered, each with its word and chain. Otherwise no file is written.

### 5. Show

**Held constant.** Every brief line, in plain sentences. Two or three lines.

**The way in.** The chain on one line, the strategy under it. For several, each under its number.

For short work, the result follows at once, under the strategy, and the reply ends: keep it, or say more. For long work, the reply ends: go, or more. Under both, one small line with the seed.

Then, unless the work is short or `--headless` was given, stop and wait.

### 6. Record, under `--log` only

```bash
jq -nc --arg ts "$TS" --arg seed "$SEED" --arg task "$TASK" --arg brief "$BRIEF" --arg word "$WORD" --rawfile strategies .entropy/strategies.txt '{ts:$ts, seed:$seed, task:$task, brief:$brief, word:$word, strategies:$strategies}' >> .entropy/seeds.jsonl
```

Write `.entropy/current.json` with the same object.

### 7. Do the task and read it back

Build the strategy, or one result per strategy for variations. Before presenting a result, check it in this order:

1. The brief. Run each test. A result that fails a brief line is wrong however well it follows the strategy.
2. The strategy. State one fact from the least prominent place in the result, the second paragraph, the footer, the button, the smallest label, and say which sentence of the strategy it shows. A fact that shows a different strategy, or the plain default, is a miss.
3. The chain. The word and its hops are reasoning, not decoration. Search the result for them. A hit is a miss unless the strategy itself put it there.

Rewrite until there are no misses. Do not mention the check in the output.

For visual work, render before reading: `"$CHROME" --headless --disable-gpu --hide-scrollbars --window-size=1280,800 --screenshot=shot.png "file://$PWD/page.html"`, or `npx playwright screenshot --viewport-size=1280,800 "file://$PWD/page.html" shot.png`, and look at the image with the Read tool. With no renderer, say so in one line and read the code. Leave the files where they are; a page the user asked for is theirs to keep, and the screenshot is one file.

## Rules

- One seed at a time. A new inject replaces the old strategy. Saying more extends the current one.
- The scope is the deliverable named in the task. Work inside it follows the strategy; work outside it does not. When unclear, ask; under `--headless`, say you are applying it and let the user object.
- The user's standing rules and the brief win. The strategy varies taste inside that box and never overrides it.
- Variations are strategies, one word each. Five results from one strategy are five synonyms. Build one strategy several ways only when the user asks for that.
- When delegating inside the scope, paste the brief and the strategy from the reply into the subagent's prompt.
- Never soften the strategy later without saying so. If the user asks for a change, apply it and keep the rest.
