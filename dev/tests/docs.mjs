// The documentation holds to the code: every relative link in the markdown resolves (and every
// #anchor), every component in ui/ has an entry in docs/components.md and a picture under 150 KB,
// and every property, signal and handler a ```qml example sets on a U component exists in that
// component's source, and every theme.<name> it reads exists in UTheme.
//
//   node dev/tests/docs.mjs
import fs from 'node:fs'
import path from 'node:path'
import { check, finish, section, REPO } from './lib.mjs'

const rel = p => path.relative(REPO, p)
function walk(dir, out = []) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    if (['.git', 'node_modules'].includes(e.name)) continue
    const p = path.join(dir, e.name)
    if (e.isDirectory()) walk(p, out)
    else if (e.name.endsWith('.md')) out.push(p)
  }
  return out
}
const mdFiles = walk(REPO).sort()

// ----------------------------------------------------------------------------------------- links
const slug = h => h.replace(/`/g, '').replace(/\[([^\]]*)\]\([^)]*\)/g, '$1').toLowerCase().replace(/[^a-z0-9 _-]/g, '').trim().replace(/ /g, '-')
function anchorsOf(file) {
  const out = new Set(), seen = {}
  let fence = false
  for (const line of fs.readFileSync(file, 'utf8').split('\n')) {
    if (/^\s*```/.test(line)) { fence = !fence; continue }
    const m = !fence && /^#{1,6}\s+(.*?)\s*#*\s*$/.exec(line)
    if (m) { let s = slug(m[1]); const n = seen[s] = (seen[s] || 0) + 1; out.add(n > 1 ? `${s}-${n - 1}` : s) }
  }
  return out
}
function linksOf(file) {
  const out = []
  let fence = false
  fs.readFileSync(file, 'utf8').split('\n').forEach((line, i) => {
    if (/^\s*```/.test(line)) { fence = !fence; return }
    if (fence) return
    const text = line.replace(/`[^`]*`/g, '')
    for (const m of text.matchAll(/!?\[[^\]]*\]\(([^)\s]+)(?:\s+"[^"]*")?\)/g)) out.push({ target: m[1], line: i + 1 })
    const ref = /^\[[^\]]+\]:\s*(\S+)/.exec(text)
    if (ref) out.push({ target: ref[1], line: i + 1 })
  })
  return out
}

section(`links: ${mdFiles.length} markdown files`)
let total = 0
for (const f of mdFiles) {
  const bad = []
  const links = linksOf(f)
  for (const { target, line } of links) {
    if (/^(https?:|mailto:)/.test(target)) continue
    total++
    const [file, anchor] = target.split('#')
    const dest = file === '' ? f : path.resolve(path.dirname(f), decodeURI(file))
    if (!fs.existsSync(dest)) { bad.push(`${line}: ${target} (no such file)`); continue }
    if (anchor && dest.endsWith('.md') && !anchorsOf(dest).has(anchor)) bad.push(`${line}: ${target} (no such heading)`)
  }
  check(`${rel(f)}: ${links.length} links, every relative one resolves`, bad.length === 0, bad.join('; '))
}
console.log(`  (${total} relative links in all)`)

// ------------------------------------------------------------------------------------ components
const uiDir = path.join(REPO, 'ui')
const components = fs.readdirSync(uiDir).filter(f => /^U\w+\.qml$/.test(f)).map(f => f.replace('.qml', '')).sort()
const refFile = path.join(REPO, 'docs/components.md')
const ref = fs.existsSync(refFile) ? fs.readFileSync(refFile, 'utf8') : ''

section('components: every file in ui/ is documented and drawn')
check(`docs/components.md exists and the kit has ${components.length} components`, ref !== '' && components.length > 0)
for (const c of components) {
  const png = path.join(REPO, 'docs/components', c + '.png')
  const has = new RegExp(`^## ${c}\\s*$`, 'm').test(ref)
  const ok = fs.existsSync(png) && fs.readFileSync(png).subarray(0, 4).toString('latin1').endsWith('PNG')
  const kb = ok ? fs.statSync(png).size / 1024 : 0
  const shown = ref.includes(`](components/${c}.png)`)
  check(`${c}: a section, its picture shown, a real PNG under 150 KB`, has && shown && ok && kb < 150, `${has ? '' : 'no section; '}${shown ? '' : 'picture not shown; '}${ok ? kb.toFixed(0) + ' KB' : 'no PNG'}`)
}

// -------------------------------------------------------------------------------------- examples
const strip = src => {   // drop // comments outside strings
  let out = '', q = ''
  for (let i = 0; i < src.length; i++) {
    const c = src[i]
    if (q) { out += c; if (c === '\\') out += src[++i]; else if (c === q) q = ''; continue }
    if (c === '"' || c === "'") { q = c; out += c; continue }
    if (c === '/' && src[i + 1] === '/') { while (i < src.length && src[i] !== '\n') i++; out += '\n'; continue }
    out += c
  }
  return out
}
const code = f => strip(fs.readFileSync(path.join(uiDir, f), 'utf8'))

// What a component declares: properties (and aliases), signals, functions, and the handlers they give.
const declared = {}
for (const c of components) {
  const src = code(c + '.qml'), names = new Set()
  for (const m of src.matchAll(/\bproperty\s+(?:alias\s+(\w+)|[\w.<>]+\s+(\w+))/g)) { const n = m[1] || m[2]; names.add(n); names.add('on' + n[0].toUpperCase() + n.slice(1) + 'Changed') }
  for (const m of src.matchAll(/\bsignal\s+(\w+)/g)) names.add('on' + m[1][0].toUpperCase() + m[1].slice(1))
  for (const m of src.matchAll(/\bfunction\s+(\w+)/g)) names.add(m[1])
  declared[c] = names
}
// What any Item, Rectangle, Column or Row carries, and which a example may set on a kit component.
const generic = new Set(['id', 'width', 'height', 'x', 'y', 'z', 'visible', 'enabled', 'opacity', 'focus', 'scale', 'clip', 'implicitWidth', 'implicitHeight',
  'activeFocusOnTab', 'spacing', 'color', 'radius', 'topPadding', 'leftPadding', 'default', 'onActiveFocusChanged', 'onVisibleChanged', 'onWidthChanged', 'onHeightChanged'])
const genericPrefix = /^(anchors|Layout|Component|Keys|Accessible|border|font|transform)\./

// A small QML reader: returns [{type, bindings: [name], line}] for every `Type {` in the text.
function readBlocks(text) {
  const blocks = []
  let i = 0
  const ws = () => { while (i < text.length && /\s/.test(text[i])) i++ }
  const skipValue = () => {   // to the end of a binding: a newline or ; at depth 0, or the closing brace of the block
    let depth = 0, q = ''
    for (; i < text.length; i++) {
      const c = text[i]
      if (q) { if (c === '\\') i++; else if (c === q) q = ''; continue }
      if (c === '"' || c === "'") { q = c; continue }
      if ('([{'.includes(c)) depth++
      else if (')]}'.includes(c)) { if (depth === 0) return; depth-- }
      else if ((c === '\n' || c === ';') && depth === 0) {
        // a value continues on the next line when that line starts with an operator or ? :
        const rest = text.slice(i + 1).match(/^\s*(.)/)
        if (c === ';' || !rest || !/[?:+\-*/&|.]/.test(rest[1])) return
      }
    }
  }
  function block(type) {   // i is just after the `{`
    const b = { type, bindings: [] }
    blocks.push(b)
    for (;;) {
      ws()
      if (i >= text.length) return
      if (text[i] === '}') { i++; return }
      if (text[i] === ';') { i++; continue }
      const m = /^[A-Za-z_][\w.]*/.exec(text.slice(i))
      if (!m) { i++; continue }
      const word = m[0]
      const afterWord = i + word.length
      let j = afterWord
      while (j < text.length && /[ \t]/.test(text[j])) j++
      if (text[j] === '{' && /^[A-Z]/.test(word)) { i = j + 1; block(word); continue }   // a child type
      if (text[j] === ':' ) { i = j + 1; b.bindings.push(word); skipValue(); continue }
      // `property ...`, `signal ...`, `function ...`, `required ...`, `default ...`, `readonly ...`, `component ...`: skip the statement
      i = afterWord
      skipValue()
    }
  }
  while (i < text.length) {
    const m = /\b([A-Z][A-Za-z0-9_]*)\s*\{/.exec(text.slice(i))
    if (!m) break
    i += m.index + m[0].length
    block(m[1])
  }
  return blocks
}

const themeNames = declared.UTheme
const spNames = new Set(['xs', 'sm', 'md', 'lg', 'xl', 'xxl'])
section('examples: every property a ```qml example sets exists in the component')
let exampleCount = 0
for (const f of mdFiles) {
  const src = fs.readFileSync(f, 'utf8')
  const fences = [...src.matchAll(/^```qml\s*\n([\s\S]*?)^```/gm)]
  if (!fences.length) continue
  const problems = []
  fences.forEach((fm, n) => {
    exampleCount++
    const text = strip(fm[1])
    for (const b of readBlocks(text)) {
      if (!declared[b.type]) continue
      for (const name of b.bindings) {
        if (generic.has(name) || genericPrefix.test(name) || declared[b.type].has(name)) continue
        problems.push(`example ${n + 1}: ${b.type}.${name}`)
      }
    }
    for (const m of text.matchAll(/\btheme\.(\w+)(?:\.(\w+))?/g)) {
      if (!themeNames.has(m[1]) && !['host'].includes(m[1])) problems.push(`example ${n + 1}: theme.${m[1]}`)
      if (m[1] === 'sp' && m[2] && !spNames.has(m[2])) problems.push(`example ${n + 1}: theme.sp.${m[2]}`)
    }
  })
  check(`${rel(f)}: ${fences.length} qml examples use only names that exist`, problems.length === 0, problems.slice(0, 6).join('; '))
}
check(`${exampleCount} qml examples were read`, exampleCount > 0 || !fs.existsSync(refFile))

finish('docs')
