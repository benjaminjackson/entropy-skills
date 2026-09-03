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
- `--seed <string> [task]`: skip generation and use the given string. If a line in `.entropy/seeds.jsonl` has this exact seed, reuse the menus recorded on that line and skip menu writing; only the hash and the picks are redone, so the direction comes out the same as before. If the seed is not in the log, write menus fresh as for a new seed, and say that the result will not match any earlier run.
- `--headless`: may be combined with any of the above. Never ask questions. Where the skill would ask, decide and state the decision instead. Once given, it stays on for the rest of the session.

Flags come first. Any text after the flags is the task. `--headless build a hero section` means: headless on, task is "build a hero section".
- `--current`: do not generate. Read `.entropy/current.json` and re-state its seed and direction so the rest of the conversation follows it. Use this when the direction was set many turns ago or the context was compacted. If the file is missing, say so and stop.

## Procedure

### 1. Get the seed

Unless `--seed` or `--current` was given, run:

```bash
openssl rand -base64 48
```

The output is the seed. Do not invent, edit, or shorten it. Do nothing else with it yet. The hash in step 3 takes the menus as input, so it cannot run until they exist.

### 2. Read the task and infer the domain

The task comes from the arguments, or from the conversation if the arguments are empty. Decide what kind of work it is and which axes carry variety there. Examples, not a fixed list:

- Visual design: palette, type pairing, layout grid, density, motion, imagery style, era or reference tradition.
- Prose: voice, point of view, sentence rhythm, structure, opening move, register, what to leave out.
- Naming and copy: sound, length, language of origin, metaphor family, tone.
- Code and architecture: module boundaries, naming scheme, data flow style, what is explicit versus implicit.
- Anything else: pick the three to six decisions that most shape how the result feels.

### 3. Enumerate options, then let the seed choose

Do not read the string for inspiration. Every random string looks alike to a model, so a reading lands in the same place every time. Instead, list the options first and let the seed pick.

Under `--seed` with a seed found in the log, do not write menus. Put the recorded menus back on disk exactly as they were, then go straight to the hash below:

```bash
mkdir -p .entropy && grep -F "\"seed\":\"$SEED\"" .entropy/seeds.jsonl | head -1 | jq -j .menus > .entropy/menus.txt
```

Otherwise, for each axis from step 2, write a numbered menu of 8 to 12 options, numbered from 0. A menu written from habit is the model's taste with a die attached, so two steps before listing:

1. Name the habit first. Before listing anything, write what you would do on this axis with no seed. That is option 0, and it gets exactly one slot.
2. Read the menu back before hashing. For every pair of options, ask whether a reader could tell them apart in the result. If not, they are one option; replace one of them.

The menu must span the whole space, not the neighborhood you would pick from yourself:

- Include the plain default. It is one option among many, so it wins rarely.
- Include the opposite of the default.
- Include options from different eras, cultures, registers, and traditions. Include at least two you would never choose on your own.
- Options on one axis must be far apart. Two shades of the same idea count as one option. Far apart means a reader could tell from the result alone which option was picked.
- Every option must be one that can be done well. Wide is not the same as bad. The menu spans the good work of many traditions, not the range from good to poor.
- One slot per habit. The model's own default takes one option on a menu, never several under different names. Cream, bone, linen, parchment, and unbleached paper are one ground, so a palette menu holds one warm-paper option, and the other nine grounds are somewhere else: white, black, a saturated field, grey, a cool tint, a pattern. The same rule for any axis: if two options would look alike in the result, they are one option.

Some axes are always on the list, because they are where the model's own taste hides. Register and Frame for every domain; the visual ones whenever the work is visual. Each names the decision, what a reader should be able to tell from the result, the model's own habit, which goes in one slot, and what the pick governs: the territory on the deliverable the axis is about. The options are written fresh each time under the rules above; the examples show how far apart options must sit, and are not the menu.

An option is a treatment, not a label. The pick governs every instance of what the axis is about, everywhere on the deliverable, footer and caption and button included. Anything in that territory that does not follow the pick is drift, and drift goes where the pick is not looking, into the least prominent instance: a folio in tracked capitals under a pick of no ornament, a refusal in the footer under a pick of plain claim, a second body paragraph in the house voice under any register but the house one. The habit line on every axis is also a ban. The marks that line names belong to slot 0 alone, and under any other pick none of them may appear anywhere in the territory, not in a stamp, an opener, a footer, or a caption. A mark of the habit on a page that picked something else is the habit wearing the pick as a costume, and it is drift whatever the pick is called. Each axis below says what it governs. That line is also the test for whether two axes overlap: two axes that govern the same territory are one axis.

