// tokens.js: contrast, lift, and every role pair in every mode.
//
//   node dev/tests/contrast.mjs            checks, and the contrast table for the canonical hosts
//   node dev/tests/contrast.mjs --table    only the table
import fs from 'node:fs'
import os from 'node:os'
import path from 'node:path'
import { check, finish, section, load, near, dim, REPO } from './lib.mjs'

const T = load('ui/tokens.js')
const hex = T.hex
const hexOf = c => T.hex(c)

// ---------------------------------------------------------------- the one body
section('contrast: WCAG 2.x, one body')
check('black on white is 21:1', near(T.contrast('#000000', '#ffffff'), 21, 1e-9))
check('a colour on itself is 1:1', near(T.contrast('#7a7a7a', '#7a7a7a'), 1, 1e-9))
check('#586e75 on black is 3.90:1 (plan-surface-v2.md, Bar.qml colours.sh)', near(T.contrast('#586e75', '#000000'), 3.902, 0.001), T.contrast('#586e75', '#000000').toFixed(3))
check('order does not matter', near(T.contrast('#336699', '#ffcc00'), T.contrast('#ffcc00', '#336699'), 1e-12))
check('the 0.03928 knee is the one WCAG 2.x uses (a channel of 10/255 is on the linear side)', near(T.luminance('#0a0a0a'), 10 / 255 / 12.92, 1e-9))
check('#rgb, #rrggbb and #aarrggbb parse, alpha first', hexOf(T.parse('#fff')) === '#ffffff' && T.parse('#80ff0000').a > 0.5 && T.parse('#80ff0000').r === 1 && T.parse('#80ff0000').g === 0)

// The same body as omarchy-notch Bar.qml (plan-surface-v2.md moves it into panelstyle.js).
const notch = [process.env.OMARCHY_NOTCH, path.join(REPO, '../omarchy-notch')].filter(Boolean).find(d => fs.existsSync(path.join(d, 'Bar.qml')))
if (!notch) check('cross-check against omarchy-notch Bar.qml', true, 'skipped: no omarchy-notch checkout beside this one (set OMARCHY_NOTCH)')
else {
  const src = fs.readFileSync(path.join(notch, 'Bar.qml'), 'utf8')
  const a = src.indexOf('function luminance(value) {')
  const b = src.indexOf('function readableOn(')
  const body = a > 0 && b > a ? src.slice(a, b) : ''
  check('Bar.qml still has `luminance` and `contrast` where this test reads them', body.includes('function contrast(a, b)'), notch)
  if (body) {
    // Qt.tint(value, "transparent") is how Bar.qml turns a colour or a string into a colour: here, parse.
    const bar = new Function('Qt', body + '; return { luminance: luminance, contrast: contrast }')({ tint: v => T.parse(v) })
    let worst = 0, n = 0
    let seed = 12345
    const rnd = () => (seed = (seed * 1664525 + 1013904223) >>> 0) / 4294967296
    const rc = () => '#' + [0, 0, 0].map(() => Math.floor(rnd() * 256).toString(16).padStart(2, '0')).join('')
    for (let i = 0; i < 200; i++) { const x = rc(), y = rc(); worst = Math.max(worst, Math.abs(bar.contrast(x, y) - T.contrast(x, y))); n++ }
    check(`200 random pairs agree with Bar.qml's contrast to 1e-9`, worst < 1e-9, `largest difference ${worst.toExponential(2)}, ${path.join(notch, 'Bar.qml')}`)
  }
  const ps = path.join(notch, 'panelstyle.js')
  if (fs.existsSync(ps)) {
    const P = load(path.relative(REPO, ps).startsWith('..') ? ps : path.relative(REPO, ps))
    check('panelstyle.js contrast agrees with this one', near(P.contrast('#336699', '#ffcc00'), T.contrast('#336699', '#ffcc00'), 1e-9))
  } else check('panelstyle.js (plan-surface-v2.md Phase 1) agrees with this one', true, 'skipped: it does not exist yet; the notch Bar.qml body above is the reference')
}

