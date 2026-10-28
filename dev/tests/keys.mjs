// keys.js: what a key means to a control, and who answers Esc.
import { check, finish, section, load } from './lib.mjs'

const K = load('ui/keys.js')
const KEY = K.KEY

section('Esc closes in order: edit, tip, pick, modal, back, then the panel')
check('the layers are in that order', K.LAYERS.join(',') === 'edit,tip,pick,modal,back', K.LAYERS.join(','))
let wrong = []
for (let mask = 0; mask < 32; mask++) {
  const open = {}
  K.LAYERS.forEach((l, i) => { if (mask & (1 << i)) open[l] = true })
  const want = K.LAYERS.find(l => open[l]) || 'close'
  if (K.escapeTarget(open) !== want) wrong.push(mask)
}
check('escapeTarget answers the highest open layer for all 32 combinations of open layers', wrong.length === 0, wrong.join(','))
check('with nothing open it answers close', K.escapeTarget({}) === 'close')

section('the registry routes a real Esc press')
{
  const log = []
  const r = K.createRegistry()
  const back = r.join('back', true, () => log.push('back'))
  const modal = r.join('modal', false, () => log.push('modal'))
  const pick = r.join('pick', false, () => log.push('pick'))
  const tip = r.join('tip', false, () => log.push('tip'))
  const edit = r.join('edit', false, () => log.push('edit'))
  check('only back is open: Esc goes back', r.escape() === 'back' && log.join() === 'back')
  r.set(modal, true)
  check('a modal opens: Esc is Cancel, not back', r.escape() === 'modal' && log.at(-1) === 'modal')
  r.set(pick, true)
  check('a pick opens over the modal: Esc closes the pick first', r.escape() === 'pick' && log.at(-1) === 'pick')
  r.set(tip, true); r.set(edit, true)
  check('a tip and an edit as well: the edit first', r.escape() === 'edit' && log.at(-1) === 'edit')
  r.set(edit, false)
  check('then the tip', r.escape() === 'tip' && log.at(-1) === 'tip')
  r.set(tip, false); r.set(pick, false); r.set(modal, false)
  check('then back again', r.escape() === 'back')
  r.set(back, false)
  const n = log.length
  check('nothing open: Esc answers close and fires nothing', r.escape() === 'close' && log.length === n)
  r.leave(back)
  check('a layer that has left is never fired', (r.set(back, true), r.escape() === 'close'))
  const second = r.join('pick', true, () => log.push('second'))
  const third = r.join('pick', true, () => log.push('third'))
  r.escape()
  check('two picks open: the newer one answers', log.at(-1) === 'third')
  check('openLayers reports what is open', JSON.stringify(r.openLayers()) === '{"pick":true}')
  let threw = false
  try { r.join('overlay', true, () => {}) } catch (e) { threw = true }
  check('an unknown layer is refused', threw)
  check('the shared registry exists and is separate from a new one', typeof K.shared.join === 'function' && K.shared !== r)
}

section('what a key means to each control')
const table = [
  ['button', KEY.Return, 'activate'], ['button', KEY.Enter, 'activate'], ['button', KEY.Space, 'activate'], ['button', KEY.Left, 'none'], ['button', KEY.Escape, 'none'],
  ['switch', KEY.Space, 'toggle'], ['switch', KEY.Return, 'toggle'], ['switch', KEY.Up, 'none'],
  ['stepper', KEY.Left, 'dec'], ['stepper', KEY.Right, 'inc'], ['stepper', KEY.Up, 'none'], ['stepper', KEY.Return, 'none'],
  ['segmented', KEY.Left, 'prev'], ['segmented', KEY.Right, 'next'], ['segmented', KEY.Space, 'activate'], ['segmented', KEY.Up, 'none'],
  ['pick', KEY.Return, 'open'], ['pick', KEY.Space, 'open'], ['pick', KEY.Right, 'open'], ['pick', KEY.Down, 'open'], ['pick', KEY.Up, 'none'], ['pick', KEY.Left, 'none'],
  ['pickOpen', KEY.Up, 'prev'], ['pickOpen', KEY.Down, 'next'], ['pickOpen', KEY.Home, 'first'], ['pickOpen', KEY.End, 'last'], ['pickOpen', KEY.Return, 'activate'], ['pickOpen', KEY.Space, 'activate'],
  ['field', KEY.Return, 'commit'], ['field', KEY.Enter, 'commit'], ['field', KEY.Space, 'none'], ['field', KEY.Escape, 'none'],
  ['list', KEY.Up, 'prev'], ['list', KEY.Down, 'next'], ['list', KEY.Slash, 'search'], ['list', KEY.Return, 'activate'], ['list', KEY.Left, 'none'],
  ['nonsense', KEY.Return, 'none']
]
const bad = table.filter(([role, key, want]) => K.action(role, key) !== want).map(([r, k, w]) => `${r}/${k.toString(16)} wanted ${w} got ${K.action(r, k)}`)
check(`${table.length} key/role pairs`, bad.length === 0, bad.join('; '))
check('no control handles Esc itself: it is UKeys', ['button', 'switch', 'stepper', 'segmented', 'pick', 'pickOpen', 'field', 'list'].every(r => K.action(r, KEY.Escape) === 'none'))
check('Qt key codes are the real ones (Escape 0x01000000, Return 0x01000004, Space 0x20)', KEY.Escape === 0x01000000 && KEY.Return === 0x01000004 && KEY.Space === 0x20)

section('stepping holds at the ends')
check('inside', K.step(5, 1, 0, 10) === 6 && K.step(5, -1, 0, 10) === 4)
check('at the top it stays', K.step(10, 1, 0, 10) === 10)
check('at the bottom it stays', K.step(0, -1, 0, 10) === 0)
check('a big step is clamped', K.step(8, 5, 0, 10) === 10 && K.step(2, -5, 0, 10) === 0)

finish('keys')