- **Register**: what the sentences do. A reader should be able to say from one paragraph whether it addresses them, how long its sentences run, and whether it names things or evokes them. Governs every sentence, body and footer and button label included, not the headline alone. The quiet contemplative voice the model reaches for by itself is one option. Examples far apart: short declaratives with no adjectives and no address to the reader; contractions, asides, and questions put to the reader; numbers, units, and names of parts with no metaphor; long periodic sentences that hold the point until the end; second person imperative, one instruction per sentence; first person plural, a group speaking for itself; one extended metaphor carried through every sentence; formal third person with no contractions, as in a public notice; exclamations and superlatives plainly meant; understatement, every claim smaller than the truth.
- **Layout skeleton** (visual work only): the shape of the page before any styling. Frame changes the costume and leaves the body; this axis rolls the body. A reader should be able to draw the shape from across the room. Governs where every block sits, header to footer. Everything centered in one column is the habit and one option. Examples far apart: one word filling the viewport; full-width horizontal bands stacked top to bottom, each a different color; content pinned to the four corners with the middle empty; a hard vertical split, one side ground and one side content; a block rotated across the diagonal; a dense grid of equal cells; a narrow column against a wide empty field; a framed card centered on a patterned ground; a sidebar and a canvas; type running vertically down one edge; concentric rings; everything hung from one hard left margin with a ragged right.
- **Micro-type ornament** (visual work only): the small type and rules the page is dressed in. A reader should be able to say what the small type is doing and how it is set. Governs every piece of small type and every rule: eyebrow, folio, caption, label, stamp, meta bar. The habit, an uppercase letter-spaced eyebrow above the headline with a hairline rule and a tiny mono meta bar, is one option; none at all is another. Examples far apart: handwritten notes in the margin; heavy bars and boxes; running heads and page numbers as in a book; numbered section labels; footnote marks and small captions; rubber stamps and seals; drop caps and printer's ornaments; callout arrows and labels as in a diagram; ticket stubs, perforations, and barcodes; none at all.
- **Headline treatment** (visual work only): how the main line of type is set, as one move. A reader should be able to name the move. Governs the headline and every subhead. The habit, a giant flush-left headline with one phrase flipped to the accent color, is one option. Examples far apart: outlined or hollow letters; set at body size and surrounded by empty space; no headline at all, the copy carries the page; stacked one word per line filling the width; a justified block; rotated or vertical; broken across an image or shape; mixed sizes within one line; set in a box, ribbon, or badge; underlined by hand; repeated until it becomes a pattern; one letter enormous and the rest small.
- **Section rhythm** (visual work only): how the page is divided and paced. A reader should be able to say where the page breaks and whether the breaks are even. Governs every break from the top of the page to the footer. The habit, equal sections at equal padding on a centered column with a stat strip, is one option. Examples far apart: a single unbroken surface with no sections; one element bleeding off the edge; margins wider than the content; overlapping blocks; one wide band and many narrow ones; a deliberate break in the grid; dense at the top and empty below; a strict repeating grid of equal cells; elements pinned to the corners; a stat strip as the only division.
- **Surface** (visual work only): what the page's surfaces are made of. A reader should be able to say whether things look flat, raised, lit, glassy, or printed. Governs every edge and fill: panel, button, input, image frame, the smallest chip. The habit today is flat and hard-edged, no gradient, no shadow, no rounded corner, and it is one option; the older habit, the purple gradient with soft shadows and 16px corners, is another, and both can be done well. Examples far apart: flat and hard-edged; soft elevation with layered shadows; a gradient field the type sits on; glass and blur over a colored ground; hard black outlines on everything; paper grain or halftone texture; embossed or skeuomorphic; neon glow on dark; rounded and pillowy; a single material, such as brushed metal or fabric, rendered in CSS.
- **Content order** (visual work and copy only): what the reader meets first, second, and last. A reader should be able to say what the page led with and what it held back. Governs the order of every block, above and below the fold. This is an order of argument, not a shuffle of the elements: every option must still let the reader learn what the thing is and what to do next, and the option must fit the situation the reader is in when they arrive. A hero for a productivity app can lead with the reader's own day, a docs page cannot. The habit, name, then claim, then explanation, then button, is one option. Examples far apart: lead with the thing the product acts on and name the product last; lead with a proof, a number or a witness, and make the claim after; lead with the action, the button first and the reason under it; lead with a question the product answers; lead with the picture and let the copy caption it; lead with a scene the reader recognizes, then the claim; the claim alone with nothing else above the fold; lead with the price or the condition; lead with the name alone and hold the claim until the reader scrolls.
- **Conceit** (visual work and copy only): the device the copy presents its subject through. The subject stays what the task gave, the product or the reader's work; this axis rolls only the device. A reader should be able to name the device in a few words. Governs every place the subject is presented, headline to footer; a device that appears in one paragraph and not the others was not the pick. The habit, an accounted-for day with clock arithmetic ("one Tuesday", 1,440 minutes), is one option; no device, the plain claim, is another. Examples far apart: a count; a comparison to something unlike it; before and after; a single object stood for the whole; a rule or a law; a definition; a letter or a note; a list; a question the product answers; no device.
- **Copy stance** (visual work and copy only): what the words do toward the reader. A reader should be able to say whether they were told, asked, shown, or invited. Governs every line of copy, subhead and footer and button included. The habit, a wry refusal of what the product does not do ("no streaks, no badges"), is one option. Examples far apart: plain description of what it does; a question to the reader; a quotation or testimony; an instruction; a single claim stated once; a story in two sentences; a list of facts; an invitation; a promise with a condition; a warning; a definition as in a dictionary; two lines of dialogue.
- **Name** (visual work and copy, when the task does not supply a product or brand name): the shape of the name, rolled before the name is invented. A reader should be able to say what kind of word it is. Governs the name wherever it appears, wordmark to title tag to footer. The habit, one plain noun like Ledger, is one option. Examples far apart: a proper name of a person or place; a verb in the imperative; a phrase of three or more words; a coined word; two words joined; initials or an acronym; a number or a date; a word from another language; an ordinary word used in a new sense; a name with punctuation in it. Invent a name of the shape picked. Skip this axis when a name is given.
- **Imagery** (visual work only): what on the page is a picture rather than type. A reader should be able to say whether there is an image, what kind, and what it is of. Governs every picture on the page, icons and decorative shapes included, not the hero image alone. The habit, no image at all, a page of type and flat panels, is one option. Options must be buildable inside the deliverable's constraints: a CSS shape composition, an inline SVG line illustration, a repeating pattern or texture, a data figure, a single giant glyph or numeral treated as the image, and a photograph. For a photograph with no image file to hand, hotlink a seeded placeholder, `https://picsum.photos/seed/<first 8 characters of the seed>/1200/800`, so the same seed gives the same photo. Examples far apart: an SVG line drawing of the product's subject; a halftone pattern filling one panel; a full-bleed photograph with type over it; a CSS composition of circles and bars; a chart or figure drawn from real numbers; a single giant glyph or numeral as the picture; a map or diagram; a repeating icon wallpaper; a small photograph in a frame like a snapshot; no image.
- **Motion** (visual work only, when the medium moves): what animates. A reader should be able to say what moved and when. Governs everything that moves, hover states and transitions included. The habit, fade-up on scroll with hover lift on every card, is one option; nothing moves is another. Examples far apart: one element only; a marquee; motion on load, then still; nothing moves; a typewriter reveal on the headline; a slow ambient drift; hover states only; one loop that never stops; parallax layers; motion that follows the cursor; a single blink.
- **Frame**: the scene, speaker, structural device, or reference tradition the piece is built on. A reader should be able to name the tradition or the speaker. For prose and copy: who is speaking, from where, in what form. For visual design: the reference tradition. Governs every element the tradition has an opinion on: type, color, layout idiom, the form the copy takes. The habit, a domestic vignette in prose or cream editorial paper in design, is one option. The menu for visual work spans print, screen, and physical traditions, with at least three options from the web era, since a menu of print traditions gives every page the same flat retro look. Examples far apart, prose: a field note; a manifesto; a story told from a distance; a letter; a dialogue; an instruction manual; a catalogue entry; a dispatch; a riddle; a eulogy. Visual: Swiss modernism; a 2010s SaaS product page; an arcade cabinet; mid-century advertising; brutalist web; a scientific plate; folk print; an operating system dashboard; Y2K web; a corporate annual report; a transit sign; a theater poster; an app store listing; a museum wall label; a game HUD.

