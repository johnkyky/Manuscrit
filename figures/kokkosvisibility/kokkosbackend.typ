#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#import "../../src/colors.typ": *

#show raw: set text(size: 6.5pt)
#let diagram = diagram.with(
  spacing: (3em, 4em),
  node-shape: rect,
  node-stroke: 0.7pt,
  edge-stroke: 0.7pt,
  node-corner-radius: 4pt,
)

#diagram(
  node(
    (0, -3),
    text(size: 1.2em, weight: "bold")[Interface],
    stroke: none,
  ),
  node(
    (1, -3),
    text(size: 1.2em, weight: "bold")[Backend],
    stroke: none,
  ),
  node(
    (2.5, -3),
    text(size: 1.2em, weight: "bold")[Politique],
    stroke: none,
  ),

  // Interface
  node(
    (0, 0),
    align(left)[#raw(
      "template<class Policy, class Backend>\nparallel_for(Policy<Backend>, ...)",
      lang: "cpp",
    )],
    fill: color-blue,
    stroke: color-blue-stroke,
    corner-radius: 2pt,
    name: <interface>,
  ),

  // Backend
  node(
    (1, -1),
    align(left)[#raw(
      "template<class Policy>\nparallel_for(Policy<Serial>, ...)",
      lang: "cpp",
    )],
    fill: color-green,
    stroke: color-green-stroke,
    corner-radius: 2pt,
    name: <serial>,
  ),
  node(
    (1, 0),
    align(left)[#raw(
      "template<class Policy>\nparallel_for(Policy<OpenMP>, ...)",
      lang: "cpp",
    )],
    fill: color-red,
    stroke: color-red-stroke,
    corner-radius: 2pt,
    name: <openmp>,
  ),
  node(
    (1, 1),
    align(left)[#raw(
      "template<class Policy>\nparallel_for(Policy<Cuda>, ...)",
      lang: "cpp",
    )],
    fill: color-purple,
    stroke: color-purple-stroke,
    corner-radius: 2pt,
    name: <cuda>,
  ),

  // Policy
  node(
    (2, -2),
    align(left)[#raw("parallel_for(Range<Serial>, ...)", lang: "cpp")],
    fill: color-green,
    stroke: color-green-stroke,
    corner-radius: 2pt,
    name: <range_serial>,
  ),
  node(
    (2, -1),
    align(left)[#raw("parallel_for(MDRange<Serial>, ...)", lang: "cpp")],
    fill: color-green,
    stroke: color-green-stroke,
    corner-radius: 2pt,
    name: <mdrange_serial>,
  ),

  node(
    (2, 0),
    align(left)[#raw("parallel_for(Range<OpenMP>, ...)", lang: "cpp")],
    fill: color-red,
    stroke: color-red-stroke,
    corner-radius: 2pt,
    name: <range_openmp>,
  ),
  node(
    (2, 1),
    align(left)[#raw("parallel_for(MDRange<OpenMP>, ...)", lang: "cpp")],
    fill: color-red,
    stroke: color-red-stroke,
    corner-radius: 2pt,
    name: <mdrange_openmp>,
  ),

  node(
    (1.7, 2),
    align(left)[#raw("...", lang: "cpp")],
    fill: color-purple,
    stroke: color-purple-stroke,
    corner-radius: 2pt,
    name: <next>,
  ),

  // Target
  node(
    (3, -0.5),
    [#raw("HostIterateTile", lang: "cpp")],
    fill: color-orange,
    stroke: color-orange-stroke,
    corner-radius: 2pt,
    name: <hostiterate_tile>,
  ),
  node(
    (3, 0.5),
    [#raw("HostIterate", lang: "cpp")],
    fill: color-orange,
    stroke: color-orange-stroke,
    corner-radius: 2pt,
    name: <hostiterate>,
  ),

  // Edges
  edge(<interface.east>, <serial>, "-|>"),
  edge(<interface.east>, <openmp>, "-|>"),
  edge(<interface.east>, <cuda>, "-|>"),

  edge(<serial.east>, <range_serial>, "-|>"),
  edge(<serial.east>, <mdrange_serial>, "-|>"),

  edge(<openmp.east>, <range_openmp>, "-|>"),
  edge(<openmp.east>, <mdrange_openmp>, "-|>"),

  edge(<cuda.east>, <next>, "-|>"),

  edge(<mdrange_serial.east>, <hostiterate_tile.west>, "--|>"),
  edge(<mdrange_openmp.east>, <hostiterate_tile.west>, "--|>"),

  edge(
    <mdrange_serial.east>,
    <hostiterate.west>,
    [`usePolyOpt`],
    label-pos: 35%,
    label-angle: auto,
    label-sep: -12pt,
    "--|>",
  ),
  edge(
    <mdrange_openmp.east>,
    <hostiterate.west>,
    [`usePolyOpt`],
    label-pos: 45%,
    label-angle: auto,
    label-sep: -12pt,
    "--|>",
  ),
)
