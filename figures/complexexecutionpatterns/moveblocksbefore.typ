#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node

#show raw: set text(size: 5pt)
#let diagram = diagram.with(
  spacing: 20pt,
  node-shape: rect,
  node-stroke: 0.7pt,
  edge-stroke: 0.7pt,
  node-corner-radius: 4pt,
  node-inset: 13pt,
)

#diagram(
  node((0, 0), [*Entry*], fill: silver),

  node((0, 1), [*Preheader A*], fill: teal),

  node((0, 2), [*Loop A*], fill: teal, name: <loopA>),

  node(
    move(dx: -4em, rotate(-90deg)[#text(teal)[*SCoP A*]]),
    enclose: (<loopA>,),
    stroke: 1pt + teal,
    snap: false,
  ),

  node((0, 3), [*Preheader B*], fill: orange),

  node((0, 4), [*Loop B*], fill: orange, name: <loopB>),

  node(
    move(dx: -4em, rotate(-90deg)[#text(orange)[*SCoP B*]]),
    enclose: (<loopB>,),
    stroke: 1pt + orange,
    snap: false,
  ),

  node((0, 5), [*Exit*], fill: silver),

  edge((0, 0), (0, 1), "->"),
  edge((0, 1), (0, 2), "->"),
  edge((0, 2), (0, 3), "->"),
  edge((0, 3), (0, 4), "->"),
  edge((0, 4), (0, 5), "->"),

  edge((0.4, 2.2), (0.4, 1.8), "->", bend: -90deg),
  edge((0.4, 4.2), (0.4, 3.8), "->", bend: -90deg),
)
