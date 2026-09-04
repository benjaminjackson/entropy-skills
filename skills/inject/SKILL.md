---
name: inject
description: Inject a random seed into any creative task (visual design, prose, naming, code architecture, anything where variety beats the default) so the result does not regress to the mean. Use when the user runs /entropy:inject, asks for "something different", "surprise me", "not the usual", or wants several distinct takes on the same brief.
argument-hint: "[--headless] [--seed <string>] [task] | --current"
---

# Entropy: inject

A model cannot act randomly. Asked for "something unique", it predicts tokens that sound random and lands on the same purple gradient every time. Real variety has to come from outside the model. This skill pulls a random string from the shell, writes menus of options, and lets arithmetic on the string choose.

Based on String Seed of Thought (Sakana AI).

This is a tool for widening the field: a first draft, a whole page, several distinct takes. When the user is narrowing toward one line and has already written a candidate, say so in one sentence and offer a roll on one axis only.

## Arguments

`$ARGUMENTS` is one of:

- Empty: new seed, direction shown, then stop and wait.
- `<task>`: new seed, direction shown, then do the task.
- `--seed <string> [task]`: use the given string. If a line in `.entropy/seeds.jsonl` has this exact seed, put its recorded sketch and menus back on disk and skip to the hash, so the picks come out the same. If not, proceed as for a new seed and say the result will not match any earlier run.
- `--current`: do not generate. Read `.entropy/current.json` and re-state its seed, brief, and direction so the rest of the conversation follows them. If the file is missing, say so and stop.
- `--headless`: combine with any of the above. Never ask questions; decide and state the decision. Stays on for the session.

Flags come first. Text after the flags is the task.

## Procedure

### 1. Seed

```bash
openssl rand -base64 48
```

Do not invent, edit, or shorten it. Do nothing else with it yet. The hash takes the menus as input, so it cannot run until they exist.

### 2. Brief

List what the user has already fixed, one line each, in their words: a length, a required word, a banned word, a voice or brand file, an example to match. Give each line a test that can be run on the result: a word count, a grep, a file to compare against. The brief is not an axis. The seed never touches it. If nothing is fixed, write `brief: none`.

### 3. Sketch the habit

A model cannot report its habit; it can only perform it. Write what you would build for this task if asked for something unusual and given no seed, one short line per decision that shapes the result. As many decisions as the result has room to show, and no more: three for a line or a name, six for a paragraph or a function, ten for a page or a module. Ten picks on eight words is a line nobody would write. For a page: the name, the headline, the opening line, the device the copy uses, the ground color, the small type, the image, the surface, what the reader meets first, the frame. For a headline: the speaker, the device, the sentence shape. For prose: the length, the opening move, the sentence shape, the speaker, the device, what is left out. For code: the module boundaries, the naming scheme, the data flow. Then the same decisions again: what you would build to get away from all of that. Then once more: what you would build to get away from both. Three layers, each as fixed a habit as the first. Write them to `.entropy/sketch.txt` with a heredoc, labeled layer one, two, three.

Under `--seed` with a seed found in the log, restore instead of writing:

```bash
mkdir -p .entropy && grep -F "\"seed\":\"$SEED\"" .entropy/seeds.jsonl | head -1 | jq -j .sketch > .entropy/sketch.txt
grep -F "\"seed\":\"$SEED\"" .entropy/seeds.jsonl | head -1 | jq -j .menus > .entropy/menus.txt
```

### 4. Menus, then the hash

The decisions in the sketch are the axes. Drop any the brief fixes and say so. For each remaining axis write a menu of 8 to 12 options, numbered from 0. Options 0, 1, and 2 are what the three layers show on that axis, in the sketch's own words, one slot each. The rest must be far apart: a reader could tell from the result alone which was picked, and two shades of one idea are one option. Include the opposite of the default, options from other eras and traditions, and at least two you would never choose. Every option must be one that can be done well. An option is a treatment, not a label: the pick governs every instance of what the axis is about, the footer and the caption and the button included.

