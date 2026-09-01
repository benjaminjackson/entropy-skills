# Spec

This file is the source of truth. The skill, hook, and README are implementations of it and can be regenerated from it. When they disagree with this file, this file wins. When a decision changes, change it here first.

## Intent

A language model cannot act randomly. Asked for something unique, it predicts the most likely "unique" and lands on the same result every run. Real variety has to come from outside the model. This plugin pulls a random string from the shell and makes the model derive every creative decision from that string, so each run starts from a different place. The technique is String Seed of Thought (Sakana AI).

The plugin must work for any task where variety beats the default: visual design, prose, naming, code architecture. It must not be tied to one domain.

## What must be true

1. `/entropy:inject` gets its seed from `openssl rand -base64 48`. The model never invents, edits, or shortens it.
2. The model reads the task, infers the domain, picks the three to six decisions that most shape the result in that domain, and derives each one from a pattern in the string. Every decision traces back to the string.
3. The model commits to where the seed points. Judgment makes the direction good. Judgment never steers it back toward the default.
4. The seed and the derived direction are both shown in chat. The seed string never appears in the deliverable.
5. Every inject appends one JSON line to `.entropy/seeds.jsonl` (timestamp, seed, task, scope, direction) and overwrites `.entropy/current.json` with the same object.
6. With a task in the arguments, the skill does the task after showing the direction. With no task, it stops and waits.
7. `--seed <string>` replays a seed from the log. The direction is derived again from the string, not copied from the log; the logged direction is a record, not an input. `--current` re-states the direction in `current.json` without generating. `--headless` suppresses every question for the rest of the session.
8. A direction ends with a scope line: the deliverable named in the task. Work inside that deliverable inherits the direction. Work outside it does not, unless the user says so. No task means the scope is everything.
9. The user's standing rules win over the seed. Before the direction is written down, each axis is checked against CLAUDE.md, active skills, and the task's own constraints. Conflicting axes are dropped and named.
10. When the model delegates work inside the scope, it pastes the seed and direction into the subagent's prompt.
11. A hook prints a one-line reminder on every prompt while `current.json` exists, so the direction survives compaction. The reminder names the scope and tells the model to read the file. Text from the file is flattened and capped before it is echoed.
12. When it is unclear whether new work is inside the scope, the model asks. Under `--headless` it applies the direction and says so.
13. In a git repository where `.entropy/` is not ignored, the skill asks whether to add it to `.gitignore`. Under `--headless` it does not ask and does not touch the file.
14. The direction is never quietly softened later in the conversation. If the user asks for a change, the change is applied and the rest of the direction is kept.

## Decisions and why

**One seed at a time. A new inject replaces the old direction.** The simplest thing first. The log keeps history, and branching is done by copying a seed from the log into a fresh conversation with `--seed`. Forking the conversation itself does the same job, so a pipeline of branches inside the plugin is not a requirement.

**Deferred, and wanted later.** These came up in the interview and are planned, not rejected: layering a new seed on top of the current direction, selected by an argument, with replace as the default; rerolling one axis while keeping the rest; an outcome note on a log entry (kept, rejected, branched from), set by a separate skill. Each is an addition on top of the current shape, not a change to it.

**Scope is the deliverable the task names, not a leaky-or-scoped switch.** The first draft applied a direction to "later work of the same kind." That was wrong: a README and a commit message are the same kind, but the README is not part of that commit message. Mood and voice feel like they should leak because they belong to a whole, and the whole was what the task named. Sentence structure for one commit message should not leak because that message was the whole. Same rule, different noun. A user who wants a project-wide mood names the project in the task.

**The user's rules win.** The seed varies taste inside the box the user set. It never overrides house style, accessibility, correctness, or explicit constraints. This was violated once in practice: a "leave out motivation" axis pushed the why out of a commit body that the user's commit skill required. The check in item 9 exists because of that.

**Subagents get the direction pasted in.** They cannot see the conversation. Without this, delegated pieces silently revert to the default.

**The reminder hook is one line and telegraph-terse.** It runs on every prompt, so it must cost almost nothing when active and print nothing when not. It names the scope so the model knows when reading the file matters.

**`--headless` sticks for the session.** It exists for scripts. Passing it on every call is the failure mode it prevents.

**`.entropy/` is the user's call.** The log could be committed to share seeds with collaborators, or ignored as scratch. The skill asks once rather than deciding.

**Replay re-derives.** `--seed` runs the string through derivation again rather than loading the logged direction. This keeps the log a plain record and lets the same seed be read for a different task. The cost is that a replay may not reproduce the earlier direction exactly. Verbatim replay from the log is a possible later addition.

**Derivation may regress to the mean too.** The string is random, but the model's reading of it may not be. It may always turn digit runs into counts and doubled letters into pairs. No fix yet. Watch `seeds.jsonl` after ten or more seeds and look for clustering before designing one.

## What the eval must show

The claim is: outputs vary more with the skill than without. The eval runs the same open creative prompt several times in each of two arms, one with the plugin and one without, and a judge scores the set for distinctness of color, structure, voice, or whichever axes fit the prompt. The plugin arm must score higher. A regenerated skill that fails this is wrong, however faithful its wording.

The eval runs on Opus by default, never Fable. A model argument accepts `opus`, `sonnet`, or `haiku` so the same suite can check whether the skill holds up on smaller models.

A second check: every direction line in a run's output names the part of the seed it came from. A direction with untraceable decisions is the model falling back on its defaults.

## Files

- `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`: manifests.
- `skills/inject/SKILL.md`: the procedure, implementing items 1 through 13.
- `hooks/hooks.json`, `hooks/remind.sh`: the reminder, item 11.
- `README.md`: install and usage.
