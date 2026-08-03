#import "../../plot.typ" as zplot: cetz
#import "trahrhe.typ": *

#cetz.canvas(length: 0.1cm, {
  import cetz.draw: *


  let N = 50
  let DX = 4

  zplot.axis(Xmax: N + 0.1 * N, Ymax: N + 0.1 * N, axis-label-offset: -0.3cm)
  // Draw point lattice
  zplot.triang-domain(N, fill: none)


  let vol = i_Ehrhart(N)
  let target-vol = calc.div-euclid(vol, DX)

  for tx in range(0, DX) {
    let lbi = i_trahrhe(N, target-vol * tx)
    let ubi = i_trahrhe(N, target-vol * (tx + 1)) - 1

    if tx < DX - 1 {
      line(
        (ubi, 0),
        (ubi, ubi),
        stroke: red,
      )
    }

    let label_x = if tx == 0 {
      (ubi + lbi) * 0.7
    } else {
      (ubi + lbi) / 2
    }
    content(
      (label_x, N / 5),
      $v_#tx$,
    )
  }
})
