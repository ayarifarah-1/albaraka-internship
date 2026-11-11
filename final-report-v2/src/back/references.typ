#import "../lib/theme.typ": *

#plain-chapter[References]

#[
  #set text(size: 9.1pt)
  #set par(justify: false, leading: 0.58em, spacing: 0.82em)
  #show link: set text(font: mono, size: 0.86em, fill: navy)
  #bibliography("refs.yml", title: none, style: "ieee")
]
