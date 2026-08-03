#import "../../plot.typ" as zplot: cetz

#grid(
  columns: 2,
  rows: 1,
  gutter: 0.5em, 
  grid.cell(align: horizon + center, cetz.canvas(length: 0.5cm, {
    import cetz.draw: *

    /* SKEWED ITERATION DOMAIN */
    let N = 7
    let M = 3
    let tick-size = 0.1cm
    let label-offset = -0.2cm
    zplot.axis-unbound(
      Xmax: N,
      Ymax: M,
      xAxisName: $t_0$,
      xParamName: $N$,
      yAxisName: $t_1$,
      yParamName: $M$,
      tick-size: tick-size,
      axis-label-offset: label-offset,
    )
    line((rel: (0, 0), to: "x-axis.end"), (rel: (M, 0)), name: "axis-extent")
    line((rel: (0, 0.5pt), to: "axis-extent.end"), (rel: (0, -tick-size)))
    content((rel: (0, label-offset), to: "axis-extent.end"), $N + M$, anchor: "north")

    // Draw point lattice
    group({
      for x in range(N + M + 2) {
        for y in range(M + 1) {
          if y < x - N or y > x { continue }
          circle((x, y), radius: 0.2, fill: blue, stroke: none)
        }
      }
    })
  })),
  grid.cell(
    align: horizon + center,
    grid(
      columns: 1,
      rows: 2,
      gutter: 1em,
      [
        #show math.equation: set text(size: 10pt)
        #math.equation(block: true, numbering: none)[
          $
            theta vec(N, M) = { vec(i, j) -> vec("t0", "t1") cases(delim: "|", "t0" = i + j, "t1" = j) }
          $
        ]
      ],
      [
        #show math.equation: set text(size: 10pt)
        #math.equation(
          block: true,
          numbering: none,
        )[
          $
            cal(D) vec(N, M) = { vec("t0", "t1") in bb(Z)^2 cases(delim: "|", 0 <= "t0" <= N + M, 0 <= "t1" <= M, "t0" - N <= "t1", "t1" <= "t0") }
          $
        ]
      ],
    ),
  ),
)
