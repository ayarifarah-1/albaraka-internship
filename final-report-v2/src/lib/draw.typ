// ─────────────────────────────────────────────────────────────────────────────
// draw.typ — a small vector-drawing kit for the report's diagrams and charts.
//
// Every figure is drawn natively by Typst: boxes, connectors and labels are
// vector objects set in the report's own typefaces, so diagrams stay sharp at
// any zoom level and never drift from the body typography.
//
// Coordinates are plain numbers in millimetres; the origin is the top-left
// corner of the canvas.
// ─────────────────────────────────────────────────────────────────────────────
#import "theme.typ": *

#let u = 1mm

/// Drawing surface. Children are produced by the helpers below.
#let canvas(w, h, ..items) = block(width: w * u, height: h * u, breakable: false, {
  set text(font: sans, size: 7.6pt, fill: ink, hyphenate: false, number-width: "proportional")
  set par(justify: false, leading: 0.42em, spacing: 0.4em)
  for it in items.pos() { it }
})

#let at(x, y, body) = place(top + left, dx: x * u, dy: y * u, body)

/// Rounded box with centred content.
#let node(
  x, y, w, h, body,
  fill: paper, stroke: 0.7pt + navy, radius: 1.6, inset: 1.3, pos: center + horizon, dash: none,
) = at(x, y, block(
  width: w * u, height: h * u, fill: fill, radius: radius * u,
  inset: if type(inset) == dictionary { inset } else { inset * u },
  stroke: if dash == none { stroke } else { (paint: stroke.paint, thickness: stroke.thickness, dash: dash) },
  align(pos, body),
))

/// Title + optional sub-line, the usual content of a node.
#let nt(title, sub: none, fill: navy, size: 1em) = {
  text(weight: "semibold", fill: fill, size: size, title)
  if sub != none {
    linebreak()
    text(size: 0.87em, fill: muted, sub)
  }
}

/// Free text block whose top-left corner sits at (x, y).
/// With `bg`, only the extent of the text itself is backed by that colour, so a
/// label can sit on top of a line and interrupt it cleanly.
#let label(x, y, w, body, pos: center, fill: ink, size: 1em, weight: "regular", bg: none) = at(x, y, box(
  width: w * u,
  align(pos, {
    let content = text(fill: fill, size: size, weight: weight, body)
    if bg == none { content } else { box(fill: bg, outset: (x: 0.9 * u, y: 0.55 * u), content) }
  }),
))

/// Dashed grouping frame with a small caption in its top-left corner.
#let zone(x, y, w, h, title, color: muted, fill: none, dash: "dashed", title-fill: paper) = {
  at(x, y, block(
    width: w * u, height: h * u, radius: 2.2 * u, fill: fill,
    stroke: (paint: color, thickness: 0.6pt, dash: dash),
  ))
  at(x + 2.2, y - 1.25, box(
    fill: title-fill, inset: (x: 1.1 * u, y: 0.2 * u),
    text(size: 6.4pt, weight: "semibold", fill: color, tracking: 0.08em, upper(title)),
  ))
}

/// Polyline connector through `pts` with an arrow head at the end
/// (and optionally at the start).
#let arrow(..pts, color: ink, thickness: 0.7pt, dash: none, head: true, tail: false, size: 1.75) = {
  let p = pts.pos()
  let tip(a, b) = {
    // Arrow head at b, pointing away from a.
    let dx = b.at(0) - a.at(0)
    let dy = b.at(1) - a.at(1)
    let len = calc.sqrt(dx * dx + dy * dy)
    if len == 0 { return none }
    let (ux, uy) = (dx / len, dy / len)
    let (bx, by) = (b.at(0) - ux * size, b.at(1) - uy * size)
    let hw = size * 0.36
    place(top + left, polygon(
      fill: color, stroke: none,
      (b.at(0) * u, b.at(1) * u),
      ((bx - uy * hw) * u, (by + ux * hw) * u),
      ((bx + uy * hw) * u, (by - ux * hw) * u),
    ))
  }
  // Shorten the stroked path so that it ends inside the arrow head.
  let shorten(a, b, amount) = {
    let dx = b.at(0) - a.at(0)
    let dy = b.at(1) - a.at(1)
    let len = calc.sqrt(dx * dx + dy * dy)
    if len == 0 { return b }
    (b.at(0) - dx / len * amount, b.at(1) - dy / len * amount)
  }
  let q = p
  if head { q.at(-1) = shorten(p.at(-2), p.at(-1), size * 0.75) }
  if tail { q.at(0) = shorten(p.at(1), p.at(0), size * 0.75) }
  place(top + left, curve(
    stroke: (paint: color, thickness: thickness, dash: dash, cap: "butt", join: "round"),
    curve.move((q.at(0).at(0) * u, q.at(0).at(1) * u)),
    ..q.slice(1).map(pt => curve.line((pt.at(0) * u, pt.at(1) * u))),
  ))
  if head { tip(p.at(-2), p.at(-1)) }
  if tail { tip(p.at(1), p.at(0)) }
}

/// Plain line (no head).
#let seg(a, b, color: hair, thickness: 0.5pt, dash: none) = place(top + left, line(
  start: (a.at(0) * u, a.at(1) * u), end: (b.at(0) * u, b.at(1) * u),
  stroke: (paint: color, thickness: thickness, dash: dash),
))

/// Filled rectangle.
#let bar(x, y, w, h, fill: navy, radius: 0) = at(x, y, rect(
  width: w * u, height: h * u, fill: fill, stroke: none, radius: radius * u,
))

