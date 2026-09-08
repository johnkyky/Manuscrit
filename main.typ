#import "covers/front.typ": front-cover
#import "covers/back.typ": back-cover
#import "glossary.typ": entry-list

#import "@preview/hydra:0.6.2": hydra

#import "src/common.typ": *

/* Codly initialization and configuration */
#show: codly-init.with()
#codly(languages: codly-languages.codly-languages)

/* Glossary initialization and configuration */
#show: make-glossary
#register-glossary(entry-list)

#show: show-theorion

#let lt(overwrite: false) = {
  if not sys.inputs.at("spellcheck", default: overwrite) {
    return doc => doc
  }
  return doc => {
    show math.equation.where(block: false): it => [0]
    show math.equation.where(block: true): it => []
    show raw.where(block: false): it => []
    show raw.where(block: true): it => [0]
    // show figure.caption.raw.where(block: false): it => [0]
    show figure.where(kind: raw): it => {
      it.caption
    }
    show bibliography: it => []
    show par: set par(justify: false, leading: 0.65em)
    set page(height: auto)
    set footnote.entry(separator: none) // add this to the styling
    show block: it => {
      it
    }
    show page: set page(numbering: none)
    show heading: it => if it.level <= 3 {
      it
    } else {
      it
    }
    doc
  }
}

#let custom-break(..args) = {
  set page(header: none, footer: none)
  pagebreak(..args)
}

/**
 * Document settings
 */
#let title-en = "Disambiguation of C++ Complexity for Advanced Program Optimization and Parallelization"
#let title-fr = "Désambiguïsation de la complexité du C++ pour l'optimisation et la parallélisation avancées de programmes"

#set document(title: title-en, author: "Ugo Battiston", date: datetime(day: 18, month: 12, year: 2026))

#set page(paper: "a4", number-align: center, numbering: none, footer: none)
#set text(font: "Brill", size: 12pt, hyphenate: false, lang: "en", features: (lnum: 1, onum: 0))
#set figure(placement: none)
#set align(left)
#show smallcaps: set text(font: "Libertinus Serif")
#show raw: set text(font: "FiraCode Nerd Font Mono", size: 8pt, ligatures: false, features: (calt: 0))
#show raw.where(block: false): it => {
  box(it)
}

#show math.equation: set text(font: "New Computer Modern Math", weight: "regular", size: 11pt)

/**
 * Front matter
 */
#show heading.where(depth: 1): hbody => {
  set text(size: 26pt, weight: "bold")
  hbody
  v(20pt)
}

#front-cover(
  title: title-en,
  author: "Ugo BATTISTON",
  defense-date: datetime(day: 18, month: 12, year: 2025),
  supervisors: (
    (
      civility: "M.",
      firstname: "Philippe",
      lastname: "Clauss",
      position: "Professeur",
      affiliation: "Université de Strasbourg",
    ),
    (
      civility: "M.",
      firstname: "Marc",
      lastname: "Pérache",
      position: "JSP",
      affiliation: "CEA DAM Île-de-France, Université de Paris-Saclay",
    ),
  ),
  thesis-referees: (
    (
      civility: "Mme",
      firstname: "Isabelle",
      lastname: "PUAUT",
      position: "Professeur",
      affiliation: "Université de Rennes",
    ),
    (
      civility: "M.",
      firstname: "Sid",
      lastname: "Touati",
      position: "Professeur",
      affiliation: "Université Côte d'Azur",
    ),
  ),
  jury-members: (
    (
      civility: "M.",
      firstname: "Fabrice",
      lastname: "Rastello",
      position: "Directeur de Recherche",
      affiliation: "Centre Inria de l'Université de Grenoble",
    ),
    (
      civility: "M.",
      firstname: "Christophe",
      lastname: "Alias",
      position: "Chargé de Recherche",
      affiliation: "ENS Lyon",
    ),
  ),
  university-name: "Université de Strasbourg",
  university-logo: image("images/covers/unistra.jpg"),
  doctoral-school-logo: image("images/covers/ed_msii.jpg"),
  laboratory: "Laboratoire des sciences de l'ingénieur, de l'informatique et de l'imagerie (UMR 7357)",
)

#pagebreak()
#pagebreak(to: "odd")

#set par(leading: 1.2em, spacing: 1.8em, justify: true, first-line-indent: 1.5em)
#set heading(numbering: none)
#set page(numbering: "i", margin: (x: 3cm), footer: context {
  align(center, counter(page).display())
})
// TODO : uncomment these lines when the abstracts and acknowledgments are ready
#show outline: set heading(outlined: true)
#counter(page).update(1)
#outline(title: "Table of Contents")
#pagebreak(to: "odd")
#outline(title: "List of Figures", target: figure.where(kind: image))
#pagebreak(to: "odd")
#outline(title: "List of Listings", target: figure.where(kind: raw))
#pagebreak(to: "odd")
#outline(title: "List of Tables", target: figure.where(kind: table))
// = Glossary
// #print-glossary(entry-list, disable-back-references: true)

#custom-break()
#custom-break()
#custom-break(to: "odd")

/**
 *  Main mattter
 */
