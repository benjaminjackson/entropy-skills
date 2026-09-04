# Spec

This file is the source of truth. The skill and README are implementations of it and can be regenerated from it. When they disagree with this file, this file wins. When a decision changes, change it here first. The history of the earlier designs and their evals is in `history/spec-menus.md`; nothing there is current, and everything there was learned the expensive way.

## Intent

A language model cannot act randomly. Asked for something unique, it predicts the most likely "unique" and lands on the same result every run. Real variety has to come from outside the model. This plugin pulls a random string from the shell, turns it into a word from the dictionary, and makes the model reason from that word to a strategy for the task.

The plugin must work for any task where variety beats the default: visual design, prose, naming, code architecture. It must not be tied to one domain. It must be usable by a person in the middle of real work, with a brief, in one turn for small things.

## What must be true

1. The seed comes from `openssl rand -base64 48`. The model never invents, edits, or shortens it.
2. Before anything random happens, the skill writes the brief: what the user has already fixed, one line each, in the user's words, each with a test that can be run on the result. House style in CLAUDE.md and active skills count as brief lines. The seed never touches the brief.
3. The seed becomes words by arithmetic: a SHA-256 hash, cut into six 8-hex-digit numbers, each taken modulo the count of lowercase four-to-nine-letter words in `/usr/share/dict/words`. The draw is one shell line. The model never chooses or invents a word. If the dictionary is missing, the skill says so and stops.
4. From the word the model writes a chain of three associations, one line, and a strategy from the third hop only: three or four plain sentences saying what the result would be, obeying every brief line. A bad fit is made to work, not swapped for a better word. An unknown word starts from what it looks or sounds like.
5. One word, one strategy, one result by default. A task asking for N variations takes the first N words, one strategy and one result each. Five results from one strategy are five synonyms and are never the answer to "variations".
6. Short work, a line, a name, a paragraph, a function, is built in the same reply. Long work, a page, a module, a document, stops after the strategy and waits for `go` or `more`.
7. `more` takes the next unused word. Past the sixth, six more are drawn from the seed with a round number appended. Nothing already shown is discarded. A new inject replaces the strategy; `more` extends it.
8. The reply leads with what is held constant, in plain sentences, then the chain, then the strategy, then the result. The seed sits in one small line at the end. It never appears in the result.
9. The result is read back in order: the brief's tests first; then one fact from the least prominent place in the result, tied to a sentence of the strategy; then a search for the word and its hops, which are reasoning and not decoration. Any miss is rewritten before the result is shown. Visual work is rendered and looked at before reading.
10. Nothing is written to disk without `--log`. Under `--log`, one line per run goes to `.entropy/seeds.jsonl` and the same object to `.entropy/current.json`, with the strategies file beside them. `--current` re-states a logged run. `--headless` never stops or asks and turns `--log` on, for scripts.
11. `--seed <string>` reuses a string, so the same words come out. The strategy is written fresh; the log is a record, not an input.
14. `--word <word>` skips the seed and the draw and uses the given word. `--strategy` ends the reply after the chain and the strategy, even under `--headless`. Both exist so another skill can run one draw in a fresh context and read the strategy back.
12. There is no hook. Nothing reads `.entropy/` unless a flag asks.
13. The user's standing rules and the brief win over the word. Scope is the deliverable the task names; work outside it is untouched unless the user says otherwise. Subagents inside the scope get the brief and the strategy pasted in. The strategy is never softened later without saying so.

## The lottery

`/entropy:lottery` runs the draw many times and reads what repeats. What must be true:

1. Every strategy comes from its own context, one agent per word, each running `/entropy:inject --headless --strategy --word <word>`. Several strategies in one call are never a round; a model that sees the others avoids repeating them and the habit hides.
2. The strategies come from the model that will build. The habits found are that model's habits. The default is opus for strategies, judge, and builds.
3. One judge per round reads the round's strategies in shuffled order and returns, by schema, every feature three or more of the finished results would share, each with a ban written as a negative imperative that names no substitute and a test that runs on the result, and a distance score and a brief pass or fail for every strategy. It judges the result the strategy would make, never the strategy's prose. It never says which is best.
4. One round by default. With `--rounds 2`, the three most shared habits become brief lines, the judge's ban and test, for the next round. More bans than that and the next round writes a checklist instead of a strategy; a described habit passed as `Do not: <description>` reads as an instruction to do it. Bans come from data, not from the skill author.
5. Filtering and ranking are plain code: brief failures out, sort by distance, fewer shared habits as the tiebreak, keep K. Habit members are not dropped; with N draws and a threshold of three, every strategy shares something. No model touches the ranking.
6. The human picks from strategies. Builds happen after the pick, or before it only under `--build`.
7. Every file is written once, by the agent that made it: `round-<r>/<NN>.md` by the strategy agent, `round-<r>/judge.json` by the judge, under `.entropy/lottery/<ts>/`. The lottery always writes; the files are the deliverable.
8. One line per named habit is appended to `.entropy/habits.jsonl`, never rewritten. This is the atlas of what the model reaches for, task by task.
9. The word draw, the brief, and the read-back are inject's, unchanged. The lottery adds a loop around inject, not a second procedure.

