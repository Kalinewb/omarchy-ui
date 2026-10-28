// errors.js: one table per plugin; a code never reaches the surface.
import { check, finish, section, load } from './lib.mjs'

const E = load('ui/errors.js')
const table = E.create({
  sentences: { not_connected: "The eGPU is not connected.", busy: "Busy: another eGPU action is running" },
  exits: { 126: "Permission declined", 127: "The system helper is not installed." },
  notes: { needs_relogin: "The HDMI monitor needs a new session to appear." }
})

section('the sentence, never the code')
check('a known code reads as its sentence', table.message('not_connected') === 'The eGPU is not connected.')
check('an unknown code reads "Something went wrong."', table.message('wat_is_this') === 'Something went wrong.')
check('the unknown code is not in the message', !table.message('wat_is_this').includes('wat_is_this'))
check('the code is available for the Details line', table.details('wat_is_this') === 'wat_is_this')
check('an empty code is an empty line (no error)', table.message('') === '' && table.message(null) === '' && table.message(undefined) === '')
check('a name that exists on Object.prototype is not a known code', table.message('toString') === 'Something went wrong.' && table.message('constructor') === 'Something went wrong.')
check('a plugin may say its own fallback', E.create({ fallback: 'Hm.' }).message('x') === 'Hm.')

section('results and notes')
check('a success has no sentence', table.forResult({ ok: true }) === '' && table.forResult(null) === '')
check('an exit code wins over the error that came with it', table.forResult({ ok: false, code: 126, error: 'not_connected' }) === 'Permission declined')
check('otherwise the error code is looked up', table.forResult({ ok: false, code: 1, error: 'not_connected' }) === 'The eGPU is not connected.')
check('no code at all still renders', table.forResult({ ok: false, code: 9 }) === 'Something went wrong.')
check('a note is looked up, an unknown note is empty', table.note('needs_relogin') !== '' && table.note('nope') === '')
check('the kit ships a fallback sentence of its own', E.FALLBACK === 'Something went wrong.')

finish('errors')
