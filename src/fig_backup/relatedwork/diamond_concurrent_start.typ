#import "../../plot.typ" as zplot: cetz

#cetz.canvas(
  length: 0.6cm,
  {
    import cetz.draw: *

    let N = 20
    let M = 8

    let cred = red.transparentize(50%)
    // let cred = red
    let cgreen = green.transparentize(70%)
    // let cgreen = green

    zplot.axis(Xmax: N, Ymax: M, xName: $x_0$, yName: $t$, axis-offset: -1)

    for i in range(0, N) {
      for j in range(0, M) {
        circle((i, j), radius: 0.15, fill: blue, name: "p-" + str(i) + "-" + str(j), stroke: none)
      }
    }

    let arrowspacing = 0.05

    let intertile-style = (mark: (end: ">", fill: cred, scale: 0.5), stroke: cred + 0.7pt)
    for i in range(2, N - 2) {
      for j in range(0, M - 1) {
        let cur = "p-" + str(i) + "-" + str(j)
        let upleft = "p-" + str(i - 2) + "-" + str(j + 1)
        let upright = "p-" + str(i + 2) + "-" + str(j + 1)
        let up = "p-" + str(i) + "-" + str(j + 1)
        line(
          (rel: (-arrowspacing, arrowspacing), to: cur + ".north"),
          (rel: (arrowspacing, -arrowspacing), to: upleft + ".south"),
          ..intertile-style,
        )
        line((rel: (0, arrowspacing), to: cur + ".north"), (rel: (0, -arrowspacing), to: up + ".south"), ..intertile-style)
        line(
          (rel: (arrowspacing, arrowspacing), to: cur + ".north"),
          (rel: (-arrowspacing, -arrowspacing), to: upright + ".south"),
          ..intertile-style,
        )
      }
    }
    let tileoffset = 0.15
    let tilewidth = 4
    let tileheight = 1
    for ty in range(0, 2) {
      for tx in range(0, 3) {
        line(
          (5 * tx + 5, ty * 3 + 1 - 1 - tileoffset),
          (5 * tx + 5 + 2 + tileoffset, ty * 3 + 1),
          (5 * tx + 5, ty * 3 + 1 + 1 + tileoffset),
          (5 * tx + 5 - 2 - tileoffset, ty * 3 + 1),
          stroke: (paint: black, thickness: 1pt),
          fill: cgreen,
          close: true,
        )
      }
    }
    for tx in range(0, 4) {
      line(
        (5 * tx + 2.5 + 2.5 - tileoffset, 0 - 2 * tileoffset),
        (5 * tx + 2.5, 1 - tileoffset),
        (5 * tx + 2.5 - 2.5 + tileoffset, 0 - 2 * tileoffset),
        stroke: (paint: black, thickness: 1pt),
        fill: cgreen,
        close: true,
      )
    }
    for tx in range(0, 4) {
      line(
        (5 * tx + 2.5, 1 + tileoffset),
        (5 * tx + 2.5 + 2.5 - tileoffset, 2.5),
        (5 * tx + 2.5, 4 - tileoffset),
        (5 * tx + 2.5 - 2.5 + tileoffset, 2.5),
        stroke: (paint: black, thickness: 1pt),
        fill: cgreen,
        close: true,
      )
    }

    // dependencies
    line((10, 1), (10 - 2.5, 1 + 1.5), stroke: (paint: black, thickness: 2pt), mark: (end: ">", fill: black))
    line((10, 1), (10 + 2.5, 1 + 1.5), stroke: (paint: black, thickness: 2pt), mark: (end: ">", fill: black))

    // legend
    let legend(pos, body, color) = {
      rect(pos, (rel: (1cm, 0.1cm)), fill: color, stroke: none)
      content((rel: (0.2cm, 0cm)), body, fill: black, anchor: "mid-west")
    }

    legend((rel: (5cm, 0cm), to: "y-axis.end"), "Inter-tile dependency", black)
    // legend((rel: (5cm, -0.4cm), to: "y-axis.end"), "Iteration dependency", red.transparentize(50%))
    legend((rel: (5cm, -0.4cm), to: "y-axis.end"), "Iteration dependency", red)
    // rect(
    //   (rel: (5cm, 0.5cm), to: "y-axis.end"),
    //   (rel: (6cm, 0.6cm), to: "y-axis.end"),
    //   fill: black,
    //   stroke: none,
    // )
  },
)
