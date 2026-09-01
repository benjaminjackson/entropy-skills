---
name: inject
description: Inject a random seed into any creative task (visual design, prose, naming, code architecture, anything where variety beats the default) so the result does not regress to the mean. Use when the user runs /entropy:inject, asks for "something different", "surprise me", "not the usual", or wants several distinct takes on the same brief.
argument-hint: "[--headless] [--seed <string>] [task] | --current"
---

# Entropy: inject

A model cannot act randomly. Asked for "something unique", it predicts tokens that sound random and lands on the same purple gradient every time. Real variety has to come from outside the model. This skill pulls a random string from the shell and uses it as the source of every creative decision.

Based on String Seed of Thought (Sakana AI).

## Arguments

`$ARGUMENTS` is one of:

- Empty: generate a new seed, derive a direction, show it, then stop and wait.
- `<task>`: generate a new seed, derive a direction, show it, then do the task.
- `--seed <string> [task]`: skip generation and use the given string. Everything else is the same.
- `--headless`: may be combined with any of the above. Never ask questions. Where the skill would ask, decide and state the decision instead. Once given, it stays on for the rest of the session.

Flags come first. Any text after the flags is the task. `--headless build a hero section` means: headless on, task is "build a hero section".
- `--current`: do not generate. Read `.entropy/current.json` and re-state its seed and direction so the rest of the conversation follows it. Use this when the direction was set many turns ago or the context was compacted. If the file is missing, say so and stop.

## Procedure

### 1. Get the seed

Unless `--seed` or `--current` was given, run:

```bash
openssl rand -base64 48
```

The output is the seed. Do not invent, edit, or shorten it.

### 2. Read the task and infer the domain

The task comes from the arguments, or from the conversation if the arguments are empty. Decide what kind of work it is and which axes carry variety there. Examples, not a fixed list:

- Visual design: palette, type pairing, layout grid, density, motion, imagery style, era or reference tradition.
- Prose: voice, point of view, sentence rhythm, structure, opening move, register, what to leave out.
- Naming and copy: sound, length, language of origin, metaphor family, tone.
- Code and architecture: module boundaries, naming scheme, data flow style, what is explicit versus implicit.
- Anything else: pick the three to six decisions that most shape how the result feels.

### 3. Enumerate options, then let the seed choose

Do not read the string for inspiration. Every random string looks alike to a model, so a reading lands in the same place every time. Instead, list the options first and let the seed pick.

For each axis from step 2, write a numbered menu of 8 to 12 options, numbered from 0. The menu must span the whole space, not the neighborhood you would pick from yourself:

- Include the plain default. It is one option among many, so it wins rarely.
- Include the opposite of the default.
- Include options from different eras, cultures, registers, and traditions. Include at least two you would never choose on your own.
- Options on one axis must be far apart. Two shades of the same idea count as one option. Far apart means a reader could tell from the result alone which option was picked.
- Every option must be one that can be done well. Wide is not the same as bad. The menu spans the good work of many traditions, not the range from good to poor.

Two axes are always on the list, whatever the domain, because they are where the model's own taste hides:

- **Register**: the voice or attitude of the piece. The menu must span at least these, each of which has a tradition of excellent work: warm, dry and witty, exuberant, austere, lyrical, plainspoken and technical, conversational, formal editorial, grand or mythic, wry and understated. The quiet contemplative voice the model reaches for by itself is one of ten.
- **Layout skeleton** (visual work only): the shape of the page or composition before any styling. Frame alone changes the costume and leaves the body; this axis rolls the body. Options must be named shapes: centered stack, asymmetric split, full-bleed image with type over it, single giant word, poster grid, editorial columns, diagonal or rotated block, stacked horizontal bands, sidebar and canvas, typographic wall, framed card on a patterned ground.
- **Frame**: the scene, speaker, structural device, or reference tradition the piece is built on. For prose and copy: who is speaking, from where, in what form (a letter, a field note, a manifesto, a dialogue, an instruction, a story told from a distance). For visual design: the reference tradition (Swiss modernism, mid-century advertising, brutalism, scientific illustration, editorial magazine, arcade, folk print, corporate annual report, Bauhaus, contemporary product). The model's habitual frame, a domestic vignette in prose or cream editorial paper in design, is one option among many.

Then turn the seed into numbers. Run:

```bash
printf '%s' "$SEED" | shasum -a 256 | cut -c1-24 | fold -w2 | while read h; do echo $((16#$h)); done
```

