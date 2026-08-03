#import "../../plot.typ" as zplot: cetz

#cetz.canvas(length: 0.6cm, {
  import cetz.draw: *


  let T = 5
  let N = 5
  zplot.axis-unbound(Xmax: T, Ymax: N, xParamName: $T - 1$, yParamName: $N -2$, xAxisName: $t$, yAxisName: $i$)

  let x = 3
  let y = 2
  for t in range(0, T + 1) {
    for i in range(0, N + 1) {
      circle((t, i), radius: 0.15, fill: blue, name: "p-" + str(t) + "-" + str(i), stroke: none)
    }
  }
  let linestyle = (mark: (end: ">", fill: black, scale: 0.6), stroke: black + 1pt)
  for t in range(0, T + 1) {
    for i in range(0, N + 1) {
      let current = "p-" + str(t) + "-" + str(i)
      if t < T {
        line(current, "p-" + str(t + 1) + "-" + str(i), ..linestyle)
      }
      if i < N {
        line(current, "p-" + str(t) + "-" + str(i + 1), ..linestyle)
      }
      if i > 0 and t < T {
        line(current, "p-" + str(t + 1) + "-" + str(i - 1), ..linestyle)
      }
      if i < N and t < T {
        line(current, "p-" + str(t + 1) + "-" + str(i + 1), ..linestyle)
      }
    }
  }
})
