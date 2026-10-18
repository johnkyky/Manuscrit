// subpar infère "Fig." en français : on force "Figure" comme pour les autres
// figures, afin d'avoir un libellé homogène dans la table des figures.
#import "@preview/subpar:0.2.2" as subpar-pkg

#let super = subpar-pkg.super.with(supplement: [Figure])
#let grid = subpar-pkg.grid.with(supplement: [Figure])
