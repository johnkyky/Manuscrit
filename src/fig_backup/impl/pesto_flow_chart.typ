#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#import fletcher.shapes: diamond


#set text(size: 9pt, hyphenate: false)
#set par(justify: false, leading: 0.5em)
#import fletcher.shapes: diamond, hexagon
#let extbloc(coord, label, ..args) = node(
  coord,
  label,
  shape: hexagon,
  width: 1.5cm,
  height: 1cm,
  ..args,
)
#let bloc(coord, label, ..args) = node(
  coord,
  label,
  shape: rect,
  corner-radius: 3pt,
  width: 2cm,
  height: 1cm,
  stroke: black,
  ..args,
)

#let group(coord, label, ..args) = {
  node(
    coord,
    label,
    shape: rect,
    corner-radius: 5pt,
    stroke: blue,
    enclose: args.at("enclose", default: ()),
    ..args,
  )
}

#let arrow(vertices, marks: "-|>", ..options) = edge(
  vertices: vertices,
  marks: marks,
  stroke: black,
  ..options,
)

#let origX = 1cm
#let height = 8cm

#diagram(
  debug: false,
  node-stroke: black,

  // first col
  bloc((origX, height), "Input File", name: "pesto:src"),
  bloc((rel: (0cm, -2cm), to: "pesto:src"), [JSON / C++\ configuration], name: "pesto:config"),

  // pesto CLI
  bloc(
    (rel: (3.5cm, 0cm), to: "pesto:src"),
    text(size: 9pt, "Is OpenScop ?"),
    shape: diamond,
    name: "pesto:ifc",
    stroke: black,
  ),
  arrow((<pesto:src>, <pesto:ifc>)),

  extbloc((rel: (0cm, -2cm), to: "pesto:ifc"), "Clan", name: "pesto:clan"),
  bloc(
    (rel: (2.5cm, -1cm), to: "pesto:ifc"),
    text(size: 9pt, [Polyhedral\ Representation\ (OpenScop)]),
    name: "pesto:polyrepr",
    height: 1.5cm,
  ),
  arrow((<pesto:ifc>, <pesto:clan>), label: "No"),
  arrow((<pesto:ifc.east>, <pesto:polyrepr.north>), label: "Yes", corner: right),
  arrow((<pesto:clan.east>, <pesto:polyrepr.south>), corner: left),

  // end pesto CLI

  bloc((rel: (3cm, 0.5cm), to: "pesto:polyrepr"), "IR Helpers", name: "pesto:helper"),

  // fourth line
  bloc((rel: (3cm, 1cm), to: "pesto:helper"), "Pesto Program", name: "pesto:prog"),
  arrow(
    (
      <pesto:polyrepr.east>,
      (rel: (0.5cm, 0cm), to: <pesto:polyrepr.east>),
      (rel: (0.5cm, 1.5cm), to: <pesto:polyrepr.east>),
      <pesto:prog.west>,
    ),
    corner: right,
  ),

  bloc((rel: (0cm, -2.5cm), to: "pesto:prog"), "Pluto pass", name: "pesto:pass:pluto"),
  bloc((rel: (0cm, -1.5cm), to: "pesto:pass:pluto"), "Parametric Tiling Pass", name: "pesto:pass:ptile"),
  bloc((rel: (0cm, -2cm), to: "pesto:pass:ptile"), "Codegen Pass", name: "pesto:pass:cloog"),
  node((rel: (0cm, -1cm), to: "pesto:pass:ptile"), text("..."), stroke: none),

  extbloc((rel: (-3cm, 0cm), to: "pesto:pass:pluto"), "Pluto", name: "pesto:pluto"),
  extbloc((rel: (-3cm, 0cm), to: "pesto:pass:ptile"), "Trahrhe", name: "pesto:trahrhe"),
  extbloc((rel: (-3cm, 0cm), to: "pesto:pass:cloog"), "Cloog", name: "pesto:cloog"),

  bloc((rel: (3cm, 0cm), to: "pesto:pass:ptile"), "Trahrhe headers", name: "pesto:trahrhe:header"),
  bloc((rel: (3cm, 0cm), to: "pesto:pass:cloog"), "Output C code", name: "pesto:out"),

  arrow((<pesto:pass:ptile.east>, <pesto:trahrhe:header.west>)),
  arrow((<pesto:pass:cloog.east>, <pesto:out.west>)),

  arrow((<pesto:pass:pluto.west>, <pesto:pluto.east>), marks: "<|--|>"),
  arrow((<pesto:pass:ptile.west>, <pesto:trahrhe.east>), marks: "<|--|>"),
  arrow((<pesto:pass:cloog.west>, <pesto:cloog.east>), marks: "<|--|>"),


  node(
    [#align(top, block(width: 100%, fill: blue.lighten(50%), [#v(5pt) Pesto CLI #v(5pt)]))],
    enclose: (
      (rel: (-1.8cm, 1.8cm), to: "pesto:ifc"),
      (rel: (-1cm, -1cm), to: "pesto:clan"),
      (rel: (1.2cm, -1cm), to: "pesto:polyrepr"),
    ),
    name: "pesto:cli",
    inset: 0cm,
    stroke: blue,
  ),
  arrow(
    (
      <pesto:config.east>,
      (rel: (0.3cm, 0cm), to: <pesto:config.east>),
      (rel: (0.3cm, 1.4cm), to: <pesto:config.east>),
      <pesto:cli.west>,
    ),
    corner: right,
  ),

  node(
    [#align(top, block(width: 100%, fill: olive.lighten(50%), [#v(5pt) Pesto Library #v(5pt)]))],
    enclose: (
      (rel: (1.5cm, 1.3cm), to: "pesto:prog"),
      (rel: (-1.2cm, -1cm), to: "pesto:cloog"),
      (rel: (0cm, -1cm), to: "pesto:pass:cloog"),
    ),
    name: "pesto:lib",
    inset: 0cm,
    stroke: olive,
  ),
  arrow(
    (
      <pesto:config.south>,
      (rel: (0cm, -1cm), to: <pesto:config.south>),
      (rel: (0cm, -1.15cm), to: <pesto:lib.west>),
    ),
    corner: right,
  ),

  node(
    [#align(top, block(width: 100%, fill: black.lighten(80%), [#v(5pt) Pass Manager #v(5pt)]))],
    enclose: (
      (rel: (-1.3cm, 1.3cm), to: "pesto:pass:pluto"),
      (rel: (1.3cm, -0.8cm), to: "pesto:pass:cloog"),
    ),
    name: "pesto:passmanager",
    inset: 0cm,
    stroke: black,
  ),

  arrow((<pesto:prog.south>, <pesto:passmanager.north>)),

  // node(
  //   (rel: (1, 0), to: "pesto:polyrepr"),
  //   align(top + center)[Pass Manager],
  //   name: "pesto:pm",
  //   shape: rect,
  //   enclose: (
  //     (2, 0),
  //     (2, 1),
  //     (2, -1.5),
  //   ),
  //   stroke: (dash: "dashed", paint: black),
  //   width: 4cm,
  // ),
  // node(
  //   align(top + left)[#text(fill: green, "Pesto CLI")],
  //   name: <pesto>,
  //   stroke: green,
  //   enclose: ((0.55, 0), (2, 1.5), (2.5, -2)),
  // ),
  // node(
  //   align(top + center)[#text(fill: blue, "Trahrhe")],
  //   name: <trahrhe>,
  //   stroke: blue,
  //   enclose: ((3, -1.1),),
  //   shape: rect,
  //   width: 1.3cm,
  // ),
)
