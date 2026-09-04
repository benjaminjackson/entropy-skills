---
name: inject
description: Inject a random seed into any creative task (visual design, prose, naming, code architecture, anything where variety beats the default) so the result does not regress to the mean. Use when the user runs /entropy:inject, asks for "something different", "surprise me", "not the usual", or wants several distinct takes on the same brief.
argument-hint: "[--log] [--headless] [--seed <string>] [task] | --current"
---

# Entropy: inject

A model cannot act randomly. Asked for "something unique", it predicts tokens that sound random and lands on the same purple gradient every time. Real variety has to come from outside the model. This skill pulls a random string from the shell, turns it into words from the dictionary, and makes the model reason from each word to a strategy for the task.

Based on String Seed of Thought (Sakana AI): randomness enters as selection, never as interpretation. A model reading a random string sees the same thing in every string. A model reading the word "vespers" does not.

## Arguments

`$ARGUMENTS` is one of:

- Empty: new seed, five strategies shown, then stop and wait.
- `<task>`: new seed, five strategies. For short work, a line, a name, a paragraph, a function, all five are built in the same reply, one result each. For long work, a page, a module, a document, stop after the strategies and wait: the user picks a number, says more, or says go and the die chooses.
- `--seed <string> [task]`: use the given string. The same words come out, so the same starting points; the strategies are written fresh.
- `--current`: do not generate. Read `.entropy/current.json` and re-state its brief and chosen strategy. If the file is missing, say so and stop.
- `--log`: record the run in `.entropy/seeds.jsonl` and `.entropy/current.json`. Off by default. Stays on for the session.
- `--headless`: never stop and never ask. For long work, build the strategy the die chose in the same reply. Turns `--log` on. Stays on for the session.

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

Six numbers from the seed, six words from the dictionary, one line:

```bash
printf '%s' "$SEED" | shasum -a 256 | cut -c1-48 | fold -w8 | while read h; do awk -v n=$((16#$h)) '/^[a-z]+$/ && length>=4 && length<=9 {a[++c]=$0} END{i=n%c+1; print i, a[i]}' /usr/share/dict/words; done
```

Each line is a position and a word, drawn from the lowercase words of four to nine letters. The first five words are starting points. The sixth is the die: its position modulo 5, plus 1, is the strategy it chooses when nobody else does. If the dictionary file is missing, say so and stop; do not invent words.

When the user says more, draw five more from the same seed with a round number appended, `printf '%s2' "$SEED"` for the second round, then `3`, and number the new strategies on from the last. Nothing already shown is discarded.

### 4. Strategies

For each of the five words, write a chain of three hops, one line each: the word, what it brings to mind, what that brings to mind, what that brings to mind. Then, from the third hop only, a strategy for the task: three or four plain sentences saying what the result would be, the way you would tell a colleague across a desk. The strategy obeys every brief line. It does not obey your taste. If the third hop is a bad fit for the task, the strategy is still built from it; a bad fit made to work is the point. If you do not know the word, the first hop is what it looks or sounds like.

Write all five to `.entropy/strategies.txt` with a heredoc, numbered 1 to 5, each with its word and chain.

Read the five back before showing them. If two would give results a reader could not tell apart, the later one is rewritten from its own third hop until they differ.

### 5. Show

**Held constant.** Every brief line, in plain sentences. Two or three lines.

**Five ways in.** Each strategy under its number, with its word and chain on one line above it.

For short work, the results follow at once, one under each strategy, and the reply ends: pick one, or say more. For long work, the reply ends: a number, more, or go. Under both, one small line: the seed, and the die with its arithmetic, `doings 12660: 12660 mod 5 = 0, plus 1, strategy 1`, which is what go builds.

Then, unless the work is short or `--headless` was given, stop and wait.

### 6. Record, under `--log` only

```bash
jq -nc --arg ts "$TS" --arg seed "$SEED" --arg task "$TASK" --arg brief "$BRIEF" --arg pick "$PICK" --rawfile strategies .entropy/strategies.txt '{ts:$ts, seed:$seed, task:$task, brief:$brief, pick:$pick, strategies:$strategies}' >> .entropy/seeds.jsonl
```

`$PICK` is the number taken. Write `.entropy/current.json` with the same object.

### 7. Do the task and read it back

Build the strategy chosen, or all five for short work. Before presenting a result, check it in this order:

1. The brief. Run each test. A result that fails a brief line is wrong however well it follows the strategy.
2. The strategy. State one fact from the least prominent place in the result, the second paragraph, the footer, the button, the smallest label, and say which sentence of the strategy it shows. A fact that shows a different strategy, or the plain default, is a miss.
3. The other four. Search the result for the most specific words of the strategies not taken. A hit is a miss.

Rewrite until there are no misses. Do not mention the check in the output.

For visual work, render before reading: `"$CHROME" --headless --disable-gpu --hide-scrollbars --window-size=1280,800 --screenshot=shot.png "file://$PWD/page.html"`, or `npx playwright screenshot --viewport-size=1280,800 "file://$PWD/page.html" shot.png`, and look at the image with the Read tool. With no renderer, say so in one line and read the code. Delete `page.html` and `shot.png` afterward unless the deliverable is the file.

## Rules

- One seed at a time. A new inject replaces the old strategy. Saying more extends the current one.
- The scope is the deliverable named in the task. Work inside it follows the strategy; work outside it does not. When unclear, ask; under `--headless`, say you are applying it and let the user object.
- The user's standing rules and the brief win. The strategy varies taste inside that box and never overrides it.
- Variations are strategies. Five headlines from one strategy are five synonyms. Build one strategy several ways only when the user picks a number and asks for that.
- When delegating inside the scope, paste the brief and the chosen strategy from the reply into the subagent's prompt.
- Never soften the strategy later without saying so. If the user asks for a change, apply it and keep the rest.
