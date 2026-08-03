#import "../../plot.typ" as zplot: cetz

#cetz.canvas(length: 0.4cm, {
  import cetz.draw: *


  let min = 3
  let start = min + 2
  let end = start + 3
  let max = end + 2

  let dot-radius = 0.1cm

  let xi = calc.floor((start + end) / 2)

  line(
    (min, min),
    (start, start),
    stroke: (dash: "dashed"),
  )
  line(
    (min, 0),
    (start, 0),
    stroke: (dash: "dashed"),
  )
  line(
    (end, end),
    (max, max),
    stroke: (dash: "dashed"),
  )
  line(
    (end, 0),
    (max, 0),
    stroke: (dash: "dashed"),
  )

  line(
    (start, start),
    (end, end),
  )
  line(
    (start, 0),
    (end, 0),
  )
  line(
    (xi, -1),
    (xi, end),
  )
  line(
    (xi + 1, -1),
    (xi + 1, end),
  )

  for i in range(0, xi + 2) {
    if i < xi + 1 {
      circle(
        (xi, i),
        fill: blue,
        radius: dot-radius,
      )
    }
    circle(
      (xi + 1, i),
      fill: blue,
      radius: dot-radius,
    )
  }
  line(
    (start, xi + 1),
    (xi, xi + 1),
    stroke: red,
    mark: (end: ">", fill: red),
  )
  // dashed / solid line
  line(
    (start, xi + 1),
    (min, xi + 1),
    stroke: (paint: red, dash: "dotted"),
    mark: (end: ">", fill: red, stroke: (paint: red, dash: "solid")),
  )
  content(
    (min + 1, xi),
    "N points",
  )

  line(
    (start, xi + 2),
    (xi + 1, xi + 2),
    stroke: red,
    mark: (end: ">", fill: red),
  )
  line(
    (start, xi + 2),
    (min, xi + 2),
    stroke: (paint: red, dash: "dotted"),
    mark: (end: ">", fill: red, stroke: (paint: red, dash: "solid")),
  )
  content(
    (min + 1, xi + 3),
    "N + i points",
  )
})
