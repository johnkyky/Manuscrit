#import "@preview/codly:1.3.0": *

#show figure.where(kind: raw): it => {
  set block(breakable: true)
  it
}

= Trahrhe software

== Trahrhe output example without dichotomy and without tiling <app:trahrhe:example:nodicho:notile>

#let trahrhe-example-nodicho-notile = read("log/trahrhe.nodicho.notile.log")
#local(raw(trahrhe-example-nodicho-notile, lang: "C", block: true))

== Trahrhe output example without dichotomy and with tiling <app:trahrhe:example:nodicho:tile>

#let trahrhe-example-nodicho-tile = read("log/trahrhe.nodicho.tile.log")
#local(raw(trahrhe-example-nodicho-tile, lang: "C", block: true))

== Trahrhe example header file <app:trahrhe:example:header>

#let trahrhe-example-header = read("code/example.trahrhe.h")
#local(raw(trahrhe-example-header, lang: "C", block: true))

== Trahrhe output on syr2k domain <app:trahrhe:syr2kt2>

#let trahrh-syr2k-t2 = read("log/trahrhe.log")
#local(raw(trahrh-syr2k-t2, lang: "C", block: true))


