---
name: inject
description: Inject a random seed into any creative task (visual design, prose, naming, code architecture, anything where variety beats the default) so the result does not regress to the mean. Use when the user runs /entropy:inject, asks for "something different", "surprise me", "not the usual", or wants several distinct takes on the same brief.
argument-hint: "[task] | --seed <string> [task] | --current"
---

# Entropy: inject

A model cannot act randomly. Asked for "something unique", it predicts tokens that sound random and lands on the same purple gradient every time. Real variety has to come from outside the model. This skill pulls a random string from the shell and uses it as the source of every creative decision.

Based on String Seed of Thought (Sakana AI).

## Arguments

`$ARGUMENTS` is one of:

- Empty: generate a new seed, derive a direction, show it, then stop and wait.
- `<task>`: generate a new seed, derive a direction, show it, then do the task.
- `--seed <string> [task]`: skip generation and use the given string. Everything else is the same.
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

Write the direction as a short list: one line per axis, each stating the decision and the part of the seed that produced it.

### 4. Show seed and direction

Print the seed string and the direction list in the reply. Both are visible here. Do not put the seed string into the deliverable itself.

### 5. Record

Create `.entropy/` in the working directory if it does not exist. Then:

Append one line to `.entropy/seeds.jsonl`:

```json
{"ts":"<ISO 8601>","seed":"<seed>","task":"<task or empty>","direction":"<direction list as one string>"}
```

Write `.entropy/current.json` with the same object, replacing whatever was there.

Use `jq -n` or a heredoc so quotes and newlines inside the direction are escaped correctly.

### 6. Do the task, or wait

If a task was given, do it now under the direction. If not, stop and say: the direction is set, say go, or run `/entropy:inject` again for a new seed.

## Rules

- One seed at a time. A new inject replaces the old direction. The log keeps history.
- To branch from an earlier point, copy its seed from `.entropy/seeds.jsonl` and run `/entropy:inject --seed <string>` in a fresh conversation.
- Never soften the direction later in the conversation without saying so. If the user asks for a change, apply it and keep the rest.
