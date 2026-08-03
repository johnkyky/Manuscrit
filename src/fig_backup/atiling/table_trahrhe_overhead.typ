#let table = {
  let data = csv("../../../data/trahrhe_exec_times_32t_xl.csv", row-type: dictionary)
  data = data.map(row => {
    row.insert("overhead_pesto", (float(row.at("trahrhe_time")) / float(row.at("time_pesto"))) * 100)
    row
  })
  data = data.map(row => {
    row.insert("overhead_hybrid", (float(row.at("trahrhe_time_hybrid")) / float(row.at("time_pesto"))) * 100)
    row
  })
  table(
    columns: (1fr,) * 7,
    table.header(
      table.cell(rowspan: 2, align(horizon, "Benchmark")),
      table.cell(colspan: 3, "Fully Algebraic Tiling"),
      table.cell(colspan: 3, "Hybrid Algebraic Tiling"),
      table.cell(align: horizon, "Execution Time (s)"),
      table.cell(align: horizon, [Bound\ Computation\ Time (s)]),
      table.cell(align: horizon, "Overhead (%)"),
      table.cell(align: horizon, "Execution Time (s)"),
      table.cell(align: horizon, [Bound\ Computation\ Time (s)]),
      table.cell(align: horizon, "Overhead (%)"),
    ),
    ..for row in data {
      (
        table.cell(row.at("benchmark")),
        table.cell(str(row.at("time_pesto"))),
        table.cell(str(row.at("trahrhe_time"))),
        table.cell(str(calc.round(row.at("overhead_pesto"), digits: 2)) + "%"),
        table.cell(str(row.at("time_hybrid"))),
        table.cell(str(row.at("trahrhe_time_hybrid"))),
        table.cell(str(calc.round(row.at("overhead_hybrid"), digits: 2)) + "%"),
      )
    },
  )
}

#table
