#import "../../plot.typ" as zplot: cetz

#let N = 50

#let lowCst(x) = {
  let a = (N - 20) / (4 * (N - 5))
  let b = 5 * (1 - a)
  return a * x + b
}

#let upCst(x) = {
  let a = (N - 20) / (0.9 * (N - 5))
  let b = 25 - a * 5
  return a * x + b
}

#let plot-domain-bounds() = {
  import cetz.draw: *

  let lineStartX = 5
  line((lineStartX, lowCst(5)), (N, lowCst(N)))
  line((lineStartX, upCst(lineStartX)), (N, upCst(N)))
}

#let canvas-len = 0.08cm
