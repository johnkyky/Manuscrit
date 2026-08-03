#import "../../plot.typ" as zplot: cetz
#import "tpz.typ": *

#cetz.canvas(length: 1.5cm, {
  import cetz.draw: *


  line((0, -0.8), (0, 1.2), stroke: (dash: "dashed", paint: olive))
  line((1, -0.8), (1, 1.2), stroke: (dash: "dashed", paint: olive))

  line((0, 0), (1, 1), stroke: (paint: red), mark: (end: ">", fill: red))
  line((0, 0), (1, 0), stroke: (paint: red), mark: (end: ">", fill: red))

  line(
    (0, 0),
    (1, 0.6),
    stroke: (dash: "dashed", paint: black),
    mark: (end: ">", fill: black, stroke: (dash: "solid")),
  )
  line(
    (0, 0),
    (1.4, 0.4),
    stroke: (dash: "dashed", paint: black),
    mark: (end: ">", fill: black, stroke: (dash: "solid")),
  )


  // Draw point lattice
})
