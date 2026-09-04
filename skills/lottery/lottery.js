export const meta = {
  name: 'entropy-lottery',
  description: 'Draw many strategies for one task, name what recurs, ban it, redraw, rank the survivors',
  phases: [{ title: 'Strategies' }, { title: 'Judge' }, { title: 'Build' }],
}

const { task, brief, words, ts, seed, model, judgeModel, keep, n, dir } = args
const bans = (args.bans || []).slice()

const STRATEGY = {
  type: 'object',
  properties: { chain: { type: 'string' }, strategy: { type: 'string' } },
  required: ['chain', 'strategy'],
}
const JUDGE = {
  type: 'object',
  properties: {
    shared: { type: 'array', items: { type: 'object', properties: { habit: { type: 'string' }, ban: { type: 'string' }, test: { type: 'string' }, members: { type: 'array', items: { type: 'integer' } } }, required: ['habit', 'ban', 'test', 'members'] } },
    strategies: { type: 'array', items: { type: 'object', properties: { id: { type: 'integer' }, distance: { type: 'integer' }, brief: { type: 'string', enum: ['pass', 'fail'] }, why: { type: 'string' } }, required: ['id', 'distance', 'brief', 'why'] } },
  },
  required: ['shared', 'strategies'],
}
const BUILT = { type: 'object', properties: { file: { type: 'string' }, note: { type: 'string' } }, required: ['file', 'note'] }

function hash(s) { let h = 2166136261; for (const c of s) { h ^= c.charCodeAt(0); h = Math.imul(h, 16777619) >>> 0 } return h }
function shuffle(arr, key) { const a = arr.slice(); let h = hash(key); for (let i = a.length - 1; i > 0; i--) { h = Math.imul(h ^ (h >>> 13), 1274126177) >>> 0; const j = h % (i + 1); [a[i], a[j]] = [a[j], a[i]] } return a }
const pad = id => String(id).padStart(2, '0')
const BANS_PER_ROUND = 3 // ponytail: fixed cap; make it a flag if a task ever needs more
const briefLines = () => [brief, ...bans.map(b => `${b.ban} Test: ${b.test}`)].filter(Boolean).join('\n')

if (args.mode === 'build') {
  const built = await parallel(args.survivors.map(s => () => agent(
    `Task: ${task}\n\nFixed by the user, every line a test the result must pass:\n${briefLines()}\n\nBuild exactly this strategy, no other:\n${s.strategy}\n\nWrite the result under ${dir}/build/${pad(s.id)}/ (mkdir -p first); a page goes in page.html. Before finishing, read it back in this order: 1. run each brief test; 2. state one fact from the least prominent place in the result and which sentence of the strategy it shows, a fact showing a different strategy or the plain default is a miss; 3. search the result for these words and count any hit as a miss: ${s.word}, ${s.chain}. Rewrite until there are no misses. Return the file path and one line on what the least prominent place shows.`,
    { label: `build ${pad(s.id)}`, phase: 'Build', model, schema: BUILT, agentType: 'general-purpose' },
  ).then(b => b && ({ id: s.id, ...b }))))
  return { built: built.filter(Boolean) }
}

const rounds = []
const roundCount = Math.ceil(words.length / n)
for (let r = 1; r <= roundCount; r++) {
  const roundWords = words.slice((r - 1) * n, r * n)
  const fixed = briefLines()
  log(`round ${r}: ${roundWords.length} words, ${bans.length} bans`)
  const strategies = (await parallel(roundWords.map((word, i) => () => {
    const id = (r - 1) * n + i + 1
    const file = `${dir}/round-${r}/${pad(id)}.md`
    return agent(
      `Run the skill entropy:inject with exactly these arguments: --headless --strategy --word ${word} ${task}\n\nThe user has fixed the lines below; treat each as a brief line with its test.\n${fixed}\n\nWrite your full reply, as it stands, to ${file} (mkdir -p the directory first). Then return the chain line and the strategy.`,
      { label: `word ${pad(id)}: ${word}`, phase: 'Strategies', model, schema: STRATEGY, agentType: 'general-purpose' },
    ).then(s => s && ({ id, word, file, ...s }))
  }))).filter(Boolean)
  if (strategies.length < 3) { log(`round ${r}: only ${strategies.length} strategies came back, stopping`); rounds.push({ r, strategies, judge: null }); break }

  const order = shuffle(strategies, `${seed}${r}`)
  const judge = await agent(
    `You are judging ${order.length} independent strategies written for the same brief, to find what they share.\n\nBrief:\n${task}\n${fixed}\n\nRead each file below with the Read tool. Judge only the strategy sentences; ignore the chain line, any held-constant lines, and any seed line.\n${order.map(s => `id ${s.id}: ${s.file}`).join('\n')}\n\nDo two things. First, name every feature three or more of the finished results would share if these strategies were built: a device, a structure, a material, a palette, a register, a conceit, an opening move, a stance. Judge what the result would be, never the wording or grammar of the strategy text itself. For each: habit, a plain description a reader could check; ban, one sentence in the negative imperative that forbids the habit itself and names no substitute (Do not let the house be the subject of the main clause; never Give the man the only active verb), because a substitute becomes the next round's habit; test, what a finished result must show or must not show, runnable by a reader or a grep on the result; members, the ids that share it. Second, for every id, score distance 1 to 10 (1 = sits in the middle of the crowd, 10 = nothing else here is like it), say pass or fail on the brief, and give one sentence why. Never say which strategy is best; that is not your job.\n\nWrite the JSON to ${dir}/round-${r}/judge.json and return the same object.`,
    { label: `judge round ${r}`, phase: 'Judge', model: judgeModel, effort: 'high', schema: JUDGE, agentType: 'general-purpose' },
  )
  rounds.push({ r, strategies, judge })
  if (!judge) { log(`round ${r}: no judge verdict`); break }
  const found = judge.shared.filter(h => h.members.length >= 3).sort((a, b) => b.members.length - a.members.length)
  const fresh = found.filter(h => !bans.some(b => b.habit === h.habit)).slice(0, BANS_PER_ROUND)
  log(`round ${r}: ${found.length} shared habits named, banning ${fresh.length}`)
  for (const h of fresh) bans.push({ habit: h.habit, ban: h.ban, test: h.test, round: r, members: h.members })
}

const pool = []
let failed = 0
for (const { strategies, judge } of rounds) {
  if (!judge) continue
  const habits = judge.shared.filter(h => h.members.length >= 3)
  for (const v of judge.strategies) {
    const s = strategies.find(x => x.id === v.id); if (!s) continue
    if (v.brief === 'fail') { failed++; continue }
    pool.push({ ...s, distance: v.distance, habits: habits.filter(h => h.members.includes(v.id)).length, why: v.why })
  }
}
pool.sort((a, b) => b.distance - a.distance || a.habits - b.habits || a.id - b.id)
const survivors = pool.slice(0, keep)
log(`dropped ${failed} for the brief; ${pool.length} left, keeping ${survivors.length}`)
return { rounds: rounds.map(({ r, strategies, judge }) => ({ r, n: strategies.length, judge })), bans, survivors, dropped: { brief: failed } }
