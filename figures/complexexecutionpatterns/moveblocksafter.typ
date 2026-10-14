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
    [*Preheader B*],
    fill: color-red,
    stroke: color-red-stroke,
  ),

  node(
    (0, 3),
    [*Loop A*],
    fill: color-blue,
    stroke: color-blue-stroke,
    name: <loopA>,
  ),

  node(
    (0, 4),
    [*Loop B*],
    fill: color-red,
    stroke: color-red-stroke,
    name: <loopB>,
  ),

  node(
    move(
      dx: -4em,
      rotate(-90deg)[
        #box(
          text(fill: gradient.linear(
            color-red-stroke,
            color-blue-stroke,
            dir: ltr,
          ))[*SCoP A + B*],
        )
      ],
    ),
    enclose: (<loopA>, <loopB>),
    stroke: 1pt
      + gradient.linear(color-blue-stroke, color-red-stroke, dir: ttb),
    snap: false,
  ),

  node((0, 5), [*Exit*], fill: color-gray, stroke: color-gray-stroke),

  edge((0, 0), (0, 1), "->"),
  edge((0, 1), (0, 2), "->"),
  edge((0, 2), (0, 3), "->"),
  edge((0, 3), (0, 4), "->"),
  edge((0, 4), (0, 5), "->"),

  edge((0.4, 3.2), (0.4, 2.8), "->", bend: -90deg),
  edge((0.4, 4.2), (0.4, 3.8), "->", bend: -90deg),
)
