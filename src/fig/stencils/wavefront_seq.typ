#import "../../plot.typ" as zplot: cetz

#cetz.canvas(length: 0.25cm, {
  import cetz.draw: *
  import cetz: matrix


  let T = 10
  let N = 10
  zplot.axis-unbound(
    Xmax: T * 2,
    Ymax: T + N,
    xParamName: $T$,
    yParamName: $T + N$,
    xAxisName: $t$,
    yAxisName: $i$,
    axis-label-offset: -0.2cm,
  )


  let x = 3
  let y = 2
  for t0 in range(0, T) {
    for t1 in range(t0, t0 + N) {
      let t = t0
      let i = calc.max(0, t1 - t0)
      circle((t0 * 2, t1), radius: 0.08cm, fill: blue, name: "p-" + str(t) + "-" + str(i), stroke: none)
    }
  }

  let TX = 3
  let TY = 3
  let Toffset = (0.3, 0.3)

  let ubzt0 = calc.ceil((T) / TX)
  let ubzt1 = calc.ceil((T + N + 1) / TY)

  for t0 in range(0, ubzt0) {
    for t1 in range(calc.ceil((TX * t0 - TY + 1) / TY), calc.min(
      ubzt1,
      calc.floor((TX * (t0 + 1) + N - 1 - 1) / TY) + 1,
    )) {
      rect(
        ((calc.max(t0 * TX, 0)) * 2 - Toffset.at(0), calc.max(t1 * TY, 0) - Toffset.at(1)),
        (
          (calc.min((t0 + 1) * TX, T) - 1) * 2 + Toffset.at(0),
          calc.min((t1 + 1) * TY, T + N - 1) - 1 + Toffset.at(1),
        ),
        stroke: (paint: black, thickness: 1.5pt, dash: "dashed"),
      )
    }
  }
  let dep-style = (mark: (end: ">", fill: red, length: 0.2cm, width: 0.2cm), stroke: red + 2pt)

  line((4 * 2, 3 + 4), (4 * 2, 6 + 4), ..dep-style)
  line((4 * 2, 3 + 4), (7 * 2, 0 + 7), ..dep-style)
  line((4 * 2, 3 + 4), (7 * 2, 3 + 7), ..dep-style)
})
