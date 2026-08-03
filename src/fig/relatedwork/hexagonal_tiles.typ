#import "../../plot.typ" as zplot: cetz

#cetz.canvas(
  length: 0.6cm,
  {
    import cetz.draw: *

    let cred = red.transparentize(50%)
    // let cred = red
    let cgreen = green.transparentize(70%)
    // let cgreen = green
    let cpurple = purple.transparentize(70%)
    // let cpurple = purple

    let N = 20
    let M = 8
    set-viewport((0, 0), (N, M), bounds: (N, M))

    zplot.axis(Xmax: N, Ymax: M, xName: $x_0$, yName: $t$, axis-offset: -1)

    for i in range(0, N) {
      for j in range(0, M) {
        circle((i, j), radius: 0.15, fill: blue, name: "p-" + str(i) + "-" + str(j), stroke: none)
      }
    }

    let arrowspacing = 0.05

    let intertile-style = (
      mark: (end: ">", fill: cred, scale: 0.5),
      stroke: cred + 0.7pt,
    )
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

    let tile_w0 = 3
    let tile_h = 1.5
    let tile_d = 3
    let hex1(pos, ..args) = line(
      pos,
      (rel: (tile_w0 - 1, 0)),
      (rel: (tile_d, tile_h)),
      (rel: (-tile_d, tile_h)),
      (rel: (-tile_w0, 0)),
      (rel: (-tile_d, -tile_h)),
      (rel: (tile_d, -tile_h)),
      close: true,
      stroke: black,
      ..args,
    )

    hex1((3, 1), fill: cgreen)
    hex1((15, 1), fill: cgreen)
    hex1((9, 3), fill: cpurple)
    hex1((9, -1), fill: cpurple)
  },
)
