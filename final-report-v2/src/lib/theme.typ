// ─────────────────────────────────────────────────────────────────────────────
// theme.typ — visual identity and reusable components of the report
// ─────────────────────────────────────────────────────────────────────────────

// Palette: Al Baraka red and orange, ESPRIT navy, and a neutral ink scale.
#let navy = rgb("#1B2A4E")
#let red = rgb("#E0122F")
#let orange = rgb("#F5881C")
#let teal = rgb("#1C7C7A")
#let ink = rgb("#20242E")
#let muted = rgb("#5E6778")
#let faint = rgb("#8B93A3")
#let hair = rgb("#D5DAE3")
#let tint = rgb("#F3F5F9")
#let paper = rgb("#FFFFFF")

// Type: Source Serif 4 for reading, Source Sans 3 for structure, Source Code
// Pro for code, Noto Naskh Arabic as the Arabic fallback of every stack.
#let serif = ("Source Serif 4", "Noto Naskh Arabic")
#let display = ("Source Serif 4 Display", "Source Serif 4")
#let sans = ("Source Sans 3", "Noto Naskh Arabic")
#let mono = ("Source Code Pro", "Noto Naskh Arabic")

#let body-size = 10.5pt

// ── Small inline helpers ────────────────────────────────────────────────────

/// Arabic run inside an English paragraph.
#let ar(body) = text(font: "Noto Naskh Arabic", lang: "ar", size: 1.04em, body)

/// Tracked small label (used for overlines, table group headers, tags).
#let overline-label(body, fill: red, size: 8pt) = text(
  font: sans, size: size, weight: "semibold", fill: fill, tracking: 0.11em, upper(body),
)

/// A short lead paragraph placed under a chapter title.
#let lead(body) = {
  set text(font: sans, size: 11.5pt, fill: muted, weight: "light")
  set par(justify: false, leading: 0.7em)
  block(width: 92%, below: 1.6em, body)
}

/// Run-in heading used inside paragraphs and lists.
#let runin(body) = text(font: sans, weight: "semibold", fill: navy, size: 0.96em, body)

// ── Callouts ────────────────────────────────────────────────────────────────

#let callout-kinds = (
  note: (color: navy, label: "Note"),
  principle: (color: navy, label: "Design principle"),
  decision: (color: orange, label: "Decision"),
  lesson: (color: teal, label: "Lesson learned"),
  limit: (color: red, label: "Limitation"),
)

#let callout(kind: "note", title: none, body) = {
  let k = callout-kinds.at(kind)
  let c = k.color
  block(
    width: 100%,
    breakable: false,
    above: 1.3em,
    below: 1.3em,
    inset: (left: 13pt, right: 12pt, top: 10pt, bottom: 11pt),
    radius: (right: 3pt),
    fill: c.lighten(93%),
    stroke: (left: 2.6pt + c),
    {
      block(above: 0pt, below: 0.62em, sticky: true, {
        set par(justify: false)
        overline-label(fill: c.darken(8%), size: 7.6pt, k.label)
        if title != none {
          h(0.6em)
          text(font: sans, size: 9.4pt, weight: "semibold", fill: navy, title)
        }
      })
      set text(size: body-size - 0.5pt)
      set par(justify: true, leading: 0.66em, spacing: 0.8em)
      body
    },
  )
}

// ── Key-figure tiles ────────────────────────────────────────────────────────

/// `items` is an array of (value, label) pairs.
#let kpis(items, columns: auto, accent: navy) = {
  let n = if columns == auto { items.len() } else { columns }
  block(above: 1.5em, below: 1.6em, width: 100%, breakable: false, grid(
    columns: (1fr,) * n,
    column-gutter: 6pt,
    row-gutter: 6pt,
    ..items.map(it => grid.cell(
      fill: tint,
      stroke: (top: 2pt + accent),
      inset: (x: 9pt, top: 10pt, bottom: 10pt),
      {
        set par(justify: false, leading: 0.5em, spacing: 0.5em)
        text(font: sans, size: 17pt, weight: "semibold", fill: navy, number-width: "proportional", hyphenate: false, it.at(0))
        parbreak()
        text(font: sans, size: 8pt, fill: muted, hyphenate: false, it.at(1))
      },
    ))
  ))
}

// ── Tables ──────────────────────────────────────────────────────────────────

/// Booktabs-style data table.
/// `header` is an array of header cells; remaining positional args are cells.
#let dtable(columns: auto, header: (), align: left + top, size: 8.8pt, pad: 5pt, ..cells) = {
  set text(font: sans, size: size, number-width: "tabular", hyphenate: true)
  set par(justify: false, leading: 0.52em, spacing: 0.5em)
  show raw: set text(size: 1.02em)
  table(
    columns: columns,
    align: align,
    stroke: none,
    inset: (x: 6pt, y: pad),
    fill: (x, y) => if y == 0 { tint },
    table.hline(stroke: 1pt + navy),
    table.header(..header.map(h => text(weight: "semibold", fill: navy, h))),
    table.hline(stroke: 0.6pt + navy),
    ..cells
      .pos()
      .enumerate()
      .map(((i, c)) => c),
    table.hline(stroke: 1pt + navy),
  )
}

