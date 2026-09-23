#import "@preview/icu-datetime:0.2.0" as icu

#import "header.typ": msii-header

#let front-cover(
  title: "My Beautiful Thesis Title",
  author: "Jessica LIDDEL",
  school: "Yay PhD School",
  laboratory: "Awesome Research Lab",
  defense-date: datetime.today(),
  supervisors: (
    (
      civility: "Dr.",
      firstname: "John",
      lastname: "Doe",
      position: "Professeur",
      affiliation: "MIT",
      description: none,
    ),
    (
      civility: "Prof. Dr.",
      firstname: "Jane",
      lastname: "Smith",
      position: "Esneignante-chercheuse",
      affiliation: "Harvard University",
      description: none,
    ),
  ),
  thesis-referees: (
    (
      civility: "Mme.",
      firstname: "Emily",
      lastname: "Johnson",
      position: "Professeure",
      affiliation: "Famous Institute",
      description: none,
    ),
  ),
  jury-members: (
    (
      civility: "Mme.",
      firstname: "Alice",
      lastname: "Brown",
      position: "Professeur",
      affiliation: "Great University",
      description: none,
    ),
    (
      civility: "M.",
      firstname: "Bob",
      lastname: "Davis",
      position: "Professeur",
      affiliation: "Renowned College",
      description: none,
    ),
    (
      civility: "M.",
      firstname: "Charlie",
      lastname: "Wilson",
      position: "MdC",
      affiliation: "Prestigious Academy",
      description: none,
    ),
  ),
  university-logo: none,
  university-name: none,
  doctoral-school-logo: none,
  doctoral-school-name: "École doctorale de Mathématiques, sciences de l'information et de l'ingénieur",
) = {
  let margin = 1cm
  // ------------------- Cover -------------------
  page(
    header: none,
    footer: none,
    margin: (top: margin, bottom: margin, left: margin, right: margin),
    numbering: none,
    [
      #set text(size: 1.3em, font: "Unistra A", lang: "fr", hyphenate: true)

      #let accent_font_size = 30pt
      #let title_font_size = 30pt
      // header
      //logos
      #if university-logo != none and doctoral-school-logo != none {
        msii-header(
          logo-left: doctoral-school-logo,
          title: text(size: 22pt, weight: "bold", [#upper(university-name)]),
          logo-right: university-logo,
        )
      }

      #align(center + top, [
        #upper(text(size: 18pt, doctoral-school-name))
        #linebreak()
        #text(size: 15pt, weight: "bold", laboratory)
      ])


      // middle block
      #align(center + horizon, [
        #text(size: accent_font_size, weight: "bold", upper("Thèse")) présentée
        par #linebreak()
        #text(size: accent_font_size, weight: "bold", author)
        #linebreak()
        soutenue le : #icu.fmt(
          defense-date,
          locale: "fr",
          date-fields: "YMD",
          length: "long",
        )
        #linebreak()
        #grid(
          columns: (1fr, 1.5fr),
          rows: 2,
          column-gutter: 1em,
          row-gutter: 0.5em,
          grid.cell(colspan: 1, align: right, [
            pour obtenir le grade de :
          ]),
          grid.cell(colspan: 1, align: left, [
            #text(weight: "bold", "Docteur de l'" + university-name)
          ]),
          grid.cell(colspan: 1, align: right, [
            Discipline/Spécialité :
          ]),
          grid.cell(colspan: 1, align: left, [
            #text(weight: "bold", "Informatique")
          ]),
        )
        #rect(width: 85%, inset: 20pt, fill: none, [
          #align(center + horizon, [
            #text(
              font: "Unistra C",
              size: title_font_size,
              weight: "bold",
              hyphenate: false,
              title,
            )
          ])
        ])
      ])
      //author
      // align(center, text(1.5em, weight: 500, degree + " Thesis by " + author))
      //study program

      //date
      // let deadline-text = deadline
      // if city != none {
      //   deadline-text = city + ", " + deadline
      // }
      // align(center, text(1.3em, weight: 100, deadline-text))
      // supervisors
      #let columns = (0.8cm, 3.6cm, auto)
      #align(left + bottom, [
        #upper("Thèse") dirigée par:
        #linebreak()
        #grid(
          columns: columns,
          rows: supervisors.len(),
          row-gutter: 0.2em,
          column-gutter: 1em,
          ..supervisors
            .map(p => (
              grid.cell(align: left, text(weight: "bold", p.civility)),
              grid.cell(align: left, text(
                weight: "bold",
                upper(p.lastname) + " " + p.firstname,
              )),
              grid.cell(align: left, p.position + ", " + p.affiliation),
            ))
            .flatten()
        )
      ])
      #upper("Rapporteurs :")
      #grid(
        columns: columns,
        rows: thesis-referees.len(),
        row-gutter: 0.2em,
        column-gutter: 1em,
        ..thesis-referees
          .map(p => (
            grid.cell(align: left, text(weight: "bold", p.civility)),
            grid.cell(align: left, text(
              weight: "bold",
              upper(p.lastname) + " " + p.firstname,
            )),
            grid.cell(align: left, p.position + ", " + p.affiliation),
          ))
          .flatten()
      )
      #upper("Examinateurs:")
      #grid(
        columns: columns,
        rows: jury-members.len(),
        row-gutter: 0.2em,
        column-gutter: 1em,
        ..jury-members
          .map(p => (
            grid.cell(align: left, text(weight: "bold", p.civility)),
            grid.cell(align: left, text(
              weight: "bold",
              upper(p.lastname) + " " + p.firstname,
            )),
            grid.cell(align: left, p.position + ", " + p.affiliation),
          ))
          .flatten()
      )




      #pagebreak()
      #pagebreak()


    ],
  ) // disable footer until the end of contents
}
