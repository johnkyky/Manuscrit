#import "../../plot.typ" as zplot: cetz

#cetz.canvas(length: 0.20cm, {
  import cetz.draw: *

  let cblue = blue.transparentize(80%)

  let N = 22
  let TX = 4
  let TY = 4

  zplot.axis(Xmax: N + 0.1 * N, Ymax: N + 0.1 * N)
  // Draw point lattice
  zplot.triang-domain(N, fill: none)

  let tile-offset = 0.4
  for tx in range(0, N + 1, step: TX) {
    for ty in range(0, tx + TX, step: TY) {
      rect(
        (tx - tile-offset, ty - tile-offset),
        (tx + TX - 1 + tile-offset, ty + TY - 1 + tile-offset),
        stroke: (paint: gray),
        fill: cblue,
      )
    }
  }
})
