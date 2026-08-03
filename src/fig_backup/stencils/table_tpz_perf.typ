
#let tpz_data = csv("../../../data/tpz_32t_xl_speedups.csv", row-type: dictionary)

#table(
  columns: 8,
  align: center,
  table.header(
    table.cell(rowspan: 2, align(horizon, "Benchmark")),
    table.cell(rowspan: 2, align(horizon, "Problem Size")),
    table.cell(colspan: 2, "Pluto (static)"),
    table.cell(colspan: 2, "Pluto (dynamic)"),
    table.cell(colspan: 2, "Pesto"),
    table.cell("Tile Sizes"),
    table.cell("Time (s)"),
    table.cell("Tile Sizes"),
    table.cell("Time (s)"),
    table.cell("Dividers"),
    table.cell("Time (s)"),
  ),
  ..for row in tpz_data {
    (
      table.cell([
        #row.at("benchmark")
      ]),
      table.cell(row.at("problem_size")),
      table.cell(row.at("pluto_static_param")),
      table.cell(row.at("pluto_static")),
      table.cell(row.at("pluto_dynamic_param")),
      table.cell(row.at("pluto_dynamic")),
      table.cell(row.at("pesto_param")),
      table.cell(row.at("pesto")),
    )
  },
)
