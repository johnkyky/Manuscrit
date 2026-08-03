#import "../../plot.typ" as zplot: cetz
#import "@preview/qcm:0.1.0": colormap

#cetz.canvas(length: 0.25cm, {
  import cetz.draw: *
  import cetz: matrix


  let T = 10
  let N = 10
  zplot.axis-unbound(
    Xmax: T * 2,
    Ymax: T + N,
    xParamName: $T$,
    yParamName: align(left, $T + N$),
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

  let colors = colormap("Set1", 5)

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
        name: str(t0) + "-" + str(t1),
        stroke: (paint: black, thickness: 1.5pt, dash: "dashed"),
      )
      let z = t0 + t1
      circle(
        (rel: (0, 0), to: str(t0) + "-" + str(t1) + ".center"),
        radius: 0.25cm,
        fill: colors.at(calc.rem(z, 5)),
        stroke: black,
      )

      content(
        (rel: (0, 0), to: str(t0) + "-" + str(t1) + ".center"),
        text(size: 10pt, str(z)),
      )
    }
  }
})