Write the menus to `.entropy/menus.txt` with a heredoc, one axis per line, options numbered from 0, exactly as shown to the user. Then turn the seed and the menus into numbers together:

```bash
{ printf '%s' "$SEED"; cat .entropy/menus.txt; } | shasum -a 256 | cut -c1-40 | fold -w2 | while read h; do echo $((16#$h)); done
```

This prints twenty numbers from 0 to 255, one per line. The menus are part of the input, so the numbers cannot exist before the menus do, and a menu edited after the numbers are known changes every number on every axis. Hash once, after the file is written; never hash the seed alone. Axis 1 uses the first number, axis 2 the second, and so on. The pick for an axis is that number modulo the size of its menu. Show the arithmetic for every axis, for example: `axis 3: 203 mod 9 = 5, option 5`. Do not adjust a pick after seeing it.

Commit to what was picked. Use judgment only to make the combination good, never to move a pick back toward the default. If the picks clash, make the clash work.

Write the direction as a short list: one line per axis, giving the option picked, its index, and the arithmetic. Before writing it down, check each axis against the user's standing rules (CLAUDE.md, active skills, the task's own constraints). Drop any axis that conflicts and say which one was dropped and why. Then add one line stating the scope: the deliverable the task named, which all later work inside it inherits. A task that names a whole (an app, a book, a brand) gives a wide scope. A task that names one piece (a commit message, a hero section) gives a narrow one.

