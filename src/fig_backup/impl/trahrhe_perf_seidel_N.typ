#import "@preview/lilaq:0.5.0" as lq
#import "../../plot.typ" as zplot: cetz
#import "trahrhe_perf.typ": label_names, marks

#let perf_domain_seidel = csv("../../../data/trahrhe_perf_domain_seidel.csv", row-type: dictionary)

#let plot = {
  show: zplot.opaque-theme

  lq.diagram(
    fill: white,
    xlabel: $N$,
    ylabel: [Execution Time ($s$)],
    yscale: "linear",
    xscale: "linear",
    xaxis: (auto-exponent-threshold: 100),
    legend: (position: top + left, fill: white),
    ..for (i, trahrhe_type) in ("exact", "gist_exact", "dicho", "gist_dicho").enumerate() {
      (lq.plot(perf_domain_seidel
      .filter(row => row.at(trahrhe_type) != "" and row.at("TSTEPS") == "100")
      .map(row => int(row.at("N"))), perf_domain_seidel
      .filter(row => row.at(trahrhe_type) != "" and row.at("TSTEPS") == "100")
      .map(row => float(row.at(trahrhe_type))), label: label_names.at(trahrhe_type), mark: marks.at(i)),)
    },
  )
}

#plot
