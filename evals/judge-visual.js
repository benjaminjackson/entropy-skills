export const meta = { name: 'entropy-judge-visual', description: 'Score a set of rendered pages for variety, three shuffled passes', phases: [{ title: 'Judge' }] }
const { task, dir, ids, passes, judgeModel } = args
const VERDICT = { type: 'object', properties: { score: { type: 'integer', minimum: 1, maximum: 10 }, shared: { type: 'string' }, notes: { type: 'string' } }, required: ['score', 'shared', 'notes'] }
function hash(s) { let h = 2166136261; for (const c of s) { h ^= c.charCodeAt(0); h = Math.imul(h, 16777619) >>> 0 } return h }
function shuffle(arr, key) { const a = arr.slice(); for (let i = a.length - 1; i > 0; i--) { const j = hash(key + i) % (i + 1); [a[i], a[j]] = [a[j], a[i]] } return a }
const pad = id => String(id).padStart(2, '0')
const results = await parallel(Array.from({ length: passes }, (_, p) => () => {
  const order = shuffle(ids, `pass${p + 1}`)
  const list = order.map((id, k) => `RESPONSE ${k + 1}: screenshot ${dir}/build/${pad(id)}/shot.png, code ${dir}/build/${pad(id)}/page.html`).join('\n')
  return agent(`You are judging how varied a set of ${ids.length} independent responses to the same brief is. Brief:\n\n${task}\n\nIgnore any preamble about seeds, menus, or creative direction; judge only the deliverable. Consider whichever axes fit the brief: palette, layout, typography, structure, voice, rhythm, sound, metaphor, tone, architecture.\n\nOpen each screenshot with the Read tool and judge from what you see, using the code only for what a screenshot cannot show.\n\n${list}\n\nReturn {"score": <1-10, 1 = near-identical, 10 = every response takes a clearly different approach>, "shared": "<the strongest pattern most responses share, or 'none'>", "notes": "<one sentence>"}.`,
    { label: `judge pass ${p + 1}`, phase: 'Judge', model: judgeModel, effort: 'high', schema: VERDICT, agentType: 'general-purpose' }).then(v => v && ({ pass: p + 1, order, ...v }))
}))
const ok = results.filter(Boolean)
const mean = ok.reduce((a, r) => a + r.score, 0) / (ok.length || 1)
return { mean, passes: ok }
