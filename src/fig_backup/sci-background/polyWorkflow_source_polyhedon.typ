#import "../../plot.typ" as zplot: cetz

#grid(columns: 2, rows: 1, grid.cell(align: horizon + center, cetz.canvas(length: 0.5cm, {
  import cetz.draw: *
  let cred = red.transparentize(50%)
  // let cred = red
  let cgreen = green.transparentize(70%)
  // let cgreen = green
  let cpurple = purple.transparentize(70%)
  // let cpurple = purple

  let N = 7
  let M = 3
  let tick-size = 0.2

  zplot.axis-unbound(Xmax: N, Ymax: M, xAxisName: $i$, yAxisName: $j$, xParamName: $N=#N$, yParamName: $M=#M$)

  // Draw point lattice
  group({
    for x in range(N + 1) {
      for y in range(M + 1) {
        circle((x, y), radius: 0.2, fill: blue, stroke: none)
      }
    }
  })
})), grid.cell(align: horizon + center, [
  #show math.equation: set text(size: 10pt)
  #math.equation(block: true, numbering: none)[
    $
      cal(D) vec(N, M) = { vec(i, j) in bb(Z)^2 cases(delim: "|", 0 <= i <= N, 0 <= j <= M) }
    $
  ]
]))
