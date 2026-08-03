#import "@preview/lilaq:0.5.0" as lq
#import "../../plot.typ" as zplot: cetz
#import "trahrhe_perf.typ": label_names, marks

#let perf_domain_1 = csv("../../../data/trahrhe_perf_domain_1.csv", row-type: dictionary)


#let plot = {
  show: zplot.opaque-theme

lq.diagram(
      width: 10cm,
      legend: (position: top + right, fill: white),
      xlabel: $N$,
      ylabel: [Execution Time ($s$)],
      yscale: "linear",
      xscale: "linear",
      xaxis: (auto-exponent-threshold: 100),
      ..for (i, trahrhe_type) in ("exact", "gist_exact", "dicho", "gist_dicho").enumerate() {
        (lq.plot(
          perf_domain_1.filter(row => row.at(trahrhe_type) != "").map(row => int(row.at("N"))),
          perf_domain_1.filter(row => row.at(trahrhe_type) != "").map(row => float(row.at(trahrhe_type))),
          label: label_names.at(trahrhe_type),
          mark: marks.at(i),
        ),)
      },
    )
}

#plot
