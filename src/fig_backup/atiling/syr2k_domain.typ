#import "../../plot.typ" as zplot: cetz

#cetz.canvas(length: 0.4cm, {
  import cetz.draw: *


  let N = 15
  zplot.axis-unbound(Xmax: N, Ymax: N, xParamName: $N$, yParamName: $N$, xAxisName: $i$, yAxisName: $j$)


  zplot.triang-domain(N - 1)
  // Draw point lattice
  zplot.triang-domain-pt(N - 1, stroke: none, radius: 0.1cm)
  let dep-style = (mark: (end: ">", fill: red, length: 0.08cm, width: 0.08cm), stroke: red + 1pt)

  // for x in range(0, N) {
  //   for y in range(0, x) {
  //     line("p-" + str(x) + "-" + str(y), "p-" + str(x) + "-" + str(y + 1), ..dep-style)
  //   }
  // }
})
