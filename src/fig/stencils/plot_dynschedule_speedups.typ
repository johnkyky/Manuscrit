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
    lq.color.map.okabe-ito.at(2),
  )

  let datasets = (
    dyn_schedule_data.map(row => float(row.at("dynschedule_speedup_over_pluto_static"))),
    dyn_schedule_data.map(row => float(row.at("dynschedule_speedup_over_pluto_dynamic"))),
    dyn_schedule_data.map(row => float(row.at("dynschedule_speedup_over_aligned"))),
  )

  let names = (
    "Speedup over Pluto (static)",
    "Speedup over Pluto (dynamic)",
    "Speedup over Aligned algebraic tiling",
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
    xlim: (-1, xs.len()),
    yaxis: (
      lim: (0, 3.0),
    ),
    ylabel: "Speedup",

    ..for (i, data) in datasets.enumerate() {
      (
        lq.bar(
          xs,
          data,
          width: 0.3,
          offset: 0.3 * i - 0.3,
          fill: colormap.at(i),
          label: names.at(i),
        ),
      )
    },
    lq.plot(
      (-1, xs.len()),
      (1, 1),
      stroke: (paint: red, thickness: 1pt),
    ),


    ..for (i, data) in datasets.enumerate() {
      (
        ..xs
          .zip(data)
          .map(((x, y)) => {
            let align = if y > 0.5 { top } else { bottom }
            lq.place(x + (0.3 * i - 0.3), y, pad(0.2em, text(size: 8pt, [#calc.round(y, digits: 2)])), align: align)
          }),
      )
    },
  )
}

#plot
