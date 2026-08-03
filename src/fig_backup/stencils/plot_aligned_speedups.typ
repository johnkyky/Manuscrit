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
    height: 4cm,
    legend: (position: top + center, fill: white),
    xaxis: (ticks: xticks, subticks: none, lim: (-1, xs.len())),
    yaxis: (lim: (0, 2.0)),
    ylabel: "Speedup",
    lq.bar(
      xs,
      aligned_tiling_data.map(row => float(row.at("speedup_over_pluto_static"))),
      width: 0.4,
      offset: -0.2,
      label: "Algebraic Tiling vs Pluto (static)",
    ),
    lq.bar(
      xs,
      aligned_tiling_data.map(row => float(row.at("speedup_over_pluto_dynamic"))),
      width: 0.4,
      offset: 0.2,
      label: "Algebraic Tiling  vs Pluto (dynamic)",
    ),
    lq.plot((-1, xs.len()), (1, 1), stroke: (paint: red, thickness: 1pt)),
    ..xs
    .zip(aligned_tiling_data.map(row => float(row.at("speedup_over_pluto_static"))))
    .map(((x, y)) => {
      let align = if y > 0.5 { top } else { bottom }
      lq.place(x - 0.2, y, pad(0.2em, text(size: 8pt, [#calc.round(y, digits: 3)])), align: align)
    }),
    ..xs
    .zip(aligned_tiling_data.map(row => float(row.at("speedup_over_pluto_dynamic"))))
    .map(((x, y)) => {
      let align = if y > 0.5 { top } else { bottom }
      lq.place(x + 0.2, y, pad(0.2em, text(size: 8pt, [#calc.round(y, digits: 3)])), align: align)
    }),
  )
}