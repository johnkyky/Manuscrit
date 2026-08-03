#import "../../plot.typ" as zplot: cetz

#cetz.canvas(length: 0.7cm, {
  import cetz.draw: *

  let tick-size = 0.2
  let axis-offset = 0.5

  let N = 20
  let M = 8

  zplot.axis(
    Xmax: N,
    Ymax: M,
    xName: $t_0$,
    yName: $t_1$,
    axis-offset: -1,
    axis-label-offset: -0.5,
  )

  // Draw point lattice
  for x in range(0, N) {
    for y in range(0, M) {
      let name = "p-" + str(x) + "-" + str(y)
      circle((x, y), radius: 0.2, fill: blue, stroke: none, name: name)
    }
  }

  // draw dependency arrows
  let mark = (end: ">", scale: 0.5, fill: black)
  for x in range(0, N) {
    for y in range(0, M) {
      let name = "p-" + str(x) + "-" + str(y)
      if x > 0 and y > 0 {
        let prec_name = "p-" + str(x - 1) + "-" + str(y - 1)
        line(prec_name + ".north-east", name + ".south-west", mark: mark, stroke: black)
      }
      if x > 0 {
        let prec_name = "p-" + str(x - 1) + "-" + str(y)
        line(prec_name + ".east", name + ".west", mark: mark, stroke: black)
      }
    }
  }

  // draw rectangular tile
  let tile-width = 3
  let tile-height = 2
  let tile-offset = 0.3
  let tile-x = 2
  let tile-y = 2
  for ti in range(0, N, step: tile-width) {
    for tj in range(0, M, step: tile-height) {
      rect(
        (ti - tile-offset, tj - tile-offset),
        (calc.min(ti + tile-width, N) - 1 + tile-offset, tj + tile-height + tile-offset - 1),
        stroke: (paint: red, thickness: 2pt),
        fill: none,
      )
    }
  }
})
