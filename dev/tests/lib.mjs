// A tiny runner in the house style: check(description, ok, detail) prints
// pass or FAIL, and finish() sets the exit code.
import fs from 'node:fs'
import path from 'node:path'
import vm from 'node:vm'
import { fileURLToPath } from 'node:url'

export const REPO = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..')
const G = process.stdout.isTTY ? '\x1b[32m' : '', R = process.stdout.isTTY ? '\x1b[31m' : '', D = process.stdout.isTTY ? '\x1b[2m' : '', X = process.stdout.isTTY ? '\x1b[0m' : ''
export const dim = s => D + s + X
let checks = 0, failures = 0
const failed = []

export function check(description, ok, detail = '') {
  checks++
  if (ok) console.log(`  ${G}pass${X}  ${description}${detail ? ' ' + D + detail + X : ''}`)
  else { failures++; failed.push(description); console.log(`  ${R}FAIL${X}  ${description}${detail ? ' ' + D + '(' + detail + ')' + X : ''}`) }
}
export function near(a, b, eps) { return Math.abs(a - b) <= eps }
export function section(title) { console.log(`\n${title}`) }
export function finish(name) {
  console.log(`\n${name}: ${checks - failures} of ${checks} passed`)
  if (failures) { console.log(`${R}failed${X}: ${failed.join('; ')}`); process.exit(1) }
}

// Load a `.pragma library` file: its top-level var and function declarations come back as an object.
export function load(file) {
  const src = fs.readFileSync(path.join(REPO, file), 'utf8').replace(/^\.pragma library/m, '')
  const ctx = vm.createContext({ Math, Object, String, Number, Array, JSON, Error, isFinite, parseInt })
  vm.runInContext(src, ctx, { filename: file })
  return ctx
}
