#import "../../plot.typ" as zplot: cetz

#cetz.canvas(length: 0.4cm, {
  import cetz.draw: *

  let T = 5
  let N = 5
  zplot.axis-unbound(
    Xmax: T * 2,
    Ymax: T + N,
    xParamName: $T$,
    yParamName: align(left, $T + N$),
    xAxisName: $t_0$,
    yAxisName: $t_1$,
  )

  for t0 in range(0, T + 1) {
    for t1 in range(t0, t0 + N + 1) {
      let t = t0
      let i = calc.max(0, t1 - t0)
      circle((t0 * 2, t1), radius: 0.15cm, fill: blue, name: "p-" + str(t) + "-" + str(i), stroke: none)
    }
  }

  let dep-style = (mark: (end: ">", fill: black, length: 0.09cm, width: 0.07cm), stroke: black + 0.7pt)

  for t in range(0, T + 1) {
    for i in range(0, N + 1) {
      let current = "p-" + str(t) + "-" + str(i)
      if t < T {
        line(current, "p-" + str(t + 1) + "-" + str(i), ..dep-style)
      }
      if i < N {
        line(current, "p-" + str(t) + "-" + str(i + 1), ..dep-style)
      }
      if i > 0 and t < T {
        line(current, "p-" + str(t + 1) + "-" + str(i - 1), ..dep-style)
      }
      if i < N and t < T {
        line(current, "p-" + str(t + 1) + "-" + str(i + 1), ..dep-style)
      }
    }
  }

  let TX = 2
  let TY = 2
  let Toffset = 0.3

  let ubzt0 = calc.ceil((T + 1) / TX)
  let ubzt1 = calc.ceil((T + 1 + N + 1) / TY)

  for t0 in range(0, ubzt0) {
    for t1 in range(calc.ceil((TX * t0 - TY + 1) / TY), calc.min(
      ubzt1,
      calc.floor((TX * (t0 + 1) + N - 1) / TY) + 1,
    )) {
      rect(
        (calc.max(t0 * TX, 0) * 2 - Toffset, calc.max(t1 * TY, 0) - Toffset),
        ((calc.min((t0 + 1) * TX, T + 1) - 1) * 2 + Toffset, calc.min((t1 + 1) * TY, T + N + 1) - 1 + Toffset),
        stroke: (paint: red, thickness: 1pt),
      )
    }
  }
})
