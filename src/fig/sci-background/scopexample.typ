#import "../../plot.typ" as zplot: cetz

#cetz.canvas(length: 0.5cm, {
  import cetz.draw: *
  let N = 5
  let M = 6
  let axis-offset = -1
  let label-size = 12pt
  let label-offset = -0.2cm

  let fontSize = 8pt

  zplot.axis(
    Xmax: M + 4,
    Ymax: N + 4,
    axis-offset: axis-offset,
    origin-label: none,
    label-size: label-size,
    axis-label-offset: label-offset,
  )

  let xtick(pos, label) = {
    line(
      (pos, axis-offset),
      (rel: (0, -0.1cm)),
    )
    content(
      (rel: (0, label-offset), to: (pos, axis-offset)),
      anchor: "north",
      text(size: label-size, label),
    )
  }
  let ytick(pos, label) = {
    line(
      (axis-offset, pos),
      (rel: (-0.1cm, 0)),
    )
    content(
      (rel: (label-offset, 0), to: (axis-offset, pos)),
      anchor: "east",
      text(size: label-size, label),
    )
  }

  let cstStyle = (stroke: (paint: black, thickness: 1pt, dash: "dotted"))
  line(
    (-1, 0),
    (N + 1, 0),
    name: "j-lower-bound",
    ..cstStyle,
  )
  content(
    (rel: (-label-offset, 0), to: "j-lower-bound.end"),
    anchor: "west",
    text(size: fontSize, $j >= 0$),
  )
  line(
    (-1, M - 1),
    (N + 1, M - 1),
    name: "j-upper-bound",
    ..cstStyle,
  )
  content(
    (rel: (-label-offset, 0), to: "j-upper-bound.end"),
    anchor: "west",
    text(size: fontSize, $j < M$),
  )
  line(
    (0, -1),
    (0, M + 1),
    name: "i-lower-bound",
    ..cstStyle,
  )
  content(
    (rel: (0, -label-offset), to: "i-lower-bound.end"),
    anchor: "south",
    text(size: fontSize, $i >= 0$),
  )
  line(
    (N - 1, -1),
    (N - 1, M + 1),
    name: "i-upper-bound",
    ..cstStyle,
  )
  content(
    (rel: (0, -label-offset), to: "i-upper-bound.end"),
    anchor: "south",
    text(size: fontSize, $i < N$),
  )

  xtick(0, $0$)
  xtick(N - 1, $N-1$)
  ytick(0, $0$)
  ytick(M - 1, $M-1$)


  for i in range(0, N) {
    for j in range(0, M) {
      circle((i, j), radius: 0.1cm, fill: blue, stroke: none)
    }
  }
})
