# entropy

A Claude Code plugin with one skill: `/entropy:inject`.

Ask a model for a landing page and you get the same purple gradient every time. Ask for an opening sentence and you get the same wry present tense. Ask it to "be unique" and you get a different sameness. The model cannot act randomly. It predicts the most likely token, and "random-sounding" has a most likely token too.

The fix is to bring randomness in from outside. `/entropy:inject` runs `openssl rand -base64 48` in the shell, hashes the string into a position in the system dictionary, and hands the model a word it did not choose: "fanega", "shielding", "unrisen". The model writes a chain of three associations from the word and builds a strategy for the task from the last link. The word is the only random part. Everything after it is the model doing real work from a starting point it would never have picked.

The technique is String Seed of Thought, from [Sakana AI](https://sakana.ai/): randomness enters as selection, never as interpretation.

## Install

```
/plugin marketplace add benjaminjackson/entropy-skills
/plugin install entropy@entropy-skills
```

Needs `/usr/share/dict/words`. macOS has it. On Debian and Ubuntu it is the `wamerican` package.

## Use

One word, one strategy, one result:

```
/entropy:inject Write the opening sentence of a short story about a man who comes home to find his house repainted a color he did not choose.
```

Several, one word each:

```
/entropy:inject Write a hero headline and one-sentence subhead for a paid one-hour session that teaches immigrants how the US financial system works. Headline under 8 words. No coaching, guidance, or training. Give me 5 variations.
```

Short work, a line, a name, a paragraph, comes back in the same reply: what was held constant, the chain, the strategy, the result. Long work, a page or a module, stops after the strategy and waits for `go`. Say `more` at any point for the next word; nothing already shown is discarded.

Flags, all optional, before the task:

- `--seed <string>`: use this string instead of a fresh one. The same words come out.
- `--log`: write the run to `.entropy/seeds.jsonl` and `.entropy/current.json`. Off by default. Nothing touches disk without it.
- `--current`: re-state the logged brief and strategy after a long conversation or a compaction. Needs a run made with `--log`.
- `--headless`: never stop, never ask. For scripts. Turns `--log` on.
- `--word <word>`: skip the draw and use this word. `--strategy`: stop after the strategy. Both are for the lottery below.

## Lottery

One word gives one strategy that is not the default. It does not tell you what the default was. `/entropy:lottery` draws twenty-four words, writes one strategy each in twenty-four separate contexts, and has a judge name what they share. Whatever three or more share is the model's habit for this task. The strategies farthest from the crowd come back for you to pick from. A second round, `--rounds 2`, bans the top habits and draws again; in testing that moved all six strategies to the model's next default rather than spreading them, so it is a way to map the next layer, not a better pick.

```
/entropy:lottery Write the opening sentence of a short story about a man who comes home to find his house repainted a color he did not choose.
```

Flags: `--n` words per round (24), `--rounds` (1), `--keep` (6), `--build` to render the kept strategies before the pick, `--model` and `--judge-model` (opus), `--headless`, `--seed`. It uses the Claude Code Workflow tool; every strategy file and judge verdict lands under `.entropy/lottery/<ts>/`, and every named habit is appended to `.entropy/habits.jsonl`, one line each, so the habits build up per task over time.

A run with defaults is twenty-five Opus agents and about 1.2 million tokens, most of it input. On the story prompt it named twelve habits and returned six survivors that read nothing alike. Judged for variety against six plain runs of the same prompt, the six built survivors scored 6 against 2 on a design brief and 3 against 2 on a blog paragraph. Keep the strategy model the same as the one that will build; the habits found are that model's.

## What is held constant

Before the word is drawn, the skill writes down what the user has already fixed, in the user's words, with a test for each: a word count, a banned word to grep for, a voice file to match. That brief comes before the strategy and is checked first on the result. The word varies taste inside the brief and never overrides it, and the same goes for house style in CLAUDE.md.

## Why a word

The first version read the random string for patterns. Every base64 string looks the same to a model, so five seeds gave five near-identical directions. The second version had the model write menus of options on a dozen axes and hash the seed into picks. That measured well on a landing-page eval, 8.3 against a baseline of 2.0, and grew to 4,400 words of procedure. On the first real copy task with a person and a brief it produced ten honored picks and no line anyone would keep, because the decision that mattered, length, was on no menu, and because a headline built from ten independent picks is a collision, not a strategy.

A dictionary word fixes both. It is far from every other word in a way no menu option is, there are a hundred thousand of them, and the model reasons from it to one coherent strategy a person can read and argue with. The chain is shown so the user can see where the idea came from. The word itself does not appear in the result.

The history, with every eval and its numbers, is in `docs/history/spec-menus.md`. The current spec is `docs/SPEC.md`.

## Does it work

The menu version was measured over seventeen eval rounds on Opus; those numbers are in the history file. The word version has been tested by hand on a headline with a brief and a story opening, on Sonnet and Opus. On the headline, five words gave five strategies a copywriter could argue over: the session as translation, as a con exposed, as freedom, as a crossing, as plain mechanics. The judged regression on the design prompt has not been run yet.

`evals/run.sh` runs the same prompt in two arms, with and without the plugin, and judges the sets for variety. It takes `--model opus|sonnet|haiku`, `--runs`, `--passes`, `--jobs`, and `--arms with|without|both`. `evals/fidelity.sh` was written for the menu version and does not grade this one yet.