// ---------------------------------------------------------------- lift
section('lift: the host\'s lift (plan-surface-v2.md section 2), for a panel with no host to ask')
check('#2a2a2a on black to 4.5:1 is #757575 (4.558)', hex(T.lift('#2a2a2a', '#000000', 4.5)) === '#757575' && near(T.contrast('#757575', '#000000'), 4.558, 0.001))
check('#6e6e6e on black to 4.5:1 is #757575 too', hex(T.lift('#6e6e6e', '#000000', 4.5)) === '#757575')
check('#747474 is 4.493 and fails, so it was not stopped at', T.contrast('#747474', '#000000') < 4.5)
check('#860111 on black to 3:1 is #9e3340 (3.001)', hex(T.lift('#860111', '#000000', 3)) === '#9e3340' && near(T.contrast('#9e3340', '#000000'), 3.001, 0.001))
check('#860111 on black to 4.5:1 is #b15a65 (4.52)', hex(T.lift('#860111', '#000000', 4.5)) === '#b15a65')
check('dark text on a light fill lifts toward black', (() => { const c = T.lift('#8a8a8a', '#ffffff', 4.5); return c.r < 0.54 && T.contrast(c, '#ffffff') >= 4.5 })())
check('a colour that already passes comes back unchanged', hex(T.lift('#cdd6f4', '#000000', 4.5)) === '#cdd6f4')
check('a translucent colour is judged as it lands on the backdrop', hex(T.lift('#99ebebf5', '#000000', 4.5)) === hex(T.over('#99ebebf5', '#000000')))
{
  let seed = 99, bad = []
  const rnd = () => (seed = (seed * 1664525 + 1013904223) >>> 0) / 4294967296
  const backs = ['#000000', '#ffffff', '#777777', '#808080', '#8a8a8a', '#101315', '#e0e0e0']
  const runs = []
  for (let pass = 0; pass < 2; pass++) {
    seed = 99; const out = []
    for (let i = 0; i < 1000; i++) {
      const c = '#' + [0, 0, 0].map(() => Math.floor(rnd() * 256).toString(16).padStart(2, '0')).join('')
      const bg = backs[i % backs.length], floor = i % 2 ? 4.5 : 3
      const l = T.lift(c, bg, floor)
      out.push(hex(l))
      if (T.contrast(l, bg) < floor) bad.push(`${c} on ${bg} to ${floor} gave ${hex(l)}`)
      if (hex(T.lift(l, bg, floor)) !== hex(l)) bad.push(`not idempotent: ${c} on ${bg}`)
    }
    runs.push(out.join())
  }
  check('1000 random colours on 7 backdrops: always at or over the floor, and idempotent', bad.length === 0, bad.slice(0, 3).join('; '))
  check('the same run twice is identical', runs[0] === runs[1])
}

// ---------------------------------------------------------------- roles
const modeOf = { standalone: 'standalone', hosted: 'hosted', styled: 'styled' }
function rolesFor(mode, host) {
  return T.roles({ mode, surface: host.surface, foreground: host.foreground, secondary: host.secondary, accent: host.accent, urgent: mode === 'hosted' ? undefined : host.urgent })
}
const hosts = {
  'black host (the notch)': { surface: '#000000', foreground: '#ffffff', secondary: '#99ebebf5', accent: '#ffffff', urgent: '#ff453a' },
  'white host': { surface: '#ffffff', foreground: '#000000', secondary: '#993c3c43', accent: '#000000', urgent: '#d70015' },
  'catppuccin-oled (this desktop)': { surface: '#000000', foreground: '#cdd6f4', secondary: undefined, accent: '#89b4fa', urgent: '#f38ba8' }
}
// mid-tones: where label and surface are closest, and the floor is hardest to hold
for (const g of ['#6e6e6e', '#777777', '#808080', '#8a8a8a', '#949494', '#a0a0a0']) {
  hosts[`mid-grey ${g}, white text`] = { surface: g, foreground: '#ffffff', secondary: undefined, accent: '#ffffff', urgent: '#ff0000' }
  hosts[`mid-grey ${g}, black text`] = { surface: g, foreground: '#000000', secondary: undefined, accent: '#000000', urgent: '#ff0000' }
}
hosts['host hands over a failing label (#444 on black)'] = { surface: '#000000', foreground: '#444444', secondary: '#333333', accent: '#222222', urgent: '#550000' }

