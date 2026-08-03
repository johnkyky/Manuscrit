#import "@preview/lilaq:0.5.0" as lq
#import "../../plot.typ" as zplot: cetz

#let aligned_tiling_data = csv("../../../data/aligned_alg_tiling.csv", row-type: dictionary)

#let xlabels = aligned_tiling_data.map(row => row.at("benchmark"))
#let xticks = xlabels.map(rotate.with(-45deg, reflow: true)).enumerate()
#let xs = range(0, xticks.len())

#{
  show: zplot.opaque-theme
  lq.diagram(
    cycle: lq.color.map.okabe-ito,
    width: 100%,
    height: 5cm,
    xaxis: (ticks: xticks, subticks: none),
    ylabel: "Execution time (s)",
    lq.bar(
      xs,
      aligned_tiling_data.map(row => float(row.at("pluto_static"))),
      width: 0.3,
      offset: -0.3,
      label: "Pluto (static)",
    ),
    lq.bar(
      xs,
      aligned_tiling_data.map(row => float(row.at("pluto_dynamic"))),
      width: 0.3,
      offset: 0,
      label: "Pluto (dynamic)",
    ),
    lq.bar(
      xs,
      aligned_tiling_data.map(row => float(row.at("pesto"))),
      width: 0.3,
      offset: 0.3,
      label: "Algebraic tiling (aligned)",
    ),
    ..xs
    .zip(aligned_tiling_data.map(row => float(row.at("pluto_static"))))
    .map(((x, y)) => {
      let align = if y > 0.5 { top } else { bottom }
      lq.place(x - 0.3, y, pad(0.2em, text(size: 8pt, [#calc.round(y, digits: 3)])), align: align)
    }),
    ..xs
    .zip(aligned_tiling_data.map(row => float(row.at("pluto_dynamic"))))
    .map(((x, y)) => {
      let align = if y > 0.5 { top } else { bottom }
      lq.place(x, y, pad(0.2em, text(size: 8pt, [#calc.round(y, digits: 3)])), align: align)
    }),
    ..xs
    .zip(aligned_tiling_data.map(row => float(row.at("pesto"))))
    .map(((x, y)) => {
      let align = if y > 0.5 { top } else { bottom }
      lq.place(x + 0.3, y, pad(0.2em, text(size: 8pt, [#calc.round(y, digits: 3)])), align: align)
    }),
  )
}