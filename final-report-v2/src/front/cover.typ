#import "../lib/theme.typ": *

#let field(name, value, detail) = {
  set par(justify: false, leading: 0.55em, spacing: 0.5em)
  overline-label(name, fill: muted, size: 7.4pt)
  parbreak()
  text(font: sans, size: 12.5pt, weight: "semibold", fill: navy, value)
  parbreak()
  text(font: sans, size: 9.6pt, fill: muted, detail)
}

#page(
  margin: (left: 34mm, right: 24mm, top: 24mm, bottom: 22mm),
  header: none,
  footer: none,
  background: {
    // A navy spine with the two Al Baraka accents at its foot.
    place(top + left, rect(width: 12mm, height: 100%, fill: navy, stroke: none))
    place(bottom + left, rect(width: 12mm, height: 46mm, fill: red, stroke: none))
    place(bottom + left, rect(width: 12mm, height: 18mm, fill: orange, stroke: none))
  },
)[
  #set par(justify: false)
  #set text(hyphenate: false)

  // Institutional header
  #grid(
    columns: (1fr, 1fr),
    align: (left + horizon, right + horizon),
    image("../../assets/esprit.png", height: 17mm),
    image("../../assets/albaraka.png", height: 15.5mm),
  )
  #v(4mm)
  #line(length: 100%, stroke: 0.6pt + hair)
  #v(1.5mm)
  #grid(
    columns: (1fr, 1fr),
    align: (left + top, right + top),
    text(font: sans, size: 8.6pt, fill: muted)[École Supérieure Privée d'Ingénierie \ et de Technologies],
    text(font: sans, size: 8.6pt, fill: muted)[Al Baraka Bank Tunisia \ Centre Urbain Nord, Tunis],
  )

  #v(1fr)

  // Title block
  #overline-label([Internship report], size: 10pt)
  #v(2mm)
  #line(length: 22mm, stroke: 2pt + red)
  #v(5mm)
  #block(width: 96%, {
    set par(leading: 0.42em)
    text(font: display, size: 39pt, weight: "semibold", fill: navy, hyphenate: false)[A Governed Intelligence for Islamic Banking]
  })
  #v(4mm)
  #block(width: 88%, {
    set par(leading: 0.5em)
    text(font: sans, size: 17pt, weight: "light", fill: ink, hyphenate: false)[The integrated RAGLab and Bank Assistant platform]
  })
  #v(9mm)
  #block(
    width: 90%, inset: (left: 11pt, y: 2pt), stroke: (left: 2pt + orange),
    {
      set par(leading: 0.62em)
      overline-label([Subject], fill: muted, size: 7.4pt)
      linebreak()
      text(font: serif, size: 12pt, style: "italic", fill: ink)[Design and integration of a governed retrieval-augmented generation system for banking knowledge]
    },
  )

  #v(1.25fr)

  // Identity block
  #line(length: 100%, stroke: 0.6pt + hair)
  #v(5mm)
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 10mm,
    row-gutter: 8.5mm,
    field([Presented by], [Farah AYARI], [Software Engineering, ESPRIT]),
    field([Host organisation], [Al Baraka Bank Tunisia], [Avenue Cheikh Mohamed Fadhel Ben Achour, \ Centre Urbain Nord, 1082 Tunis]),
    field([Internship supervisor], [Mrs. Ahlem Ben Haddoud], [Al Baraka Bank Tunisia]),
    field([Academic year], [2025–2026], [Tunis, Tunisia]),
  )
  #v(2mm)
]