function table(label, mode, host) {
  const r = rolesFor(mode, host)
  console.log(`\n  ${label}, mode ${mode}  ${dim('surface ' + hex(r.surface) + '  label ' + hex(r.label) + '  secondary ' + hex(T.over(r.secondary, r.surface)) + '  accent ' + hex(r.accent) + '  destructive ' + hex(r.destructive))}`)
  T.check(r).forEach(x => console.log(`    ${x.pass ? 'ok  ' : 'FAIL'}  ${x.name.padEnd(28)} ${x.ratio.toFixed(2).padStart(6)} : 1   floor ${x.floor}   (${x.role})`))
}

if (process.argv.includes('--table')) {
  for (const [name, host] of Object.entries(hosts).slice(0, 3)) for (const mode of ['standalone', 'hosted', 'styled']) table(name, mode, host)
  process.exit(0)
}

section('roles: every pair in every mode on every host')
let pairsChecked = 0
const failing = []
for (const [name, host] of Object.entries(hosts)) {
  for (const mode of ['standalone', 'hosted', 'styled']) {
    const results = T.check(rolesFor(mode, host))
    pairsChecked += results.length
    results.filter(x => !x.pass).forEach(x => failing.push(`${name} / ${mode} / ${x.name} ${x.ratio.toFixed(2)} < ${x.floor}`))
  }
}
check(`${Object.keys(hosts).length} hosts x 3 modes x 12 pairs = ${pairsChecked} pairs all hold their floor (text 4.5:1, marks 3:1)`, failing.length === 0, failing.slice(0, 4).join('; '))

section('roles: what each mode promises')
{
  const host = hosts['black host (the notch)']
  const hosted = rolesFor('hosted', host), styled = rolesFor('styled', host), alone = rolesFor('standalone', Object.assign({}, hosts['catppuccin-oled (this desktop)']))
  const colourRoles = ['surface', 'label', 'secondary', 'accent', 'accentText', 'destructive', 'fill', 'hover', 'selected', 'pressed', 'raised', 'hairline', 'ring', 'trackOn', 'knobOn', 'trackOff', 'knobOff', 'disabled']
  const translucent = r => colourRoles.filter(k => T.translucent(r[k]))
  check('hosted-opaque: every role is an opaque colour (zero translucent)', translucent(hosted).length === 0, translucent(hosted).join(','))
  check('hosted-opaque on white: the same', translucent(rolesFor('hosted', hosts['white host'])).length === 0)
  check('hosted-opaque on a mid-grey and on a failing host: the same', translucent(rolesFor('hosted', hosts['mid-grey #808080, white text'])).length === 0 && translucent(rolesFor('hosted', hosts['host hands over a failing label (#444 on black)'])).length === 0)
  check('standalone and styled use alpha fills (fill, hover, selected, pressed)', ['fill', 'hover', 'selected', 'pressed'].every(k => T.translucent(alone[k]) && T.translucent(styled[k])))
  check('level 2 (raised) is solid in every mode: it floats over content', [hosted, styled, alone].every(r => r.raised.a === 1))
  check('hosted tints are the Qt.tint of the host colour: fill = surface + 4 % of label', hex(hosted.fill) === hex(T.mix(host.surface, '#ffffff', 0.04)), hex(hosted.fill))
  check('hosted: destructive is the label (wording and position, not red)', hex(hosted.destructive) === hex(hosted.label))
  check('standalone and styled: destructive is the urgent colour, lifted to 4.5:1', hex(alone.destructive) !== hex(alone.label) && T.contrast(alone.destructive, alone.surface) >= 4.5)
  check('levels on #000: fill 0.04, hover 0.08, selected 0.18, pressed 0.22 of the label colour', [alone.alphas.fill, alone.alphas.hover, alone.alphas.selected, alone.alphas.pressed].join() === '0.04,0.08,0.18,0.22')
  check('hairline and focus ring clear 3:1 (the surface-v2 guard) where Style.focusBorderAlpha (0.25) alone would not', T.contrast(T.mix('#000000', '#cdd6f4', 0.25), '#000000') < 3 && T.contrast(alone.ring, alone.surface) >= 3 && T.contrast(alone.hairline, alone.surface) >= 3)
  check('the ring is never fainter than the host asked for', alone.ringAlpha >= 0.25)
  check('the hairline is the 0.4 border alpha or more, as much as 3:1 needs', alone.hairlineAlpha >= 0.4)
  check('"when the guard trips the kit falls to hosted-opaque by itself": styled and hosted differ only in mode, from the same host', (() => {
    const a = T.roles({ mode: 'styled', surface: '#000000', foreground: '#ffffff', secondary: '#99ebebf5', accent: '#ffffff' })
    const b = T.roles({ mode: 'hosted', surface: '#000000', foreground: '#ffffff', secondary: '#99ebebf5', accent: '#ffffff' })
    return hex(a.label) === hex(b.label) && hex(a.secondary) === hex(b.secondary) && !T.translucent(b.fill) && T.translucent(a.fill)
  })())
}

