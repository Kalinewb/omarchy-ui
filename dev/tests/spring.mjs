// spring.js and the motion tokens: Spring.overshoot, and that each token's curve does what it says.
import { check, finish, section, load, near } from './lib.mjs'

const S = load('ui/spring.js'), T = load('ui/tokens.js')
const M = T.MOTION

section('Spring.overshoot = exp(-pi z / sqrt(1 - z^2))')
// swiftui-animation-lessons.md, "Conversion table"; the last is quoted there to a whole percent (the formula gives 20.53)
const known = [[0.85, 0.006, 0.0015], [0.72, 0.038, 0.0015], [0.60, 0.095, 0.0015], [0.45, 0.20, 0.006]]
known.forEach(([z, want, eps]) => check(`zeta ${z} overshoots ${(want * 100).toFixed(1)} %`, near(S.overshoot(z), want, eps), (S.overshoot(z) * 100).toFixed(2) + ' %'))
check('more damping overshoots less', S.overshoot(0.9) < S.overshoot(0.85) && S.overshoot(0.85) < S.overshoot(0.72) && S.overshoot(0.72) < S.overshoot(0.6))
check('critically damped does not overshoot', near(S.overshoot(0.999999), 0, 1e-3), S.overshoot(0.999999).toFixed(6))

section('the motion tokens')
check('arrive: zeta 0.72, peak 0.6, 350 ms, 3.8 % overshoot (the notch\'s grow)', M.arrive.damping === 0.72 && M.arrive.peakAt === 0.6 && M.arrive.ms === 350 && near(S.overshoot(M.arrive.damping), 0.038, 0.001))
check('control: zeta 0.85, peak 0.55, 200 ms, 0.6 % overshoot', M.control.damping === 0.85 && M.control.peakAt === 0.55 && M.control.ms === 200 && near(S.overshoot(M.control.damping), 0.006, 0.001))
check('celebrate: zeta 0.60, 450 ms, 9.5 % overshoot', M.celebrate.damping === 0.6 && M.celebrate.ms === 450 && near(S.overshoot(M.celebrate.damping), 0.095, 0.001))
check('exit 180 ms; fade out 90, in 150; press 0.97 over 60; stagger 40 capped at 240', M.exit.ms === 180 && M.fade.out === 90 && M.fade.in === 150 && M.press.scale === 0.97 && M.press.ms === 60 && M.stagger.ms === 40 && M.stagger.cap === 240)
check('an exit is shorter than an arrival (0.6 x or less)', M.exit.ms / M.arrive.ms <= 0.6, (M.exit.ms / M.arrive.ms).toFixed(2))
check('stagger: sibling 3 waits 120 ms, sibling 6 and 9 wait the cap', T.staggerDelay(3) === 120 && T.staggerDelay(6) === 240 && T.staggerDelay(9) === 240)

section('Spring.curve: the sampled spline lands, overshoots by the stated amount, and peaks where it says')
function sample(points, t) {   // evaluate the cubic Bezier spline `points` (x1,y1,x2,y2,x,y per piece) at time t
  let x0 = 0, y0 = 0
  for (let i = 0; i < points.length; i += 6) {
    const [x1, y1, x2, y2, x3, y3] = points.slice(i, i + 6)
    if (t <= x3 + 1e-12) {
      let lo = 0, hi = 1
      for (let k = 0; k < 60; k++) {
        const u = (lo + hi) / 2, v = 1 - u
        const x = v * v * v * x0 + 3 * v * v * u * x1 + 3 * v * u * u * x2 + u * u * u * x3
        if (x < t) lo = u; else hi = u
      }
      const u = (lo + hi) / 2, v = 1 - u
      return v * v * v * y0 + 3 * v * v * u * y1 + 3 * v * u * u * y2 + u * u * u * y3
    }
    x0 = x3; y0 = y3
  }
  return y0
}
for (const [name, tok] of [['arrive', M.arrive], ['control', M.control], ['celebrate', M.celebrate]]) {
  const pts = S.curve(tok.damping, tok.peakAt, 8)
  let peak = 0, peakT = 0
  for (let i = 0; i <= 1000; i++) { const y = sample(pts, i / 1000); if (y > peak) { peak = y; peakT = i / 1000 } }
  check(`${name}: starts at 0 and ends on exactly 1`, pts[pts.length - 2] === 1 && pts[pts.length - 1] === 1 && near(sample(pts, 0), 0, 1e-9))
  check(`${name}: overshoot ${((peak - 1) * 100).toFixed(2)} % is Spring.overshoot ${(S.overshoot(tok.damping) * 100).toFixed(2)} % to within 0.4 points`, near(peak - 1, S.overshoot(tok.damping), 0.004))
  check(`${name}: peaks at ${peakT.toFixed(3)} of the duration, the stated ${tok.peakAt} to within 0.04`, near(peakT, tok.peakAt, 0.04))
}

finish('spring')
