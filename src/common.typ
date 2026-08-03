#import "@preview/glossarium:0.5.9" as glossarium: make-glossary, print-glossary, register-glossary
#import "@preview/codly:1.3.0": codly, codly-init, local
#import "@preview/codly-languages:0.1.1"
#import "@preview/cetz:0.4.2"
#import "@preview/cetz-plot:0.1.3"
#import "@preview/subpar:0.2.2"
#import "@preview/lovelace:0.3.0": *
#import "@preview/drafting:0.2.2": *
#import "@preview/pinit:0.2.2": *
#import "@preview/drafting:0.2.2": *
#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#import "@preview/lilaq:0.5.0" as lq

#import "theorion-theme.typ": *
#import "plot.typ" as zplot
#import "figures.typ" as fig

#import "../covers/front.typ": front-cover
#import "../covers/back.typ": back-cover


#let polyrelcst = math.class(
  "relation",
  sym.gt.eq,
)

#let lexordersym = math.class(
  "relation",
  sym.prec.eq,
)

#let mtext = math.italic

#let chref(label) = ref(label, supplement: "Chapter")

#let appref(label) = ref(label, supplement: "Appendix")

#let edit(body) = {
  text(fill: blue, body)
  // body
}

#let todo(bodysize) = {
  text(fill: red)[#lorem(bodysize)]
}

#let software(body) = smallcaps(body)

#let gls(..args) = glossarium.gls(link: false, ..args)
#let glspl(..args) = glossarium.glspl(link: false, ..args)