section('roles: every stock and user theme, in every mode')
{
  const dirs = ['/usr/share/omarchy/themes', path.join(os.homedir(), '.config/omarchy/themes')]
  const themes = []
  for (const d of dirs) if (fs.existsSync(d)) for (const n of fs.readdirSync(d)) {
    const f = path.join(d, n, 'colors.toml')
    if (!fs.existsSync(f)) continue
    const v = {}
    for (const line of fs.readFileSync(f, 'utf8').split('\n')) {
      const m = line.match(/^\s*([A-Za-z0-9_-]+)\s*=\s*["']?(#[0-9A-Fa-f]{6})/)
      if (m) v[m[1]] = m[2]
    }
    themes.push({ name: n, bg: v.background || v.color0, fg: v.foreground || v.color7, accent: v.accent || v.color4, urgent: v.red || v.color1 })
  }
  const usable = themes.filter(t => t.bg && t.fg && t.accent && t.urgent)
  const bad = []
  let n = 0
  for (const t of usable) for (const mode of ['standalone', 'hosted', 'styled']) {
    const r = T.roles({ mode, surface: t.bg, foreground: t.fg, accent: t.accent, urgent: t.urgent })
    T.check(r).forEach(x => { n++; if (!x.pass) bad.push(`${t.name}/${mode}/${x.name} ${x.ratio.toFixed(2)}`) })
  }
  check(`${usable.length} themes (${themes.length - usable.length} without a full palette skipped) x 3 modes: all ${n} pairs hold`, usable.length > 10 && bad.length === 0, bad.slice(0, 4).join('; ') || dirs.filter(fs.existsSync).join(' + '))
  // a stock theme whose urgent colour alone fails 4.5:1, to show the repair is doing work
  const weak = usable.filter(t => T.contrast(t.urgent, t.bg) < 4.5)
  check(`${weak.length} themes hand over an urgent colour under 4.5:1; the kit lifts it (e.g. ${weak.slice(0, 3).map(t => t.name).join(', ')})`, weak.every(t => T.contrast(T.roles({ mode: 'standalone', surface: t.bg, foreground: t.fg, accent: t.accent, urgent: t.urgent }).destructive, t.bg) >= 4.5))
}

section('the other tokens')
check('density: row 30 on the notch, 32 standalone; body from Style.font.body / Style.font.subtitle', T.DENSITY.notch.row === 30 && T.DENSITY.standalone.row === 32 && T.DENSITY.notch.body === 'body' && T.DENSITY.standalone.body === 'subtitle')
check('space is 4, 8, 12, 16, 24 with a 1 px hairline; hit 24; switch 22 x 42; text floor 11; tips 60', T.SPACE.join() === '4,8,12,16,24' && T.HAIRLINE === 1 && T.MIN_HIT === 24 && T.SWITCH.height === 22 && T.SWITCH.width === 42 && T.MIN_TEXT === 11 && T.TIP_MAX === 60)
check('radius is the host\'s, never more than half the height', T.radius(10, 30) === 10 && T.radius(10, 14) === 7 && T.radius(0, 30) === 0 && T.radius(undefined, 30) === 0 && T.radius(40, 22) === 11)
{
  const env = vars => name => vars[name] || ''
  check('reduced motion: OMARCHY_REDUCED_MOTION=1', T.reducedFrom(env({ OMARCHY_REDUCED_MOTION: '1' })))
  check('reduced motion: NOTCH_REDUCED_MOTION=1 is an alias', T.reducedFrom(env({ NOTCH_REDUCED_MOTION: '1' })))
  check('reduced motion: unset, 0 and empty are off', !T.reducedFrom(env({})) && !T.reducedFrom(env({ OMARCHY_REDUCED_MOTION: '0' })) && !T.reducedFrom(env({ OMARCHY_REDUCED_MOTION: '' })))
}

finish('contrast')
