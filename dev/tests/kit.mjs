// The kit's shape: what is in ui/, how it is named, and that every component reads
// the theme it is handed and nothing else.
import fs from 'node:fs'
import path from 'node:path'
import { check, finish, section, REPO } from './lib.mjs'

const ui = path.join(REPO, 'ui')
const files = fs.readdirSync(ui).filter(f => f !== 'KIT')
const qml = files.filter(f => f.endsWith('.qml'))
const text = f => fs.readFileSync(path.join(ui, f), 'utf8')
const code = f => text(f).replace(/\/\/.*$/gm, '')

section('the files')
const components = ['UBack', 'UClose', 'UButton', 'USwitch', 'USegmented', 'UPick', 'UField', 'UStepper', 'URow', 'USection', 'UTip', 'UToast', 'UNotice', 'UEmpty', 'URing', 'UConfirmSheet']
check('the 15 components of plan-apple-ui.md 4.2 (UToast and UNotice are two files: 16 names)', components.every(c => qml.includes(c + '.qml')), components.filter(c => !qml.includes(c + '.qml')).join(','))
check('UTheme.qml, UKeys.qml, tokens.js, spring.js, errors.js and keys.js', ['UTheme.qml', 'UKeys.qml', 'tokens.js', 'spring.js', 'errors.js', 'keys.js'].every(f => files.includes(f)))
check('nothing else is in ui/ (a helper would be a 23rd file)', files.length === components.length + 6, files.filter(f => !components.includes(f.replace('.qml', '')) && !['UTheme.qml', 'UKeys.qml', 'tokens.js', 'spring.js', 'errors.js', 'keys.js'].includes(f)).join(',') || `${files.length} files`)
check('every QML file starts with U (bare Row, Button, Switch collide with QtQuick and qs.Ui)', qml.every(f => f.startsWith('U')))
check('no inline component in ui/ that does not start with U', qml.every(f => [...text(f).matchAll(/^\s*component\s+(\w+)\s*:/gm)].every(m => m[1].startsWith('U'))))
const lines = files.reduce((n, f) => n + text(f).split('\n').length, 0)
const codeLines = files.reduce((n, f) => n + text(f).split('\n').filter(l => !/^\s*(\/\/.*)?$/.test(l)).length, 0)
check(`size recorded in the plan: ${codeLines} code lines, ${lines} with comments and blanks (plan-apple-ui.md guessed 1,000; Corners is 593)`, codeLines > 1000 && codeLines < 2500, `${files.length} files`)
check('every .js is a library (`.pragma library` first), so it is one instance and carries no Qt', files.filter(f => f.endsWith('.js')).every(f => text(f).startsWith('.pragma library')))

section('what a component may read')
const withTheme = qml.filter(f => !['UTheme.qml', 'UKeys.qml'].includes(f))
check('every component declares `required property var theme`', withTheme.every(f => /required property var theme\b/.test(text(f))), withTheme.filter(f => !/required property var theme\b/.test(text(f))).join(','))
check('only UTheme imports qs.Commons or Quickshell: every other file reads the theme it is handed', qml.filter(f => f !== 'UTheme.qml').every(f => !/import\s+(qs\.|Quickshell)/.test(text(f))), qml.filter(f => f !== 'UTheme.qml' && /import\s+(qs\.|Quickshell)/.test(text(f))).join(','))
check('no component reads Style or Color directly', qml.filter(f => f !== 'UTheme.qml').every(f => !/\b(Style|Color)\.\w/.test(code(f))))
check('no colour or duration or pixel literal in a component (the gate holds the kit to its own rule)', qml.filter(f => f !== 'UTheme.qml').every(f => !/["']#[0-9a-fA-F]{3,8}["']/.test(code(f))), '')

section('the theme surface')
const decl = src => new Set([...src.matchAll(/(?:readonly\s+)?property\s+[\w.<>]+\s+(\w+)/g)].map(m => m[1]).concat([...src.matchAll(/function\s+(\w+)\s*\(/g)].map(m => m[1])))
const utheme = decl(code('UTheme.qml'))
const stub = decl(fs.readFileSync(path.join(REPO, 'dev/tests/qml/StubTheme.qml'), 'utf8').replace(/\/\/.*$/gm, ''))
const used = new Set()
for (const f of qml.filter(f => f !== 'UTheme.qml')) for (const m of code(f).matchAll(/\btheme\.(\w+)/g)) used.add(m[1])
const notInTheme = [...used].filter(n => !utheme.has(n)), notInStub = [...used].filter(n => !stub.has(n)), phantom = [...stub].filter(n => !utheme.has(n))
check(`all ${used.size} names the components read from \`theme\` exist in UTheme.qml`, notInTheme.length === 0, notInTheme.join(','))
check('…and in dev/tests/qml/StubTheme.qml, which the behaviour tests use', notInStub.length === 0, notInStub.join(','))
check('the stub has nothing UTheme does not', phantom.length === 0, phantom.join(','))
check('UTheme exposes pairs and palette ({pairs}) for plan-surface-v2.md, and the three modes', utheme.has('pairs') && utheme.has('palette') && /"standalone"/.test(text('UTheme.qml')) && /"hosted-opaque"/.test(text('UTheme.qml')) && /"styled"/.test(text('UTheme.qml')))
check('UTheme is not a singleton (it has to see a plugin\'s surfaceHost)', !/pragma Singleton/.test(text('UTheme.qml')))
check('UTheme reads OMARCHY_REDUCED_MOTION and the NOTCH_ alias only through tokens.js reducedFrom', /reducedFrom/.test(text('UTheme.qml')) && /NOTCH_REDUCED_MOTION/.test(text('tokens.js')) && /OMARCHY_REDUCED_MOTION/.test(text('tokens.js')))

section('the focusable ones')
const focusable = qml.filter(f => /activeFocusOnTab/.test(text(f)))
check(`every component with a tab stop (${focusable.length}) names itself for a screen reader (Accessible.name)`, focusable.every(f => /Accessible\.name/.test(text(f))), focusable.filter(f => !/Accessible\.name/.test(text(f))).join(','))
check('…and has a role', focusable.every(f => /Accessible\.role/.test(text(f))))
check('Esc is handled only in UKeys.qml: no other file has onEscapePressed or Key_Escape', qml.filter(f => f !== 'UKeys.qml').every(f => !/onEscapePressed|Key_Escape/.test(code(f))))

finish('kit')
