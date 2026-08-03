#import "../../plot.typ" as zplot: cetz
#import "tpz.typ": *

#cetz.canvas(length: canvas-len, {
  import cetz.draw: *


  let bandWidth = 4
  zplot.axis(
    Xmax: N + 0.1 * N,
    Ymax: N + 0.1 * N,
    xName: $x$,
    yName: $y$,
    axis-label-offset: -0.3cm,
    origin-label: none,
  )

  for i in range(bandWidth * 3, N - 2 * bandWidth, step: bandWidth) {
    line((i, 0), (i, N), stroke: (dash: "dashed", paint: olive))
  }

  plot-domain-bounds()
  // Draw point lattice
})
