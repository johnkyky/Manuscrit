#import "@preview/cetz:0.4.2"
#import "@preview/cetz-plot:0.1.3"
#import "@preview/lovelace:0.3.0": *
#import "@preview/lilaq:0.5.0" as lq

#let opaque-theme = it => {
  show: lq.set-diagram(
    fill: white,
    xaxis: (subticks: none, mirror: false),
    yaxis: (subticks: none, mirror: false),
  )

  show: lq.set-grid(stroke: none)
  show: lq.set-tick(inset: 3pt)

  show: lq.set-legend(
    pad: .4em,
    radius: 1pt,
    fill: white,
  )

  it
}


#let axis(
  Xmax: 5,
  Ymax: 5,
  axis-offset: 0,
  axis-label-offset: -0.5cm,
  label-size: 16pt,
  xName: $i$,
  yName: $j$,
  origin-label: $0$,
) = {
  import cetz.draw: content, line
  line(
    (axis-offset, axis-offset),
    (Xmax, axis-offset),
    mark: (end: ">", fill: black),
    name: "x-axis",
  )
  line(
    (axis-offset, axis-offset),
    (axis-offset, Ymax),
    mark: (end: ">", fill: black),
    name: "y-axis",
  )

  content((rel: (axis-label-offset, 0), to: "y-axis.end"), anchor: "east", text(size: label-size, yName))
  content((rel: (0, axis-label-offset), to: "x-axis.end"), anchor: "north", text(size: label-size, xName))
  if origin-label != none {
    content((rel: (0, axis-label-offset), to: "x-axis.start"), text(size: label-size, origin-label))
  }
}

#let axis-unbound(
  Xmax: 5,
  Ymax: 5,
  xParamName: "N",
  yParamName: "M",
  axis-offset: -1,
  axis-label-offset: -0.2cm,
  label-size: 16pt,
  tick-size: 0.1cm,
  xAxisName: none,
  yAxisName: none,
) = {
  import cetz.draw: content, line

  line(
    (0, axis-offset),
    (Xmax, axis-offset),
    name: "x-axis",
  )

  line(
    (axis-offset, 0),
    (axis-offset, Ymax),
    name: "y-axis",
  )
  if tick-size != 0 {
    line(
      (rel: (0, 0.5pt), to: "x-axis.start"),
      (rel: (0, -tick-size)),
      stroke: black + 1pt,
    )
    line(
      (rel: (0, 0.5pt), to: "x-axis.end"),
      (rel: (0, -tick-size)),
      stroke: black + 1pt,
    )
    line(
      (rel: (0.5pt, 0), to: "y-axis.start"),
      (rel: (-tick-size, 0)),
      stroke: black + 1pt,
    )
    line(
      (rel: (0.5pt, 0), to: "y-axis.end"),
      (rel: (-tick-size, 0)),
      stroke: black + 1pt,
    )
  }

  content((rel: (0, axis-label-offset), to: "x-axis.start"), anchor: "north", text(size: label-size, $0$))
  content((rel: (0, axis-label-offset), to: "x-axis.end"), anchor: "north", text(size: label-size, xParamName))
  if xAxisName != none {
    content((rel: (0, axis-label-offset), to: "x-axis.mid"), anchor: "north", text(size: label-size, $xAxisName$))
  }

  content((rel: (axis-label-offset, 0), to: "y-axis.start"), anchor: "east", text(size: label-size, $0$))
  content((rel: (axis-label-offset, 0), to: "y-axis.end"), anchor: "east", text(size: label-size, yParamName))
  if yAxisName != none {
    content((rel: (axis-label-offset, 0), to: "y-axis.mid"), anchor: "east", text(size: label-size, $yAxisName$))
  }
}


#let triang-domain(N, ..args) = {
  import cetz.draw: content, line

  line(
    (0, 0),
    (N, 0),
    (N, N),
    close: true,
    ..args,
  )
}

#let triang-domain-pt(N, ..args) = {
  import cetz.draw: circle

  //  radius: 0.3, fill: blue, stroke: none

  for x in range(0, N + 1) {
    for y in range(0, x + 1) {
      let name = "p-" + str(x) + "-" + str(y)
      circle((x, y), name: name, radius: 0.3, fill: blue, ..args)
    }
  }
}
