
#let likwid_dataset = csv("../../../data/likwid_rect_32t_xl.csv", row-type: dictionary)
#table(
  columns: (1.9cm,) + (1fr,) * 3 * 5,
  align: center,
  table.header(
    table.cell(rowspan: 2, align(horizon, "Benchmark")),
    table.cell(colspan: 5, "Pluto (static)"),
    table.cell(colspan: 5, "Pluto (dynamic)"),
    table.cell(colspan: 5, "Pesto"),
    table.cell("Mean Time (s)"),
    table.cell("Min Time (s)"),
    table.cell("Max Time (s)"),
    table.cell("Std Dev (%)"),
    table.cell("Gini Coeff"),
    table.cell("Mean Time (s)"),
    table.cell("Min Time (s)"),
    table.cell("Max Time (s)"),
    table.cell("Std Dev (%)"),
    table.cell("Gini Coeff"),
    table.cell("Mean Time (s)"),
    table.cell("Min Time (s)"),
    table.cell("Max Time (s)"),
    table.cell("Std Dev (%)"),
    table.cell("Gini Coeff"),
  ),
  ..for row in likwid_dataset {
    (
      table.cell(row.at("benchmark")),
      ..for exec_type in ("pluto:static", "pluto:dynamic", "pesto") {
        (
          // table.cell([
          //   #let mean = calc.round(
          //     float(row.at("mean_rdtsc_" + exec_type)),
          //     digits: 4,
          //   )
          //   #let min = calc.round(
          //     mean - float(row.at("min_rdtsc_" + exec_type)),
          //     digits: 4,
          //   )
          //   #let max = calc.round(
          //     float(row.at("max_rdtsc_" + exec_type)) - mean,
          //     digits: 4,
          //   )
          //   #num(str(mean) + "+" + str(max) + "-" + str(mean))
          // ]),
          table.cell([
            #calc.round(
              float(row.at("mean_rdtsc_" + exec_type)),
              digits: 4,
            )
          ]),
          table.cell([
            #calc.round(
              float(row.at("min_rdtsc_" + exec_type)),
              digits: 4,
            )
          ]),
          table.cell([
            #calc.round(
              float(row.at("max_rdtsc_" + exec_type)),
              digits: 4,
            )
          ]),
          // table.cell([
          //   #calc.round(
          //     float(row.at("std_rdtsc_" + exec_type)),
          //     digits: 4,
          //   )
          // ]),
          table.cell([
            #calc.round(
              float(row.at("pstd_rdtsc_" + exec_type)),
              digits: 1,
            )
            %
          ]),
          table.cell([
            #calc.round(
              float(row.at("gini_rdtsc_" + exec_type)),
              digits: 4,
            )
          ]),
        )
      },
    )
  },
)