### 4. Show seed and direction

Print the seed string and the direction list in the reply. Both are visible here. Do not put the seed string into the deliverable itself.

### 5. Record

Create `.entropy/` in the working directory if it does not exist. Then:

Append one line to `.entropy/seeds.jsonl`:

```json
{"ts":"<ISO 8601>","seed":"<seed>","task":"<task or empty>","scope":"<scope line>","direction":"<direction list as one string>","menus":"<the contents of .entropy/menus.txt>","from":"<ts of the log line replayed, or empty>"}
```

`menus` is the file the hash read, byte for byte, so a replay hashes the same input. Do not retype it; take it from the file:

```bash
jq -nc --arg ts "$TS" --arg seed "$SEED" --arg task "$TASK" --arg scope "$SCOPE" --arg dir "$DIRECTION" --arg from "$FROM" --rawfile menus .entropy/menus.txt '{ts:$ts, seed:$seed, task:$task, scope:$scope, direction:$dir, menus:$menus, from:$from}' >> .entropy/seeds.jsonl
```

`$FROM` is the `ts` of the log line replayed, or empty.

Write `.entropy/current.json` with the same object, replacing whatever was there.

If the working directory is a git repository and `.entropy/` is not yet ignored, ask with AskUserQuestion whether to add it to `.gitignore`. Under `--headless`, do not ask and do not change `.gitignore`.

Use `jq -n` or a heredoc so quotes and newlines inside the direction are escaped correctly.

### 6. Do the task, or wait

If a task was given, do it now, in this same reply, under the direction. Do not stop after showing the direction. Before presenting the result, read it back against the direction, one fact per axis, taken from the place the pick was least likely to reach: register from the last paragraph, not the first. A pick is random, but execution drifts back toward the habitual voice where the pick is not looking: the model picks conversational, writes the opening conversational, and lets the rest go lyrical. If any fact reads as a different option than the one picked, rewrite until it does not. Do not mention this check in the output.

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

From the image, or from the code if nothing rendered, state one fact per axis, read from the least prominent instance of what that axis governs, since that is where the habit goes: register from the second body paragraph and the footer, not the headline; ornament from the folio, a caption, or a label; surface from the button and the smallest panel; skeleton from the whole frame at arm's length; imagery from every picture, icons included; copy stance from the button and the small print; conceit from the last paragraph; the ground color from a corner pixel. State each fact in the words a reader would use, then compare it to the pick, and check the territory for any mark the axis's habit line names. A fact that reads as a different option than the one picked, or a mark of the habit under another pick, is a miss; rewrite until it does not. A pixel font on a two-column bone-paper split is not an arcade cabinet. Delete `page.html` and `shot.png` afterward unless the deliverable is the file itself. If no task was given, stop and say: the direction is set, say go, or run `/entropy:inject` again for a new seed.

## Rules

- One seed at a time. A new inject replaces the old direction. The log keeps history.
- The direction's scope is the deliverable named in the task. Work that is part of that deliverable inherits the direction. Work outside it is untouched unless the user says to apply the seed to it. A direction set with no task applies to everything until replaced. When it is unclear whether new work is inside the scope, ask with AskUserQuestion. If `--headless` was given, do not ask: say you are applying the direction and let the user object.
- To branch from an earlier point, run `/entropy:inject --seed <string>` in a fresh conversation in the same working directory, so the log with its menus is there to replay. A seed alone does not reproduce a direction; the menus do, because they are part of what is hashed. To branch in another directory, copy the whole log line into that directory's `.entropy/seeds.jsonl` first. Log lines written before the menus went into the hash replay to different picks; their `direction` field still records what was picked.
- The user's standing rules win. The direction varies taste inside the box set by CLAUDE.md, the task's own constraints, accessibility, and correctness. It never overrides them.
- When delegating work inside the scope to a subagent, paste the seed and direction from `.entropy/current.json` into its prompt. Subagents cannot see this conversation.
- Never soften the direction later in the conversation without saying so. If the user asks for a change, apply it and keep the rest.