## Decisions and why

**A word, not a reading of the string.** The first skill read the string for patterns. Five seeds gave five near-identical directions, hard consonant names and ledger metaphors and bone paper, because every base64 string looks the same to a model and its reading of it is not random. Randomness has to enter as selection. A dictionary position is a selection the model cannot argue with, and a word is a starting point that carries meaning.

**A word, not menus.** The second skill made the model write menus on a dozen axes and hash the seed into picks. It measured 8.3 against 2.0 on a landing-page judge and grew to 4,400 words. It failed the first real copy task: ten picks honored per line, no line worth keeping. Two causes. The decision that mattered, length, was not an axis, and could not have been, because the axes were written for pages. And a line built from ten independent picks is a collision, not a strategy. The word gives one coherent strategy a person can read and judge. It costs reach: menus forced "arcade cabinet" onto a page, and a word can only go where association takes it. For work with a brief and a person, coherent beats forced.

**Three hops, then stop, then build from the third only.** Free association with no fixed length lets the model associate until it finds something it likes, and what it likes is the habit. Three hops is far enough to leave the word and short enough to stay legible. Building from the third hop only, whether or not it fits, is what keeps taste out of the choice.

**Numbers were considered and rejected.** A number from 1 to 100 as the starting point has perhaps thirty distinct associations, seven to sins, thirteen to luck, and feeds the model's own favorite device, the counted day. A hundred thousand words do neither.

**The brief comes first.** The copy task that broke the menu version had the length target in context and the model doubled it anyway; thirty picks to honor crowded out one brief. The brief is written before the word, with tests, and checked before the strategy. The word never touches it.

**One by default.** Five strategies per call was the first shape and it worked, but the user reads one result at a time, and five results at once on a page is five pages. One word, one result, `more` for the next, and N variations when asked.

**Short work does not pause.** A headline costs less to build than a turn of waiting. A page does not. The pause exists so a person can say no to a strategy before it is built, which is where the menu version lost its user: thirty picks nobody saw until ten finished blocks landed.

**Nothing on disk by default.** The log, replay, current, hook, and gitignore question were built on day one for a workflow nobody used. A hook that fired on every prompt to say "read the state file" cost more than the state was worth. They are behind `--log` now, and the hook is gone.

**The chain is shown, the word is not used.** The chain is what lets a person trust the strategy: "shielding, a lead apron at the dentist, protection goes on before the harm, the fees are the invisible dose." The strategy that follows says what the page does and leaves the apron behind. The read-back searches for the word and the hops in the result, since a word on the page is decoration wearing the strategy as a costume.

**The evals are a regression check, not a compass.** Seventeen rounds on one landing-page prompt with a model as judge optimized for what the judge liked, which was the same paper and risograph the model drifts to anyway, and never saw a brief or a person. Score sat at 8 for two days and 3,000 words. No skill change lands on a judge number alone from here. Every change is tried by hand on a real task with a brief first, and the eval only says whether it broke something.

**Strategies, not pages.** A strategy is about a hundred tokens and a page about twenty thousand. Twenty-four Opus strategies cost less than two pages, so the lottery can afford many draws, and what recurs in strategies is what would recur in pages: the design regression showed the shared ground, eyebrow, and copy conceit were all decided at the strategy level.

**Recurrence names the habit; the author does not.** Each territory pick, costume and skeleton, bought back one point on the design prompt and left the next habit standing. A ban moves a habit only once it is named, and the list of habits differs per task. A judge names shared features reliably, nine of ten blind in the test session, and is unreliable at best. So the judge names and the human picks.

**Survivors come from volume and distance, not from bans.** Two six-word runs on the story prompt, one with positive bans (give the man the active verb, put in a voice, put in an outburst) and one with negative bans (do not write him as passive, never withhold his alarm, do not name the color flat). Round two converged both times: six of six first person or six of six scraping and cursing, four of six with the house key in hand. Forbid the top habit and the whole field takes the nearest exit together, the way cream gave way to Swiss white on the design prompt. What held both times was the distance ranking: four survivors a reader would call far apart, all on brief. So the default is one round of many draws, and a second round is a map of the model's next layer.

