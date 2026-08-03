#import "../../plot.typ" as zplot: cetz
#import "trahrhe.typ": *

#cetz.canvas(
  length: 0.09cm,
  {
    import cetz.draw: *

    let cgray = gray.transparentize(80%)
    // let cgray = gray


    let N = 50
    let DI = 4

    let axis-label-offset = -0.5cm
    zplot.axis(Xmax: N + 0.1 * N, Ymax: N + 0.1 * N, axis-label-offset: axis-label-offset)
    // Draw point lattice
    zplot.triang-domain(N, fill: cgray)
    // zplot.triang-domain-pt(N,)

    let vol = i_Ehrhart(N)
    let target-vol = calc.div-euclid(vol, DI)

    for ti in range(0, DI) {
      let lbi = i_trahrhe(N, target-vol * ti)
      let ubi = i_trahrhe(N, target-vol * (ti + 1)) - 1
      if ti == DI - 1 {
        ubi = N
      }

      if ti < DI - 1 {
        line((ubi, 0), (ubi, ubi), stroke: red)
      }

      if ti == 2 {
        content((lbi, axis-label-offset), $"lb"_i$)
        content((ubi, axis-label-offset), $"ub"_i$)

        let spacing = 2
        for j in range(1, ubi - spacing, step: spacing) {
          line((calc.max(lbi - 1, j), j), (ubi, j), stroke: black + 0.5pt, mark: (end: ">", fill: black, scale: 0.6))
          if j > spacing {
            line((calc.max(lbi - 1, j), j), (ubi, j - spacing), stroke: (paint: gray, dash: "dotted"))
          }
        }
        let ubj = calc.round(N / (2 * spacing)) * spacing - 1
        line((-0.1cm, ubj), (ubi, ubj), stroke: (paint: olive, dash: "dotted"))
        line((-0.1cm, ubj - 4 * spacing), (ubi, ubj - 4 * spacing), stroke: (paint: olive, dash: "dotted"))
        content((axis-label-offset, ubj), $"ub"_j$)
        content((axis-label-offset, ubj - 4 * spacing), $"lb"_j$)
      }
    }
  },
)
