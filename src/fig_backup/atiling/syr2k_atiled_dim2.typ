#import "../../plot.typ" as zplot: cetz
#import "trahrhe.typ": *

#cetz.canvas(length: 0.1cm, {
  import cetz.draw: *


  let N = 50
  let DI = 4
  let DJ = 4

  zplot.axis(Xmax: N + 0.1 * N, Ymax: N + 0.1 * N, axis-label-offset: -0.3cm)
  // Draw point lattice
  zplot.triang-domain(N, fill: none)
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
      line(
        (ubi, 0),
        (ubi, ubi),
        stroke: red,
      )
    }

    let j_vol = j_Ehrhart(N, lbi, ubi)
    let j_target_vol = calc.div-euclid(j_vol, DJ)

    for tj in range(0, DJ) {
      let lbj = j_trahrhe(N, lbi, ubi, j_target_vol * tj)
      let ubj = j_trahrhe(N, lbi, ubi, j_target_vol * (tj + 1)) - 1

      if tj < DJ - 1 {
        line(
          (calc.max(lbi - 1, ubj), ubj),
          (ubi, ubj),
          stroke: green,
        )
      }

      let label_x = if ti == 0 {
        (ubi + lbi) * 0.8
      } else {
        (ubi + lbi) / 2
      }
      let label_y = if tj == DJ - 1 {
        (ubj + lbj) * 0.45
      } else {
        (ubj + lbj) / 2
      }
      content(
        (label_x, label_y),
        $v_(#ti,#tj)$,
      )
    }
  }
})
