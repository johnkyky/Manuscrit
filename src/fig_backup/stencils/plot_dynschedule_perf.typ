#import "@preview/lilaq:0.5.0" as lq
#import "../../plot.typ" as zplot: cetz

#let dyn_schedule_data = csv("../../../data/dynamic_schedule.csv", row-type: dictionary)

#let plot = {
  show: zplot.opaque-theme

  let xlabels = dyn_schedule_data.map(row => row.at("benchmark"))
  let xticks = xlabels.map(rotate.with(-45deg, reflow: true)).enumerate()
  let xs = range(0, xticks.len())
  let colormap = (
    lq.color.map.okabe-ito.at(0),
    lq.color.map.okabe-ito.at(1),
    lq.color.map.okabe-ito.at(2).darken(20%),
    lq.color.map.okabe-ito.at(2).lighten(50%),
  )

  let datasets = (
    dyn_schedule_data.map(row => float(row.at("pluto_static"))),
    dyn_schedule_data.map(row => float(row.at("pluto_dynamic"))),
    dyn_schedule_data.map(row => float(row.at("aligned_alg"))),
    dyn_schedule_data.map(row => float(row.at("dyn_schedule_kernel")) + float(row.at("schedule_compute"))),
  )

  let names = (
    "Pluto (static)",
    "Pluto (dynamic)",
    "Aligned algebraic",
    "Dynamic schedule (kernel)",
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
    yaxis: (
      lim: (0, 8.0),
    ),
    ylabel: "Execution time (s)",

    ..for (i, data) in datasets.enumerate() {
      (
        lq.bar(
          xs,
          data,
          width: 0.2,
          offset: 0.2 * i - 0.3,
          fill: colormap.at(i),
          label: names.at(i),
        ),
      )
    },
    lq.bar(
      xs,
      dyn_schedule_data.map(row => float(row.at("dyn_schedule_kernel")) + float(row.at("schedule_compute"))),
      base: dyn_schedule_data.map(row => float(row.at("dyn_schedule_kernel"))),
      width: 0.2,
      offset: 0.3,
      label: "Dynamic schedule (schedule)",
      fill: lq.color.map.okabe-ito.at(3),
    ),

    ..for (i, data) in datasets.enumerate() {
      (
        ..xs
          .zip(data)
          .map(((x, y)) => {
            let align = if y > 0.5 { top } else { bottom }
            lq.place(x + (0.2 * i - 0.3), y, pad(0.2em, text(size: 8pt, [#calc.round(y, digits: 3)])), align: align)
          }),
      )
    },
  )
}

#plot
