#import "../../plot.typ" as zplot: cetz
#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node

#diagram(
  node-stroke: .1em,
  spacing: 4em,
  node((0, 0), $arrow(x) = vec(x_1, x_2, ..., x_n)$, stroke: none),
  node((2, 0), $italic("pc") in bracket.l.stroked 1, italic("LTC") bracket.r.stroked$, stroke: none, width: 4cm),
  edge((0, 0), (2, 0), $r(arrow(x))$, "-|>", bend: 30deg),
  edge((2, 0), (0, 0), [$italic("trahrhe")(italic("pc"))$], "-|>", bend: 30deg),
)