/// Row separator hairline for long tables.
#let rowline = table.hline(stroke: 0.4pt + hair)

// ── The report template ─────────────────────────────────────────────────────

#let report(meta: (:), body) = {
  set document(title: meta.title, author: meta.author, keywords: meta.keywords)

  set page(
    paper: "a4",
    margin: (top: 31mm, bottom: 29mm, left: 30mm, right: 30mm),
    header-ascent: 34%,
    footer-descent: 38%,
    header: context {
      let here-page = here().page()
      if here().page-numbering() == none { return }
      let chapters = query(heading.where(level: 1))
      // No running header on a page that opens a chapter.
      if chapters.any(h => h.location().page() == here-page) { return }
      let before = chapters.filter(h => h.location().page() < here-page)
      if before.len() == 0 { return }
      let ch = before.last()
      let label = if ch.numbering != none {
        let n = counter(heading).at(ch.location()).first()
        [#ch.supplement #numbering(ch.numbering, n) #h(0.5em) #sym.dot.c #h(0.5em) #ch.body]
      } else { ch.body }
      set text(font: sans, size: 8pt, fill: muted, dir: ltr, lang: "en")
      grid(
        columns: (1fr, auto),
        align: (left + bottom, right + bottom),
        text(tracking: 0.04em, meta.running),
        text(weight: "semibold", fill: navy, label),
      )
      v(-0.55em)
      line(length: 100%, stroke: 0.5pt + hair)
    },
    footer: context {
      let pattern = here().page-numbering()
      if pattern == none { return }
      set text(font: sans, size: 8pt, fill: muted, dir: ltr, lang: "en")
      grid(
        columns: (1fr, auto),
        align: (left + horizon, right + horizon),
        meta.footer,
        text(size: 9.5pt, weight: "semibold", fill: navy, counter(page).display(pattern)),
      )
    },
  )

  // Fixed text edges: a fallback (Arabic) glyph never changes the line pitch.
  set text(
    font: serif, size: body-size, lang: "en", region: "GB", fill: ink,
    hyphenate: true, number-type: "lining", top-edge: 0.67em, bottom-edge: 0em,
  )
  set par(justify: true, leading: 0.7em, spacing: 1.08em, linebreaks: "optimized")

  // Headings ------------------------------------------------------------------
  set heading(numbering: "1.1", supplement: [Chapter])

  show heading: set text(font: sans, fill: navy, hyphenate: false)
  show heading: set par(justify: false, leading: 0.5em)

  show heading.where(level: 1): it => {
    pagebreak(weak: true)
    // Per-chapter numbering of figures, tables and listings.
    counter(figure.where(kind: image)).update(0)
    counter(figure.where(kind: table)).update(0)
    counter(figure.where(kind: raw)).update(0)
    let numbered = it.numbering != none
    block(width: 100%, above: 0pt, below: 2.1em, breakable: false, {
      v(12mm)
      if numbered {
        context {
          let n = counter(heading).get().first()
          place(top + right, dy: 1mm, text(
            font: display, size: 76pt, weight: "semibold", fill: hair.lighten(8%),
            numbering(it.numbering, n),
          ))
          overline-label([#it.supplement #numbering(it.numbering, n)], size: 8.6pt)
        }
      } else {
        overline-label(sym.zws, size: 8.6pt)
      }
      v(-0.3em)
      line(length: 16mm, stroke: 1.6pt + red)
      v(0.25em)
      block(width: 82%, text(
        font: display, size: 25pt, weight: "semibold", fill: navy, hyphenate: false,
        it.body,
      ))
    })
  }

  show heading.where(level: 2): it => block(above: 1.9em, below: 0.95em, breakable: false, {
    set text(size: 13.2pt, weight: "semibold")
    if it.numbering != none {
      context text(fill: red, counter(heading).display(it.numbering))
      h(0.7em)
    }
    it.body
  })

  show heading.where(level: 3): it => block(above: 1.55em, below: 0.8em, breakable: false, {
    set text(size: 10.8pt, weight: "semibold")
    if it.numbering != none {
      context text(fill: muted, weight: "regular", counter(heading).display(it.numbering))
      h(0.65em)
    }
    it.body
  })

  show heading.where(level: 4): it => block(above: 1.3em, below: 0.6em, {
    set text(size: 10pt, weight: "semibold", fill: ink)
    it.body
  })

  // Lists ---------------------------------------------------------------------
  set list(
    marker: (text(fill: red, size: 0.8em, baseline: -0.12em, sym.square.filled), text(fill: muted, [–])),
    indent: 0.4em, body-indent: 0.7em, spacing: 0.72em,
  )
  set enum(indent: 0.4em, body-indent: 0.7em, spacing: 0.72em, numbering: n => text(
    font: sans, weight: "semibold", fill: navy, size: 0.94em, numbering("1.", n),
  ))
  set terms(separator: [: ], hanging-indent: 1.2em)

  // Code ----------------------------------------------------------------------
  set raw(theme: none)
  show raw: set text(font: mono, ligatures: false)
  show raw.where(block: false): set text(size: 1.09em, fill: navy.darken(10%))
  show raw.where(block: true): it => block(
    width: 100%, breakable: true, above: 1.2em, below: 1.2em,
    inset: (x: 11pt, y: 10pt), radius: 3pt, fill: tint, stroke: (left: 2pt + navy.lighten(55%)),
    {
      set align(left)
      set text(size: 8.3pt, fill: ink)
      set par(justify: false, leading: 0.58em)
      it
    },
  )

  // Figures -------------------------------------------------------------------
  let chapter-prefix(n) = {
    let levels = counter(heading).get()
    let c = if levels.len() > 0 { levels.first() } else { 0 }
    let style = query(heading.where(level: 1).before(here()))
    let pattern = if style.len() > 0 and style.last().numbering != none { style.last().numbering } else { "1.1" }
    [#numbering(pattern, c).#n]
  }
  set figure(numbering: n => chapter-prefix(n), gap: 1.0em)
  show figure: set block(above: 1.7em, below: 1.7em)
  show figure.where(kind: table): set figure.caption(position: top)
  show figure.where(kind: table): set block(breakable: true)
  show figure.where(kind: raw): set figure.caption(position: top)
  show figure.caption: it => {
    set text(font: sans, size: 8.8pt, fill: muted)
    set par(justify: false, leading: 0.55em)
    align(center, block(width: 92%, sticky: it.kind != image, {
      text(weight: "semibold", fill: navy)[#it.supplement #context it.counter.display(it.numbering)]
      h(0.65em)
      it.body
    }))
  }

  // Links, footnotes, quotes --------------------------------------------------
  show link: it => if type(it.dest) == str { text(fill: navy, it) } else { it }
  set footnote.entry(separator: line(length: 22%, stroke: 0.5pt + hair), gap: 0.6em)
  show footnote.entry: set text(size: 8.6pt)
  set quote(block: true)
  show quote.where(block: true): it => block(
    inset: (left: 14pt, y: 2pt), stroke: (left: 1.5pt + hair),
    text(style: "italic", fill: muted, it.body),
  )

  body
}

// ── Front- and back-matter helpers ──────────────────────────────────────────

/// Unnumbered chapter-level heading (kept in the outline unless stated).
#let plain-chapter(title, outlined: true) = heading(level: 1, numbering: none, outlined: outlined, title)

/// Styled table of contents.
#let contents(depth: 2) = {
  show outline.entry.where(level: 1): it => {
    set block(above: 1.12em)
    set text(font: sans, weight: "semibold", fill: navy, size: 10.2pt)
    link(it.element.location(), it.indented(
      if it.prefix() != none { box(width: 1.7em, text(fill: red, it.prefix())) },
      [#it.body() #h(1fr) #it.page()],
    ))
  }
  show outline.entry.where(level: 2): it => {
    set block(above: 0.58em)
    set text(font: sans, size: 9.6pt, fill: ink)
    link(it.element.location(), it.indented(
      box(width: 2.3em, text(fill: muted, it.prefix())),
      [#it.body() #h(0.5em) #box(width: 1fr, repeat(gap: 0.35em, text(fill: faint.lighten(35%), [.]))) #h(0.5em) #text(fill: muted, it.page())],
    ))
  }
  outline(title: none, depth: depth, indent: 1.7em)
}

/// List of figures / tables / listings.
#let list-of(kind) = {
  show outline.entry: it => {
    set block(above: 0.66em)
    set text(font: sans, size: 9.4pt, fill: ink)
    set par(justify: false)
    link(it.element.location(), it.indented(
      box(width: 4.9em, text(fill: navy, weight: "semibold", it.prefix())),
      [#it.body() #h(0.5em) #box(width: 1fr, repeat(gap: 0.35em, text(fill: faint.lighten(35%), [.]))) #h(0.5em) #text(fill: muted, it.page())],
    ))
  }
  outline(title: none, target: figure.where(kind: kind))
}

/// Figure whose body is a drawing (forces the "Figure" kind even when the
/// drawing contains code-styled labels).
#let fig(body, caption: none, placement: none) = figure(
  kind: image, supplement: [Figure], placement: placement, body, caption: caption,
)

/// Figure whose body is a table. Tables are kept on one page unless
/// `breakable` is set; `placement: auto` lets a table float to the top or the
/// bottom of a page so that the text keeps flowing.
#let tab(body, caption: none, breakable: false, placement: none) = figure(
  kind: table, supplement: [Table], placement: placement, caption: caption,
  if breakable { body } else { block(breakable: false, body) },
)

/// Figure whose body is a code listing.
#let lst(body, caption: none, placement: none) = figure(
  kind: raw, supplement: [Listing], placement: placement, body, caption: caption,
)
