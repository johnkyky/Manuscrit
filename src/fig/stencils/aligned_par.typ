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
    yParamName: align(left, [$T + N$]),
    xAxisName: $t$,
    yAxisName: $i$,
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


  let Toffset = 0.3
  let colors = colormap("Set1", 5)

  let tiles = (
    (tx: 0, ty: 0, lb: (0, 0), ub: (2, 6)),
    (tx: 0, ty: 1, lb: (0, 7), ub: (2, 10)),
    (tx: 0, ty: 2, lb: (0, 11), ub: (2, 11)),
    (tx: 1, ty: 0, lb: (3, 0), ub: (5, 6)),
    (tx: 1, ty: 1, lb: (3, 7), ub: (5, 10)),
    (tx: 1, ty: 2, lb: (3, 11), ub: (5, 14)),
    (tx: 2, ty: 0, lb: (6, 0), ub: (9, 6)),
    (tx: 2, ty: 1, lb: (6, 7), ub: (9, 10)),
    (tx: 2, ty: 2, lb: (6, 11), ub: (9, 18)),
  )

  for tile in tiles {
    rect(
      (tile.at("lb").at(0) * 2 - Toffset, tile.at("lb").at(1) - Toffset),
      (
        (tile.at("ub").at(0)) * 2 + Toffset,
        tile.at("ub").at(1) + Toffset,
      ),
      stroke: (paint: black, thickness: 1pt, dash: "dashed"),
      name: str(tile.at("tx")) + "-" + str(tile.at("ty")),
    )
  }

  for tx in range(0, 3) {
    for ty in range(0, 3) {
      let z = tx + ty
      circle(
        (rel: (0, 0), to: str(tx) + "-" + str(ty) + ".center"),
        radius: 0.25cm,
        fill: colors.at(calc.rem(z, 5)),
        stroke: black,
      )
      content(
        (rel: (0, 0), to: str(tx) + "-" + str(ty) + ".center"),
        text(size: 10pt, str(z)),
      )
    }
  }
})
