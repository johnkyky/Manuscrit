#import "../../plot.typ" as zplot: cetz

#cetz.canvas(length: 0.5cm, {
  import cetz.draw: *
  let N = 6
  let label-size = 12pt
  let label-offset = -0.2cm

  let fontSize = 8pt

  zplot.axis(
    Xmax: N + 4,
    Ymax: N + 4,
    origin-label: none,
    label-size: label-size,
    axis-label-offset: label-offset,
  )

  let xtick(pos, label) = {
    line(
      (pos, 0),
      (rel: (0, -0.1cm)),
    )
    content(
      (pos, label-offset),
      anchor: "north",
      text(size: label-size, label),
    )
  }
  let ytick(pos, label) = {
    line(
      (0, pos),
      (rel: (-0.1cm, 0)),
    )
    content(
      (label-offset, pos),
      anchor: "east",
      text(size: label-size, label),
    )
  }

  let cstStyle = (stroke: (paint: black, thickness: 1pt, dash: "dotted"))
  line(
    (0, N + 2),
    (N + 2, 0),
    name: "if-cst",
    ..cstStyle,
  )
  content(
    (rel: (1.3, -0.9), to: "if-cst.start"),
    anchor: "west",
    text(size: fontSize, $i <= N + 2 - j$),
  )
  line(
    (0, 1),
    (N + 3, 1),
    name: "j-lower-bound",
    ..cstStyle,
  )
  content(
    (rel: (-label-offset, 0), to: "j-lower-bound.end"),
    anchor: "west",
    text(size: fontSize, $j >= 1$),
  )
  line(
    (0, N),
    (N + 3, N),
    name: "j-upper-bound",
    ..cstStyle,
  )
  content(
    (rel: (-label-offset, 0), to: "j-upper-bound.end"),
    anchor: "west",
    text(size: fontSize, $j <= N$),
  )
  line(
    (1, 0),
    (1, N + 2),
    name: "i-lower-bound",
    ..cstStyle,
  )
  content(
    (rel: (0, -label-offset), to: "i-lower-bound.end"),
    anchor: "south",
    text(size: fontSize, $i >= 1$),
  )
  line(
    (N, 0),
    (N, N + 2),
    name: "i-upper-bound",
    ..cstStyle,
  )
  content(
    (rel: (0, -label-offset), to: "i-upper-bound.end"),
    anchor: "south",
    text(size: fontSize, $i <= N$),
  )

  xtick(1, $1$)
  xtick(N, $N$)
  xtick(N + 2, $N+2$)
  ytick(1, $1$)
  ytick(N, $N$)
  ytick(N + 2, $N+2$)


  for i in range(1, N + 1) {
    for j in range(1, N + 1) {
      if i <= N + 2 - j {
        circle((i, j), radius: 0.1cm, fill: blue, stroke: none)
      }
    }
  }
})