**Twenty-four is enough to read the field.** The first run at the default size, on the story prompt with no brief, named twelve habits with three or more members; the top three (the man's feelings kept out, the man kept outdoors, the color named flat) each covered eleven or twelve of twenty-four. Six survivors scored seven to nine, and each was the only strategy taking its stance: the wife as the painter, the house molted, thanks spoken before the shock, an observation form, a gift that becomes a debt, a deed. Two were dropped for the brief because their strategy risked a sentence with no repaint in it. The judge's habit counts matched the files on every survivor checked by hand.

**The lottery's pick scores 8 on the design prompt.** Same prompt as `evals/run.sh`, 24 words, six survivors built by the same model, screenshots judged three times with the run.sh wording (`evals/judge.js`): 8, 8, 8. Words alone scored 5.3 over five unselected runs; the menu version's best was 8.3. The judge named the shared skeleton every time, a tracked-caps wordmark over one big sentence and one button with no picture of the product, which is the next layer under the twenty-three-of-twenty-four physical-object conceit the strategy judge found. Two of the six pages had render faults, a headline past the fold and a stray band under the panel, which the build agents' read-back did not catch.

**A thin brief makes ugly pages, and no eval saw it.** The six pages above were varied and bad: no product to picture, a hundred-line cap, system fonts, no line about the screen. The design prompt is now a real brief: a named product, who it is for, the copy that must appear, a picture of the product, Google Fonts, 250 lines, a fold test at 1280x800, 16px body, WCAG AA. On that brief the strategy judge found paper ground 17 of 24, one ink plus one accent 17 of 24, seven identical day units 17 of 24, and three marks compared by length 16 of 24. The six built survivors all passed the fold on the first try and scored 8, 6, 7 for variety, mean 7. The judge's shared line every pass: cream ground, left copy stack, picture on the right; the pictures themselves are six different inventions. Lower than 8 and the pages are the first this project has made that a person would ship. The variety score never measured quality, and it must not become the compass.

**With beats without on both prompts, and prose moves less than design.** Fresh run, both arms, six items each, one Opus judge, three shuffled passes with the run.sh wording (`evals/judge.js`, which takes screenshots or text files). Design, the Ledger brief: without 2, 2, 2; with 6, 6, 6. Prose, the sync paragraph: without 2, 2, 2; with 4, 3, 3. The plain runs converged past layout into wording, five of six pages with the same Fraunces-or-Instrument-Serif over Inter on cream with one forest green, five of six paragraphs with the same "no wondering which copy is the real one" clause. The lottery moved the design picture (a time-card rack, a struck-through ledger, one day blown up) but not the shell, and moved the prose anecdote but not the voice: all six paragraphs second person, past pain then a dated pivot, a flat close. The strategy judge had named that voice as habit; six survivors chosen by distance still all carried it, because every one of the twenty-four did. A habit with twenty-four members has no survivor to pick, so on prose the next layer needs a ban, not a bigger draw.

**Same model for strategies and builds.** Cheaper strategy agents would give the cheaper model's atlas. There is nothing to save at a hundred tokens each.

## What the eval must show

The claim is still: outputs vary more with the skill than without. `evals/run.sh` runs the same prompt in two arms and judges the sets for variety on Opus, never Fable, three shuffled passes, `--jobs` capped so the machine stays usable, `--arms with` to run one arm alone. The word version has not been through it yet. The menu version's design score was 8.3 against 2.0; the word version may score lower on that prompt, since a word has less reach than a forced menu, and a drop to 7 is acceptable if the hand tests hold.

`evals/fidelity.sh` was written for menus and per-axis picks and does not apply. What a fidelity check for this version must ask, per run: did every brief test pass; does the least prominent place in the result show the strategy; do the word and its hops appear in the result. It has not been written.

The hand tests that stand in for a person until then: a headline with a length cap, banned words, and a voice; a story opening with no brief. Both were run on this version. The headline gave five strategies a copywriter could argue over. The story opening gave a sentence from a strategy nobody would have reached for.

## Files

- `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`: manifests.
- `skills/inject/SKILL.md`: the procedure, items 1 through 14.
- `skills/lottery/SKILL.md`, `skills/lottery/lottery.js`: the loop around inject and the Workflow script that runs it.
- `evals/run.sh`, `evals/tells.sh`, `evals/judge.js`: variety eval, tell counter, and the judge for a set of files; all still apply.
- `evals/fidelity.sh`: menu-era fidelity check; kept for the history, not applicable.
- `docs/history/spec-menus.md`: the earlier specs and every eval through round 17.
- `README.md`: install and usage.