This prints twelve numbers from 0 to 255, one per line. Axis 1 uses the first number, axis 2 the second, and so on. The pick for an axis is that number modulo the size of its menu. Show the arithmetic for every axis, for example: `axis 3: 203 mod 9 = 5, option 5`. Do not adjust a pick after seeing it.

Commit to what was picked. Use judgment only to make the combination good, never to move a pick back toward the default. If the picks clash, make the clash work.

Write the direction as a short list: one line per axis, giving the option picked, its index, and the arithmetic. Before writing it down, check each axis against the user's standing rules (CLAUDE.md, active skills, the task's own constraints). Drop any axis that conflicts and say which one was dropped and why. Then add one line stating the scope: the deliverable the task named, which all later work inside it inherits. A task that names a whole (an app, a book, a brand) gives a wide scope. A task that names one piece (a commit message, a hero section) gives a narrow one.

### 4. Show seed and direction

Print the seed string and the direction list in the reply. Both are visible here. Do not put the seed string into the deliverable itself.

### 5. Record

Create `.entropy/` in the working directory if it does not exist. Then:

Append one line to `.entropy/seeds.jsonl`:

```json
{"ts":"<ISO 8601>","seed":"<seed>","task":"<task or empty>","scope":"<scope line>","direction":"<direction list as one string>"}
```

Write `.entropy/current.json` with the same object, replacing whatever was there.

If the working directory is a git repository and `.entropy/` is not yet ignored, ask with AskUserQuestion whether to add it to `.gitignore`. Under `--headless`, do not ask and do not change `.gitignore`.

Use `jq -n` or a heredoc so quotes and newlines inside the direction are escaped correctly.

### 6. Do the task, or wait

If a task was given, do it now, in this same reply, under the direction. Do not stop after showing the direction. Before presenting the result, read it back against the direction, axis by axis, with the register pick first. A pick is random, but execution drifts back toward the habitual voice: the model picks conversational and writes lyrical. If the result reads as a different option than the one picked, rewrite it until it does not. Do not mention this check in the output.

For visual work the read-back is concrete, because a model reading its own CSS says yes to everything. Render the result and look at it with the Read tool. Take the first rung that works:

1. Headless Chrome or Chromium, if installed. macOS path: `/Applications/Google Chrome.app/Contents/MacOS/Google Chrome`. Linux: `google-chrome`, `chromium`, or `chromium-browser`.
   ```bash
   "$CHROME" --headless --disable-gpu --hide-scrollbars --window-size=1280,800 --screenshot=shot.png "file://$PWD/page.html"
   ```
2. Playwright, if `npx --no-install playwright --version` answers. If no browser is downloaded yet, run `npx playwright install chromium` once; it may fail behind a proxy, and that is the end of this rung.
   ```bash
   npx playwright screenshot --viewport-size=1280,800 page.html shot.png
   ```
3. No renderer. Say so in one line and read the code instead.

With a screenshot, ImageMagick gives the ground color without guessing, if present as `magick` (version 7) or `convert` (version 6):
```bash
magick shot.png -resize 1x1 -format '%[pixel:p{0,0}]' info:    # or: convert shot.png -resize 1x1 -format '%[pixel:p{0,0}]' info:
```

From the image, or from the code if nothing rendered, state three facts: the ground color, the layout skeleton, and the type family actually used. Compare each to its pick. Rewrite if any differ. A pixel font on a two-column bone-paper split is not an arcade cabinet. Delete `page.html` and `shot.png` afterward unless the deliverable is the file itself. If no task was given, stop and say: the direction is set, say go, or run `/entropy:inject` again for a new seed.

## Rules

- One seed at a time. A new inject replaces the old direction. The log keeps history.
- The direction's scope is the deliverable named in the task. Work that is part of that deliverable inherits the direction. Work outside it is untouched unless the user says to apply the seed to it. A direction set with no task applies to everything until replaced. When it is unclear whether new work is inside the scope, ask with AskUserQuestion. If `--headless` was given, do not ask: say you are applying the direction and let the user object.
- To branch from an earlier point, copy its seed from `.entropy/seeds.jsonl` and run `/entropy:inject --seed <string>` in a fresh conversation.
- The user's standing rules win. The direction varies taste inside the box set by CLAUDE.md, the task's own constraints, accessibility, and correctness. It never overrides them.
- When delegating work inside the scope to a subagent, paste the seed and direction from `.entropy/current.json` into its prompt. Subagents cannot see this conversation.
- Never soften the direction later in the conversation without saying so. If the user asks for a change, apply it and keep the rest.
