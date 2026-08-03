#let msii-header(
  logo-left: none,
  title: none,
  logo-right: none,
) = grid(
  columns: (1fr, 2fr, 1fr),
  column-gutter: 1em,
  rows: 1,
  grid.cell(colspan: 1, align: center, logo-left),
  grid.cell(colspan: 1, align: center + horizon, title),
  grid.cell(colspan: 1, align: center, logo-right),
)

