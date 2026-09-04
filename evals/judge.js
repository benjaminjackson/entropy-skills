export const meta = { name: 'entropy-judge', description: 'Score a set of responses to one brief for variety, several shuffled passes', phases: [{ title: 'Judge' }] }
// args: { task, items: [{shot?, code?, text?}], passes, judgeModel }
const { task, items, passes, judgeModel } = args
const VERDICT = { type: 'object', properties: { score: { type: 'integer', minimum: 1, maximum: 10 }, shared: { type: 'string' }, notes: { type: 'string' } }, required: ['score', 'shared', 'notes'] }
function hash(s) { let h = 2166136261; for (let i = 0; i < s.length; i++) { h ^= s.charCodeAt(i); h = Math.imul(h, 16777619) >>> 0 } return h }
function shuffle(arr, key) { const a = arr.slice(); for (let i = a.length - 1; i > 0; i--) { const j = hash(key + i) % (i + 1); [a[i], a[j]] = [a[j], a[i]] } return a }
const visual = items.some(it => it.shot)
const how = visual ? 'Open each screenshot with the Read tool and judge from what you see, using the code only for what a screenshot cannot show.' : 'Read each response with the Read tool.'
const results = await parallel(Array.from({ length: passes }, (_, p) => () => {
  const order = shuffle(items.map((_, i) => i), `pass${p + 1}`)
  const list = order.map((i, k) => { const it = items[i]; return `RESPONSE ${k + 1}: ` + (it.shot ? `screenshot ${it.shot}, code ${it.code}` : `file ${it.text}`) }).join('\n')
  return agent(`You are judging how varied a set of ${items.length} independent responses to the same brief is. Brief:\n\n${task}\n\nIgnore any preamble about seeds, menus, or creative direction; judge only the deliverable. Consider whichever axes fit the brief: palette, layout, typography, structure, voice, rhythm, sound, metaphor, tone, architecture.\n\n${how}\n\n${list}\n\nReturn {"score": <1-10, where 1 means the responses are near-identical and 10 means no two share an approach>, "shared": "<one sentence naming what most of them share, or 'nothing' if there is no clear shared habit>", "notes": "<two or three sentences on the spread>"}.`, { label: `judge pass ${p + 1}`, phase: 'Judge', model: judgeModel, effort: 'high', schema: VERDICT, agentType: 'general-purpose' }).then(v => v && ({ pass: p + 1, order, ...v }))
}))
const ok = results.filter(Boolean)
const mean = ok.reduce((a, r) => a + r.score, 0) / (ok.length || 1)
return { mean, passes: ok }
