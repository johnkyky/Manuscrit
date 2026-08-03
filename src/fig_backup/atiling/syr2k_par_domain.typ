#import "../../plot.typ" as zplot: cetz

#cetz.canvas(length: 0.20cm, {
  import cetz.draw: *


  let N = 22
  let TX = 4
  let TY = 4

  zplot.axis(Xmax: N + 0.1 * N, Ymax: N + 0.1 * N)
  // Draw point lattice
  zplot.triang-domain(N, fill: none)

  let tile-offset = 1
  for tx in range(0, calc.div-euclid(N + 1, TX) + 1) {
    line(
      ((tx + 1) * TX, -1),
      ((tx + 1) * TX, N + 2),
      stroke: red,
    )
  }
  for ty in range(0, calc.div-euclid(N, TY) + 1) {
    line(
      (if ty == 0 { 0 } else { ty * TY }, (ty + 1) * TY),
      (TY * (calc.ceil(N / TY)), (ty + 1) * TY),
      stroke: (paint: gray, dash: "dashed"),
    )
  }
})
