#import "@preview/lilaq:0.5.0" as lq
#import "../../plot.typ" as zplot: cetz

#let tpz_speedup_data = csv("../../../data/tpz_32t_xl_speedups.csv", row-type: dictionary)

#let xlabels = tpz_speedup_data.map(row => row.at("benchmark"))
#let xticks = xlabels.map(rotate.with(-45deg, reflow: true)).enumerate()
#let xs = range(0, xticks.len())

#let labels = ("Algebraic Tiling vs Pluto (static)", "Algebraic Tiling vs Pluto (dynamic)",)

#{
  show: zplot.opaque-theme
  lq.diagram(
    cycle: lq.color.map.okabe-ito,
    width: 100%,
    height: 4cm,
    legend: (position: left + top),
    xaxis: (ticks: xticks, subticks: none),
    xlim: (-0.5, xs.len() - 0.5),
    yaxis: (lim: (0, 3.0)),
    ylabel: "Speedup",
    ..for (i, col) in ("speedup_pluto_static", "speedup_pluto_dynamic").enumerate() {
      (
        lq.bar(xs, tpz_speedup_data.map(row => float(row.at(col))), width: 0.4, offset: -0.2 + 0.4 * i, label: labels.at(i)),
        ..xs
        .zip(tpz_speedup_data.map(row => float(row.at(col))))
        .map(((x, y)) => {
          let align = if y > 0.5 { top } else { bottom }
          lq.place(x - 0.2 + 0.4 * i, y, pad(0.2em, text(size: 8pt, [#calc.round(y, digits: 3)])), align: align)
        }),
      )
    },
    lq.plot((-1, xs.len()), (1, 1), stroke: (paint: red, thickness: 1pt)),
  )
}