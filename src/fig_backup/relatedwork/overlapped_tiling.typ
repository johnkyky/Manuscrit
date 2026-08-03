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
    let tileoffset = 0.15
    let tilewidth = 8
    let tileheight = 2

    let trapez(pos, ..args) = group({
      line(
        pos,
        (rel: (tilewidth - 1, 0)),
        (rel: (-2, tileheight - 1)),
        (rel: (-(tilewidth - 4 - 1), 0)),
        close: true,
        ..args,
      )
    })

    let textures = (cgreen, cgreen,)
    for ty in range(0, 3) {
      for tx in range(3) {
        trapez((2 + tx * 4, ty * (tileheight)), fill: textures.at(calc.rem-euclid(tx, 2)))
      }
    }

    // legend
    let legend(pos, body, color) = {
      rect(pos, (rel: (1cm, 0.1cm)), fill: color, stroke: none)
      content((rel: (0.2cm, 0cm)), body, fill: black, anchor: "mid-west")
    }

    for t in range(0, 4) {
      line((-0.5, tileheight * t - 0.5), (N - 0.5, tileheight * t - 0.5), stroke: (paint: black, dash: "dashed"))
    }
    legend((rel: (5cm, 0cm), to: "y-axis.end"), "Inter-tile dependency", black)
    legend((rel: (5cm, -0.4cm), to: "y-axis.end"), "Iteration dependency", cred)
    // rect(
    //   (rel: (5cm, 0.5cm), to: "y-axis.end"),
    //   (rel: (6cm, 0.6cm), to: "y-axis.end"),
    //   fill: black,
    //   stroke: none,
    // )
  },
)
