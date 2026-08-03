#import "../../plot.typ" as zplot: cetz

#cetz.canvas(length: 0.6cm, {
  import cetz.draw: *


  let N = 5
  zplot.axis-unbound(Xmax: N, Ymax: N, xParamName: $N - 2$, yParamName: $N - 2$, xAxisName: $i$, yAxisName: $j$)

  let x = 3
  let y = 2
  for i in range(0, N + 1) {
    for j in range(0, N + 1) {
      circle((i, j), radius: 0.15, fill: blue, name: "p-" + str(i) + "-" + str(j), stroke: none)
    }
  }
  let target = "p-" + str(x) + "-" + str(y)
  let others = (
    (x - 1, y - 1),
    (x - 1, y),
    (x - 1, y + 1),
    (x, y - 1),
    (x, y + 1),
    (x + 1, y - 1),
    (x + 1, y),
    (x + 1, y + 1),
  )
  for other in others {
    line(
      "p-" + str(other.at(0)) + "-" + str(other.at(1)),
      target,
      mark: (end: ">", fill: black, scale: 0.6),
      stroke: black + 1pt,
    )
  }
})
