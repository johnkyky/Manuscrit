#show table.cell.where(y: 0).or(table.cell.where(y: 1)): strong
#let xl_dataset = csv("../../../data/32t_xl_dataset_perf.csv", row-type: dictionary)

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
  ..for row in xl_dataset {
    (
      table.cell([
        #row.at("benchmark")#if "best_pesto" in row and row.at("best_pesto") == "hybrid" {
          "*"
        }
      ]),
      table.cell(row.at("problem_size")),
      table.cell(row.at("tile_sizes_pluto_static")),
      table.cell(row.at("time_pluto_static")),
      table.cell(row.at("tile_sizes_pluto_dynamic")),
      table.cell(row.at("time_pluto_dynamic")),
      if "best_pesto" in row and row.at("best_pesto") == "hybrid" {
        table.cell(row.at("tile_sizes_pesto_hybrid"))
      } else {
        table.cell(row.at("tile_sizes_pesto"))
      },
      table.cell(row.at("time_pesto")),
    )
  },
)
