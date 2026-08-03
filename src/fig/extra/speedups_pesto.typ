#import "@preview/lilaq:0.5.0" as lq
#import "../../plot.typ" as zplot: cetz

#let plot = {
  show: zplot.opaque-theme

  let xl_dataset = csv("../../../data/32t_xl_dataset_perf.csv", row-type: dictionary)
  let xlabels = xl_dataset.map(row =>row.at("benchmark"))

  xlabels += ("Average",)

  let static_speedups = xl_dataset.map(row => float(row.at("time_pluto_static")) / float(row.at("time_pesto_classic")))
  let dynamic_speedups = xl_dataset.map(row => float(row.at("time_pluto_dynamic")) / float(row.at("time_pesto_classic")))

  let static_avg = 0
  for speedup in static_speedups {
    static_avg += speedup
  }
  static_avg = static_avg / static_speedups.len()

  let dynamic_avg = 0
  for speedup in dynamic_speedups {
    dynamic_avg += speedup
  }
  dynamic_avg = dynamic_avg / dynamic_speedups.len()

  static_speedups += (static_avg,)
  dynamic_speedups += (dynamic_avg,)

  let datasets = (static_speedups, dynamic_speedups,)

  let xticks = xlabels.map(rotate.with(-45deg, reflow: true)).enumerate()
  let xs = range(0, xticks.len())

  let barLabels = ("Pesto vs Pluto (static)", "Pesto vs Pluto (dynamic)")

  lq.diagram(
    width: 15cm,
    xlim: (-1, xticks.len()),
    ylim: (0, 2),
    xaxis: (ticks: xticks, subticks: none),
    ..for (i, data) in datasets.enumerate() {
      (lq.bar(xs, data, width: 0.4, offset: -0.2 + 0.4 * i, label: barLabels.at(i)), ..xs
      .zip(data)
      .map(((x, y)) => {
        let align = if y > 0.5 { top } else { bottom }
        lq.place(x - 0.2 + 0.4 * i, y, pad(0.2em, text(size: 8pt, [#calc.round(y, digits: 2)])), align: align)
      }),)
    },
    lq.plot((-1, xticks.len()), (1, 1), stroke: red + 1pt, clip: true),
  )
}
#plot
