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

### 3. Derive the direction from the seed

Read the string closely. Look past the surface: repeated characters, runs of digits, case patterns, letters that spell fragments, numbers that suggest ratios, proportions, counts, or hue angles. Map what you find onto the axes from step 2. Each decision must trace back to something in the string.

Commit to what the seed points at. Use judgment only to make the direction good, never to steer it back toward the default. If the seed points somewhere strange, go there and make it work.

Write the direction as a short list: one line per axis, each stating the decision and the part of the seed that produced it. Before writing it down, check each axis against the user's standing rules (CLAUDE.md, active skills, the task's own constraints). Drop any axis that conflicts and say which one was dropped and why. Then add one line stating the scope: the deliverable the task named, which all later work inside it inherits. A task that names a whole (an app, a book, a brand) gives a wide scope. A task that names one piece (a commit message, a hero section) gives a narrow one.

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

If a task was given, do it now, in this same reply, under the direction. Do not stop after showing the direction. If no task was given, stop and say: the direction is set, say go, or run `/entropy:inject` again for a new seed.

## Rules

- One seed at a time. A new inject replaces the old direction. The log keeps history.
- The direction's scope is the deliverable named in the task. Work that is part of that deliverable inherits the direction. Work outside it is untouched unless the user says to apply the seed to it. A direction set with no task applies to everything until replaced. When it is unclear whether new work is inside the scope, ask with AskUserQuestion. If `--headless` was given, do not ask: say you are applying the direction and let the user object.
- To branch from an earlier point, copy its seed from `.entropy/seeds.jsonl` and run `/entropy:inject --seed <string>` in a fresh conversation.
- The user's standing rules win. The direction varies taste inside the box set by CLAUDE.md, the task's own constraints, accessibility, and correctness. It never overrides them.
- When delegating work inside the scope to a subagent, paste the seed and direction from `.entropy/current.json` into its prompt. Subagents cannot see this conversation.
- Never soften the direction later in the conversation without saying so. If the user asks for a change, apply it and keep the rest.
