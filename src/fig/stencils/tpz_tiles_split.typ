#import "../../plot.typ" as zplot: cetz
#import "tpz.typ": *

#cetz.canvas(length: canvas-len, {
  import cetz.draw: *


  let bandWidth = 10
  zplot.axis(
    Xmax: N + 0.1 * N,
    Ymax: N + 0.1 * N,
    xName: $x$,
    yName: $y$,
    axis-label-offset: -0.3cm,
    origin-label: none,
  )

  for i in range(bandWidth, N, step: bandWidth) {
    line((i, 0), (i, N), stroke: (dash: "dashed", paint: olive))
  }

  plot-domain-bounds()

  let divY = 3

  for i in range(bandWidth, N, step: bandWidth) {
    let xOffset = i
    let yOffset = int(lowCst(xOffset))
    let maxY = int(upCst(xOffset + bandWidth))

    let sizeY = calc.div-euclid(maxY - yOffset, divY)

    for j in range(0, divY) {
      line(
        (xOffset, yOffset + j * sizeY),
        (xOffset + bandWidth, yOffset + j * sizeY),
        stroke: (paint: olive),
      )

      let correctionFactor = (
        (
          sizeY
            - (
              (yOffset + (j + 1) * sizeY) - (xOffset + (yOffset + (j + 1) * sizeY - xOffset - bandWidth))
            )
        )
          / 2
      )

      // correctionFactor = 0
      line(
        (xOffset + bandWidth, yOffset + (j + 1) * sizeY - correctionFactor),
        (xOffset, xOffset + (yOffset + (j + 1) * sizeY - xOffset - bandWidth) - correctionFactor),
        stroke: (paint: olive),
      )
    }
  }

  // Draw point lattice
})
