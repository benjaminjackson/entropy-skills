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

For each axis from step 2, write a numbered menu of 8 to 12 options, numbered from 0. A menu written from habit is the model's taste with a die attached, so write each one in this order:

1. Name the habit first. Before listing anything, write what you would do on this axis with no seed. That is option 0, and it gets exactly one slot.
2. Name the goal of the axis. One sentence: what a reader should be able to tell from the result alone. If two options would read the same in the result, they are one option.
3. Walk traditions, not adjectives. Fill the other slots by asking who did this well in a different era, place, or medium. Bauhaus is an option; bold is not.
4. Check before rolling. Read the menu back: is the default in one slot, is there an option you would never pick, could you tell every pair apart in the result. Fix, then hash.

The menu must span the whole space, not the neighborhood you would pick from yourself:

- Include the plain default. It is one option among many, so it wins rarely.
- Include the opposite of the default.
- Include options from different eras, cultures, registers, and traditions. Include at least two you would never choose on your own.
- Options on one axis must be far apart. Two shades of the same idea count as one option. Far apart means a reader could tell from the result alone which option was picked.
- Every option must be one that can be done well. Wide is not the same as bad. The menu spans the good work of many traditions, not the range from good to poor.
- One slot per habit. The model's own default takes one option on a menu, never several under different names. Cream, bone, linen, parchment, and unbleached paper are one ground, so a palette menu holds one warm-paper option, and the other nine grounds are somewhere else: white, black, a saturated field, grey, a cool tint, a pattern. The same rule for any axis: if two options would look alike in the result, they are one option.

Some axes are always on the list, because they are where the model's own taste hides. Register and Frame for every domain; the visual ones whenever the work is visual:

- **Register**: the voice or attitude of the piece. The menu must span at least these, each of which has a tradition of excellent work: warm, dry and witty, exuberant, austere, lyrical, plainspoken and technical, conversational, formal editorial, grand or mythic, wry and understated. The quiet contemplative voice the model reaches for by itself is one of ten.
- **Layout skeleton** (visual work only): the shape of the page or composition before any styling. Frame alone changes the costume and leaves the body; this axis rolls the body. Options must be named shapes: centered stack, asymmetric split, full-bleed image with type over it, single giant word, poster grid, editorial columns, diagonal or rotated block, stacked horizontal bands, sidebar and canvas, typographic wall, framed card on a patterned ground.
- **Micro-type ornament** (visual work only): the small type and rules the page is dressed in. Left to itself the model puts an uppercase letter-spaced eyebrow above every headline, a hairline rule under it, and a tiny mono meta bar; that is one option. Menu: none at all, uppercase eyebrow and hairline rules, numbered section labels, handwritten or marginal notes, heavy bars and boxes, footnote marks and small captions, running heads and folios as in a book, stamps and stickers, drop caps and ornaments, callout arrows and labels as in a diagram. The pick governs the treatment of every piece of small type on the page, not only the name of the ornament: uppercase letter-spaced small type is allowed only when the eyebrow option was picked. Under every other pick, stamps, running heads, folios, captions, and labels are set in sentence case at body size or larger, with no tracking. A stamp set in tiny tracked capitals is the eyebrow wearing a costume.
- **Headline treatment** (visual work only): how the main line of type is set. The model's own move, a giant flush-left headline with one phrase flipped to the accent color, is one option. Menu: one word in accent color, all one color and one weight, outlined or hollow, stacked one word per line, justified block, set small and surrounded by space, rotated or vertical, broken across an image or shape, mixed sizes within one line, set in a box or ribbon, underlined by hand, no headline at all with the copy carrying the page.
- **Section rhythm** (visual work only): how the page is divided and paced. The model's default, equal sections at equal padding on a centered 1200px column, with a three or four figure stat strip, is one option. Menu: equal sections on a centered column, one element bleeding off the edge, overlapping blocks, a single unbroken surface with no sections, one wide and many narrow, a deliberate break in the grid, dense top and empty bottom, margins wider than the content, elements pinned to corners, a stat strip or figure row as the only division.
- **Copy stance** (visual work and copy only): the attitude of the words toward the reader. The model's habit, a wry refusal of what the product does not do ("no streaks, no badges"), is one option. The pick governs every line of copy on the page, subhead and footer and button included, not only the headline. A refusal ("no streaks, no notifications") anywhere on a page that did not pick refusal is drift. Menu: refusal of the category's habits, plain description of what it does, a single claim stated once, a question to the reader, an instruction, a quotation or testimony, a story in two sentences, a list of facts, an invitation, a promise with a condition.
- **Name** (visual work and copy, when the task does not supply a product or brand name): the model's own names are one plain noun, and Ledger comes up in one run of four. Roll the name's shape rather than the name: a plain noun, a coined word, two words joined, a proper name of a person or place, a verb in the imperative, an acronym or initials, a number or a date, a phrase of three or more words, a word from another language, an ordinary word used in a new sense. Then invent a name of that shape. Skip this axis when a name is given.
- **Motion** (visual work only, when the medium moves): what animates. Fade-up on scroll with hover lift on every card is one option. Menu: nothing moves, one element only, typewriter or reveal on the headline, marquee, a slow ambient drift, hover states only, a single loop that never stops, motion on load then still, parallax layers, motion triggered by the cursor.
- **Frame**: the scene, speaker, structural device, or reference tradition the piece is built on. For prose and copy: who is speaking, from where, in what form (a letter, a field note, a manifesto, a dialogue, an instruction, a story told from a distance). For visual design: the reference tradition (Swiss modernism, mid-century advertising, brutalism, scientific illustration, editorial magazine, arcade, folk print, corporate annual report, Bauhaus, contemporary product). The model's habitual frame, a domestic vignette in prose or cream editorial paper in design, is one option among many.

