#import "header.typ": msii-header

#let back-cover(
  title: "",
  french-title: "",
  french-abstract: none,
  french-keywords: (),
  english-title: "",
  english-keywords: (),
  english-abstract: none,
  university-logo: none,
  doctoral-school-logo: none,
) = page(
  margin: 1cm,
  header: none,
  footer: none,
  numbering: none,
  [
    #msii-header(
      title: title,
      logo-left: doctoral-school-logo,
      logo-right: university-logo,
    )
    #set text(size: 11pt)
    #set par(
      leading: 0.7em,
    )
    #block(inset: 2em)[
      #block(breakable: false, [
        #align(center, text(size: 1.5em, weight: "bold", english-title))
        #rect(width: 100%, inset: 10pt, fill: none, radius: 5pt, [
          #block(text(size: 18pt, weight: "bold", "Abstract"))

          #english-abstract

          #if english-keywords != none and english-keywords != () {
            linebreak()
            text(weight: "bold", "Keywords: ")
            english-keywords.join(", ")
          }
        ])
      ])
      #v(1.5cm, weak: true)
      #block(breakable: false, [
        #align(center, text(size: 1.5em, weight: "bold", french-title))
        #rect(width: 100%, inset: 10pt, fill: none, radius: 5pt, [
          #block(text(size: 18pt, weight: "bold", "Résumé"))

          #french-abstract

          #if french-keywords != none and french-keywords != () {
            linebreak()
            text(weight: "bold", "Mots-clés : ")
            french-keywords.join(", ")
          }
        ])
      ])
    ]
  ],
)
