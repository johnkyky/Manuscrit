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
    (tx: 0, ty: 0, lb: (0, 0), ub: (2, 3), front: 0),
    (tx: 0, ty: 1, lb: (0, 4), ub: (2, 6), front: 1),
    (tx: 0, ty: 2, lb: (0, 7), ub: (2, 11), front: 2),
    (tx: 1, ty: 0, lb: (3, 3), ub: (5, 6), front: 2),
    (tx: 1, ty: 1, lb: (3, 7), ub: (5, 9), front: 3),
    (tx: 1, ty: 2, lb: (3, 10), ub: (5, 14), front: 4),
    (tx: 2, ty: 0, lb: (6, 6), ub: (9, 9), front: 4),
    (tx: 2, ty: 1, lb: (6, 10), ub: (9, 13), front: 5),
    (tx: 2, ty: 2, lb: (6, 14), ub: (9, 18), front: 6),
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
    circle(
      (rel: (0, 0), to: str(tile.at("tx")) + "-" + str(tile.at("ty")) + ".center"),
      radius: 0.25cm,
      fill: colors.at(calc.rem(tile.at("front"), 5)),
      stroke: black,
    )
    content(
      (rel: (0, 0), to: str(tile.at("tx")) + "-" + str(tile.at("ty")) + ".center"),
      text(size: 10pt, str(tile.at("front"))),
    )
  }
})
