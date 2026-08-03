#import "@preview/lilaq:0.5.0" as lq
#import "../../plot.typ" as zplot: cetz

#let plot = {
  show: zplot.opaque-theme
  
  let tpz_data = csv("../../../data/tpz_32t_xl.csv", row-type: dictionary)

  let xlabels = tpz_data.map(row => row.at("benchmark_name")).dedup()
  let xticks = xlabels.map(rotate.with(-45deg, reflow: true)).enumerate()
  let xs = range(0, xticks.len())
  let datasets = (
    tpz_data.filter(row => row.at("tags") == "pluto:static").map(row => float(row.at("best_score"))),
    tpz_data.filter(row => row.at("tags") == "pluto:dynamic").map(row => float(row.at("best_score"))),
    tpz_data.filter(row => row.at("tags") == "tpz:pesto").map(row => float(row.at("best_score"))),
  )

  let names = (
    "Pluto (static)",
    "Pluto (dynamic)",
    "Pesto (trapezoidal)",
  )

  lq.diagram(
    cycle: lq.color.map.okabe-ito,
    width: 100%,
    height: 6cm,
    legend: (position: top + center),
    xaxis: (
      ticks: xticks,
      subticks: none,
    ),
    ylabel: "Execution time (s)",

    ..for (i, data) in datasets.enumerate() {
      (
        lq.bar(
          xs,
          data,
          width: 0.3,
          offset: 0.3 * i - 0.3,
          label: names.at(i),
        ),
      )
    },

    ..for (i, data) in datasets.enumerate() {
      (
        ..xs
          .zip(data)
          .map(((x, y)) => {
            let align = if y > 0.5 { top } else { bottom }
            lq.place(x + (0.3 * i - 0.3), y, pad(0.2em, text(size: 8pt, [#calc.round(y, digits: 4)])), align: align)
          }),
      )
    },
  )
}

#plot