// Numbering styles
#set heading(numbering: "1.")
// number math equations
#set math.equation(numbering: "(1)")
#set page(
  numbering: "1",
  margin: (x: 3cm, bottom: 2.5cm, top: 3.5cm),
  // alternate pages
  // margin: (inside: 3.5cm, outside: 3cm, bottom: 2.5cm, top: 3.5cm),
  header: context {
    v(0.5cm)
    block({
      if calc.odd(here().page()) {
        h(1fr)
        smallcaps(text(size: 14pt, hydra(1)))
      } else {
        smallcaps(text(size: 14pt, hydra(2)))
        h(1fr)
      }
    })
  },
  footer: context {
    align(center, counter(page).display())
  },
)
#set math.mat(align: right)

// heading styles
#show heading: set text(features: (lnum: 0, onum: 1))
#show heading: set par(spacing: 1.5em, first-line-indent: 0in, justify: false)
#show heading: it => block(it + v(0.5cm))

#show heading.where(level: 1): set text(size: 34pt, weight: "bold")
#show heading.where(level: 1): set par(spacing: 1.1em, first-line-indent: 0in, justify: false)

#show heading.where(level: 1): it => {
  custom-break()
  custom-break(to: "odd")
  block({
    v(2cm)
    text(size: 28pt, [Chapter #counter(heading).display("1")])
    linebreak()

    it.body

    v(1.5cm)
  })
}

#show heading.where(level: 2): set text(size: 22pt, weight: "bold")
#show heading.where(level: 2): it => block(v(0.5em) + it)

#show heading.where(level: 3).or(heading.where(level: 4)): set text(size: 18pt, weight: "semibold")
#show heading.where(level: 3).or(heading.where(level: 4)): it => pad(left: 2em, it)

// Pad lists
#show list: it => pad(left: 1em, top: 0em, it)
#show enum: it => pad(left: 1em, top: 0em, it)
#set cite(style: "./citation.csl")

/*
  global formating
*/

#show table.cell: set text(font: "New Computer Modern Math", size: 9pt)
#show "et al.": emph
#show "ad hoc": emph
#show "e.g.": emph
#show "i.e.": emph

#let softwares = (
  "Kokkos",
  "RAJA",
  "Pluto",
  "Clang",
  "GCC",
  "LLVM",
  "Polly",
  "Apollo",
  "PPCG",
  "OpenScop library",
  "OpenScop",
  regex("\b(isl)\b"),
  "Integer Set Library",
  "PET",
  "Graphite",
  "PolyLib",
  "Polyhedral Library",
  "PIPLib",
  "Parametric Integer Programming Library",
  "std::par",
)

#for s in softwares {
  show s: it => software(it)
}

#show raw: it => {
  for s in softwares {
    show s: name => name
  }
  it
}

#show: lt(overwrite: false)

#show heading.where(level: 1): it => {
  custom-break(to: "odd", weak: true)
  block({
    v(2cm)
    text(size: 28pt, [Chapter #counter(heading).display("1")])
    linebreak()

    it.body

    v(1.5cm)
  })
}

// double spacing
// #set par(
//   leading: 2.4em,
//   spacing: 3.2em,
//   first-line-indent: 1.9em,
// )

// reset page counter
#counter(page).update(1)
#include "chapters/11-Introduction.typ"

#include "chapters/12-ScientificBackground.typ"
#include "chapters/13-StateOfTheArt.typ"
#include "chapters/14-KokkosVisibility.typ"
#include "chapters/15-ComplexExecutionPatterns.typ"
#include "chapters/16-SchedulingHeterogeneous.typ"
#include "chapters/17-Evaluations.typ"

#include "chapters/18-Conclusion.typ"

/**
 * Back matter
 */

#show heading.where(depth: 1): it => [
  #set text(size: 26pt, weight: "bold")
  #set par(spacing: 1.5em, first-line-indent: 0in, justify: false)
  #custom-break(to: "odd", weak: true)
  #block()[
    #it.body
  ]
]

#bibliography("references.bib", title: "References")

/**
 * Appendices
 */
#set heading(numbering: "A.1.")
#show heading.where(depth: 1): it => {
  set text(size: 36pt, weight: "bold")
  set par(spacing: 1.1em, first-line-indent: 0in, justify: false)
  custom-break(to: "odd")
  block({
    v(2cm)

    text(size: 30pt, [Appendix #counter(heading).display("A")])

    v(0.2cm)
    it.body
    v(1cm)
  })
}
#counter(heading).update(0)

#include "appendices/resume.typ"
// #include "appendices/trahrhe.typ"
// #include "appendices/code_excerpts.typ"

/**
 * Back cover
 */
#custom-break()
#custom-break(to: "odd", weak: false)

#back-cover(
  title: "Ugo BATTISTON",
  french-title: title-fr,
  french-abstract: [
    #set text(lang: "fr")
    #todo(130)
  ],
  french-keywords: (
    "Calcul haute performance",
    "Compilation",
    "Optimisation de boucles",
    "Représentation intermédiaire",
    "Kokkos",
  ),
  english-title: title-en,
  english-abstract: [
    #todo(130)
  ],
  english-keywords: (
    "High-performance computing",
    "Compilation",
    "Loops optimization",
    "Intermediate representation",
    "Kokkos",
  ),
  university-logo: image("images/covers/unistra.jpg"),
  doctoral-school-logo: image("images/covers/ed_msii.jpg"),
)