/// Small numbered badge (used to number the steps of a flow).
#let badge(x, y, n, fill: red, d: 3.6) = at(x - d / 2, y - d / 2, box(
  width: d * u, height: d * u, radius: 50%, fill: fill,
  align(center + horizon, text(size: 6.4pt, weight: "bold", fill: paper, str(n))),
))

/// Pill-shaped tag.
#let pill(x, y, w, body, fill: tint, color: navy, h: 4.2) = at(x, y, box(
  width: w * u, height: h * u, radius: (h / 2) * u, fill: fill, stroke: 0.5pt + color.lighten(55%),
  align(center + horizon, text(size: 6.6pt, weight: "semibold", fill: color, body)),
))

// ── Charts ──────────────────────────────────────────────────────────────────

/// Legend row: array of (label, colour).
#let legend(x, y, items, gap: 4, sw: 2.6) = {
  // Laid out left-to-right from (x, y) inside a single box.
  at(x, y, {
    set text(size: 7pt, fill: muted)
    stack(dir: ltr, spacing: gap * u, ..items.map(it => stack(
      dir: ltr, spacing: 1.2 * u,
      box(width: sw * u, height: sw * u, radius: 0.5 * u, fill: it.at(1), baseline: 0.2 * u),
      it.at(0),
    )))
  })
}

/// Grouped vertical bar chart.
/// - `groups`: array of group labels (content)
/// - `series`: array of (name, colour)
/// - `data`: array (one per group) of arrays (one value per series)
#let barchart(
  groups, series, data,
  w: 150, h: 58, ymax: 100, step: 25, unit: "%",
  ml: 9, mb: 9.5, mt: 9.5, mr: 1,
  bar-w: auto, inner-gap: 0.7, value-size: 6.6pt, group-size: 7.2pt, title: none,
) = {
  let pw = w - ml - mr
  let ph = h - mt - mb
  let ng = groups.len()
  let ns = series.len()
  let gw = pw / ng
  let bw = if bar-w == auto { calc.min(8.5, (gw * 0.66 - inner-gap * (ns - 1)) / ns) } else { bar-w }
  let cluster = bw * ns + inner-gap * (ns - 1)
  let y0 = mt + ph
  let items = ()
  // Grid and y axis labels.
  let v = 0
  while v <= ymax {
    let y = y0 - ph * v / ymax
    items.push(seg((ml, y), (ml + pw, y), color: if v == 0 { faint } else { hair }, thickness: if v == 0 { 0.7pt } else { 0.4pt }))
    items.push(label(0, y - 1.3, ml - 1.6, pos: right, fill: muted, size: 6.6pt, [#v#unit]))
    v += step
  }
  // Bars.
  for (gi, g) in groups.enumerate() {
    let gx = ml + gw * gi + (gw - cluster) / 2
    for (si, s) in series.enumerate() {
      let val = data.at(gi).at(si)
      if val == none { continue }
      let bh = ph * val / ymax
      let bx = gx + si * (bw + inner-gap)
      items.push(bar(bx, y0 - bh, bw, bh, fill: s.at(1), radius: 0.3))
      items.push(label(bx - 3, y0 - bh - 3.1, bw + 6, pos: center, size: value-size, fill: ink, weight: "semibold", [#val]))
    }
    items.push(label(ml + gw * gi, y0 + 1.6, gw, pos: center, fill: ink, size: group-size, g))
  }
  if title != none { items.push(label(ml, 0, pw * 0.6, pos: left, weight: "semibold", fill: navy, size: 7.8pt, title)) }
  // Legend, right-aligned above the plot.
  items.push(at(ml, 0.2, box(width: pw * u, align(right, {
    set text(size: 7pt, fill: muted)
    stack(dir: ltr, spacing: 4 * u, ..series.map(s => stack(
      dir: ltr, spacing: 1.2 * u,
      box(width: 2.6 * u, height: 2.6 * u, radius: 0.5 * u, fill: s.at(1), baseline: 0.3 * u),
      s.at(0),
    )))
  }))))
  canvas(w, h, ..items)
}

/// Horizontal stacked bars (one row per item), values are absolute counts.
/// - `rows`: array of (label, (v1, v2, …))
/// - `series`: array of (name, colour)
#let stackedbars(rows, series, w: 150, row-h: 7.2, gap: 4.2, ml: 38, mr: 2, mt: 8, total: auto) = {
  let pw = w - ml - mr
  let items = ()
  let h = mt + rows.len() * (row-h + gap) + 1
  for (ri, r) in rows.enumerate() {
    let y = mt + ri * (row-h + gap)
    let tot = if total == auto { r.at(1).sum() } else { total }
    let x = ml
    items.push(label(0, y + row-h / 2 - 1.4, ml - 2.5, pos: right, r.at(0)))
    for (si, val) in r.at(1).enumerate() {
      let bw = pw * val / tot
      if val > 0 {
        let c = series.at(si).at(1)
        items.push(bar(x, y, bw, row-h, fill: c))
        items.push(label(x, y + row-h / 2 - 1.35, bw, pos: center, size: 7pt, weight: "semibold",
          fill: series.at(si).at(2, default: paper), [#val]))
      }
      x += bw
    }
  }
  items.push(at(ml, 0.4, {
    set text(size: 7pt, fill: muted)
    stack(dir: ltr, spacing: 4 * u, ..series.map(s => stack(
      dir: ltr, spacing: 1.2 * u,
      box(width: 2.6 * u, height: 2.6 * u, radius: 0.5 * u, fill: s.at(1), baseline: 0.3 * u),
      s.at(0),
    )))
  }))
  canvas(w, h, ..items)
}