Write the menus to `.entropy/menus.txt` with a heredoc, one axis per line, exactly as shown to the user. Then hash the seed and the menus together, once:

```bash
{ printf '%s' "$SEED"; cat .entropy/menus.txt; } | shasum -a 256 | cut -c1-40 | fold -w2 | while read h; do echo $((16#$h)); done
```

Twenty numbers from 0 to 255. Axis 1 takes the first, axis 2 the second, and so on. The pick is the number modulo the menu size. Show the arithmetic for every axis: `axis 3: 203 mod 9 = 5, option 5`. Never hash the seed alone, and never edit a menu after the numbers exist; the menus are in the hash, so an edit re-rolls every axis. Do not adjust a pick after seeing it. If picks clash, make the clash work.

When the user asks for several variations, roll once. The variations differ on one axis, one option each in menu order from the pick; everything else holds.

### 5. Show

Print the seed, the brief, and the direction: one line per axis with the option, its index, and the arithmetic, then one line stating the scope, the deliverable the task named. Do not put the seed into the deliverable.

### 6. Record

```bash
mkdir -p .entropy
jq -nc --arg ts "$TS" --arg seed "$SEED" --arg task "$TASK" --arg scope "$SCOPE" --arg brief "$BRIEF" --arg dir "$DIRECTION" --arg from "$FROM" --rawfile menus .entropy/menus.txt --rawfile sketch .entropy/sketch.txt '{ts:$ts, seed:$seed, task:$task, scope:$scope, brief:$brief, direction:$dir, menus:$menus, sketch:$sketch, from:$from}' >> .entropy/seeds.jsonl
```

`$FROM` is the `ts` of the line replayed, or empty. Write `.entropy/current.json` with the same object. If the directory is a git repository and `.entropy/` is not ignored, ask whether to add it to `.gitignore`; under `--headless`, do not ask and do not change it.

### 7. Do the task and read it back

If a task was given, do it now, in this same reply. If not, stop and say the direction is set.

Before presenting the result, check it in this order:

1. The brief. Run each test. A result that fails a brief line is wrong however well it honors the seed.
2. The picks. State one fact per axis, read from the least prominent instance of what the axis governs, since that is where the habit goes: register from the second body paragraph and the footer, not the headline; small type from a folio or caption; surface from the button and the smallest panel; the ground from a corner pixel. A fact that reads as a different option than the one picked is a miss.
3. The sketch. Take the ten most specific words from each layer in `.entropy/sketch.txt` and search the result with `grep -ci`. A hit on an axis whose pick was not the slot that layer fed is a miss, whatever the pick is called.

Rewrite until there are no misses. Do not mention the check in the output.

For visual work, render before reading: headless Chrome, `"$CHROME" --headless --disable-gpu --hide-scrollbars --window-size=1280,800 --screenshot=shot.png "file://$PWD/page.html"`, or `npx playwright screenshot --viewport-size=1280,800 "file://$PWD/page.html" shot.png`, and look at the image with the Read tool. `magick shot.png -format '%[pixel:p{0,0}]' info:` gives the corner pixel. With no renderer, say so in one line and read the code. Delete `page.html` and `shot.png` afterward unless the deliverable is the file.

## Rules

- One seed at a time. A new inject replaces the old direction. The log keeps history.
- The scope is the deliverable named in the task. Work inside it inherits the direction; work outside it does not. When unclear, ask; under `--headless`, say you are applying it and let the user object.
- The user's standing rules and the brief win. The direction varies taste inside that box and never overrides it.
- To replay, run `/entropy:inject --seed <string>` in the same directory, where the log holds the sketch and menus. A seed alone does not reproduce a direction. To replay elsewhere, copy the whole log line first.
- When delegating inside the scope, paste seed, brief, and direction from `.entropy/current.json` into the subagent's prompt.
- Never soften the direction later without saying so. If the user asks for a change, apply it and keep the rest.
