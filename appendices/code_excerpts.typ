#import "@preview/codly:1.3.0": *

= Code Excerpts

#show raw: set text(size: 8pt)

== Pesto algebraic rectangular tiling

#let syr2k-original = read("code/syr2k.c")
#let syr2k-pesto = read("code/syr2k.pesto.c")
#let syr2k-trahrhe-header1 = read("./code/syr2k.pesto.trahrhe.n0.g0.h")
#let syr2k-trahrhe-header2 = read("code/syr2k.pesto.trahrhe.n0.g1.h")

=== syr2k original program <app:syr2k:original>

#local(smart-skip: true, ranges: ((69, 99),), raw(syr2k-original, lang: "C", block: true))

=== syr2k pesto program <app:syr2k:atiled>

#local(
  smart-skip: true,
  ranges: (
    (1, 19),
    (77, 209),
  ),
  raw(syr2k-pesto, lang: "C", block: true),
)
/*
=== syr2k trahrhe header 1 <app:syr2k:trahrhe-header1>

#raw(syr2k-trahrhe-header1, lang: "C", block: true)

=== syr2k trahrhe header 2 <app:syr2k:trahrhe-header2>

#raw(syr2k-trahrhe-header2, lang: "C", block: true)
*/
== Pesto algebraic trapezoidal tiling

#let seidel-original = read("code/seidel2d.c")
#let seidel-tpz = read("code/seidel2d.tpz.c")
#let seidel-tpz-header = read("code/seidel2d.tpz.trahrhe.h")

=== Seidel-2d original program <app:seidel:original>

#local(
  smart-skip: true,
  ranges: (
    (51, 66),
  ),
  raw(seidel-original, lang: "C", block: true),
)

=== Seidel-2d trapezoidal tiled program <app:seidel:tpz>

#local(
  smart-skip: true,
  ranges: (
    (71, 230),
  ),
  raw(seidel-tpz, lang: "C", block: true),
)
/*
=== Seidel-2d trapezoidal tiled header <app:seidel:tpz-header>

#local(
  smart-skip: true,
  ranges: (
    (1, 129),
    (168, 172),
    (451, none),
  ),
  raw(seidel-tpz-header, lang: "C", block: true),
)
*/
