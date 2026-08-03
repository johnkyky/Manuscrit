#import "@preview/lilaq:0.5.0" as lq
#import "../../plot.typ" as zplot: cetz

#let plot = {
  show: zplot.opaque-theme
  
  let xl_dataset = csv("../../../data/32t_xl_dataset_flops.csv", row-type: dictionary)
  

    let names = (
    "Pluto (static)",
    "Pluto (dynamic)",
    "Pesto (algebraic)",
    "Pesto (hybrid)",
  )

  let xlabels = xl_dataset.map(row => row.at("benchmark")).dedup()
  let xticks = xlabels.map(rotate.with(-45deg, reflow: true)).enumerate()  
  let xs = range(0, xticks.len())

  let datasets = (
    xl_dataset.map(row => float(row.at("pluto_static_score"))),
    xl_dataset.map(row => float(row.at("pluto_dynamic_score"))),
    xl_dataset.map(row => float(row.at("pesto_default_score"))),
    xl_dataset.map(row => float(row.at("pesto_hybrid_score"))),
  )



    lq.diagram(
    cycle: lq.color.map.okabe-ito,
    width: 100%,
    height: 6cm,
    legend: (position: top + right),
    xaxis: (
      ticks: xticks,
      subticks: none,
    ),
    ylabel: "MFlop/s)",

    ..for (i, data) in datasets.enumerate() {
      (
        lq.bar(
          xs,
          data,
          width: 0.2,
          offset: 0.2 * i - 0.3,
          label: names.at(i),
        ),
      )
    },

    // ..for (i, data) in datasets.enumerate() {
    //   (
    //     ..xs
    //       .zip(data)
    //       .map(((x, y)) => {
    //         let align = if y > 0.5 { top } else { bottom }
    //         lq.place(x + (0.2 * i - 0.3), y, pad(0.2em, text(size: 8pt, [#calc.round(y, digits: 4)])), align: align)
    //       }),
    //   )
    // },
  )
}
#plot