Then turn the seed into numbers. Run:

```bash
printf '%s' "$SEED" | shasum -a 256 | cut -c1-40 | fold -w2 | while read h; do echo $((16#$h)); done
```

This prints twenty numbers from 0 to 255, one per line. Axis 1 uses the first number, axis 2 the second, and so on. The pick for an axis is that number modulo the size of its menu. Show the arithmetic for every axis, for example: `axis 3: 203 mod 9 = 5, option 5`. Do not adjust a pick after seeing it.

Commit to what was picked. Use judgment only to make the combination good, never to move a pick back toward the default. If the picks clash, make the clash work.

Write the direction as a short list: one line per axis, giving the option picked, its index, and the arithmetic. Before writing it down, check each axis against the user's standing rules (CLAUDE.md, active skills, the task's own constraints). Drop any axis that conflicts and say which one was dropped and why. Then add one line stating the scope: the deliverable the task named, which all later work inside it inherits. A task that names a whole (an app, a book, a brand) gives a wide scope. A task that names one piece (a commit message, a hero section) gives a narrow one.

### 4. Show seed and direction

Print the seed string and the direction list in the reply. Both are visible here. Do not put the seed string into the deliverable itself.

### 5. Record

Create `.entropy/` in the working directory if it does not exist. Then:

Append one line to `.entropy/seeds.jsonl`:

```json
{"ts":"<ISO 8601>","seed":"<seed>","task":"<task or empty>","scope":"<scope line>","direction":"<direction list as one string>","menus":"<every menu, one axis per line, options numbered>"}
```

Write `.entropy/current.json` with the same object, replacing whatever was there.

If the working directory is a git repository and `.entropy/` is not yet ignored, ask with AskUserQuestion whether to add it to `.gitignore`. Under `--headless`, do not ask and do not change `.gitignore`.

Use `jq -n` or a heredoc so quotes and newlines inside the direction are escaped correctly.

### 6. Do the task, or wait

If a task was given, do it now, in this same reply, under the direction. Do not stop after showing the direction. Before presenting the result, read it back against the direction, axis by axis, with the register pick first. A pick is random, but execution drifts back toward the habitual voice: the model picks conversational and writes lyrical. If the result reads as a different option than the one picked, rewrite it until it does not. Do not mention this check in the output.

For visual work the read-back is concrete, because a model reading its own CSS says yes to everything. Render the result and look at it with the Read tool. Take the first rung that works:

0. A browser tool in this session with a screenshot action (the built-in Claude Browser or Claude in Chrome), if it can reach the page. It runs on the user's machine, so it cannot open a file that lives only in a cloud container.
1. Headless Chrome or Chromium, if installed. macOS path: `/Applications/Google Chrome.app/Contents/MacOS/Google Chrome`. Linux: `google-chrome`, `chromium`, or `chromium-browser`.
   ```bash
   "$CHROME" --headless --disable-gpu --hide-scrollbars --window-size=1280,800 --screenshot=shot.png "file://$PWD/page.html"
   ```
2. Playwright, if `npx --no-install playwright --version` answers. The cloud container ships Chromium for it. Elsewhere, if no browser is downloaded yet, run `npx playwright install chromium` once; it may fail behind a proxy, and that is the end of this rung. The page must be given as a URL; a bare path is treated as a hostname.
   ```bash
   npx playwright screenshot --viewport-size=1280,800 "file://$PWD/page.html" shot.png
   ```
3. No renderer. Say so in one line and read the code instead.

With a screenshot, ImageMagick gives the ground color without guessing, if present as `magick` (version 7) or `convert` (version 6). Sample a corner, since averaging the frame lets the text tint the result:
```bash
magick shot.png -format '%[pixel:p{0,0}]' info:    # or: convert shot.png -format '%[pixel:p{0,0}]' info:
```

From the image, or from the code if nothing rendered, state four facts: the ground color, the layout skeleton, the type family actually used, and whether any small type is uppercase and letter-spaced. Compare each to its pick; uppercase tracked small type is a miss unless the eyebrow was picked. Then read every line of copy on the page, not only the headline, and name its stance; a refusal that was not picked is a miss. Rewrite if any differ. A pixel font on a two-column bone-paper split is not an arcade cabinet. Delete `page.html` and `shot.png` afterward unless the deliverable is the file itself. If no task was given, stop and say: the direction is set, say go, or run `/entropy:inject` again for a new seed.

## Rules

- One seed at a time. A new inject replaces the old direction. The log keeps history.
- The direction's scope is the deliverable named in the task. Work that is part of that deliverable inherits the direction. Work outside it is untouched unless the user says to apply the seed to it. A direction set with no task applies to everything until replaced. When it is unclear whether new work is inside the scope, ask with AskUserQuestion. If `--headless` was given, do not ask: say you are applying the direction and let the user object.
- To branch from an earlier point, copy its seed from `.entropy/seeds.jsonl` and run `/entropy:inject --seed <string>` in a fresh conversation.
- The user's standing rules win. The direction varies taste inside the box set by CLAUDE.md, the task's own constraints, accessibility, and correctness. It never overrides them.
- When delegating work inside the scope to a subagent, paste the seed and direction from `.entropy/current.json` into its prompt. Subagents cannot see this conversation.
- Never soften the direction later in the conversation without saying so. If the user asks for a change, apply it and keep the rest.
