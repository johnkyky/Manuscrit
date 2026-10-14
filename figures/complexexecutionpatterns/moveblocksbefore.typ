#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#import "../../src/colors.typ": *

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
  node((0, 0), [*Entry*], fill: color-gray, stroke: color-gray-stroke),

  node((0, 1), [*Preheader A*], fill: color-blue, stroke: color-blue-stroke),

  node(
    (0, 2),
    [*Loop A*],
    fill: color-blue,
    stroke: color-blue-stroke,
    name: <loopA>,
  ),

  node(
    move(dx: -4em, rotate(-90deg)[#text(color-blue-stroke)[*SCoP A*]]),
    enclose: (<loopA>,),
    stroke: 1pt + color-blue-stroke,
    snap: false,
  ),

  node(
    (0, 3),
    [*Preheader B*],
    fill: color-red,
    stroke: color-red-stroke,
  ),

  node(
    (0, 4),
    [*Loop B*],
    fill: color-red,
    stroke: color-red-stroke,
    name: <loopB>,
  ),

  node(
    move(dx: -4em, rotate(-90deg)[#text(color-red-stroke)[*SCoP B*]]),
    enclose: (<loopB>,),
    stroke: 1pt + color-red-stroke,
    snap: false,
  ),

  node((0, 5), [*Exit*], fill: color-gray, stroke: color-gray-stroke),

  edge((0, 0), (0, 1), "->"),
  edge((0, 1), (0, 2), "->"),
  edge((0, 2), (0, 3), "->"),
  edge((0, 3), (0, 4), "->"),
  edge((0, 4), (0, 5), "->"),

  edge((0.4, 2.2), (0.4, 1.8), "->", bend: -90deg),
  edge((0.4, 4.2), (0.4, 3.8), "->", bend: -90deg),
)
