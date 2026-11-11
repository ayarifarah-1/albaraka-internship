// ─────────────────────────────────────────────────────────────────────────────
// figures.typ — every diagram and chart of the report, drawn as vectors.
// Coordinates are millimetres on a canvas whose origin is its top-left corner.
// ─────────────────────────────────────────────────────────────────────────────
#import "lib/theme.typ": *
#import "lib/draw.typ": *

// Shared styles ---------------------------------------------------------------
#let s-navy = 0.7pt + navy
#let s-red = 0.7pt + red
#let s-orange = 0.7pt + orange
#let s-teal = 0.7pt + teal
#let s-soft = 0.6pt + faint

#let f-navy = navy.lighten(92%)
#let f-red = red.lighten(93%)
#let f-orange = orange.lighten(90%)
#let f-teal = teal.lighten(91%)

/// Legend entry with a numbered badge.
#let key(x, y, w, n, body, fill: red) = {
  badge(x + 1.8, y + 1.75, n, fill: fill)
  label(x + 4.6, y + 0.45, w - 4.6, pos: left, size: 6.9pt, fill: muted, body)
}

/// Multi-line sub-text for a node.
#let lines(..items) = text(size: 0.87em, fill: muted, items.pos().join(linebreak()))

// ═════════════════════════════════════════════════════════════════════════════
// Chapter 3 — architecture
// ═════════════════════════════════════════════════════════════════════════════

#let fig-architecture = canvas(150, 84,
  zone(0, 4, 22.5, 64, [Internet]),
  zone(25.5, 4, 96, 64, [Bank private network], color: navy),
  zone(124.5, 4, 25.5, 64, [Model APIs]),

  node(2, 17, 18.5, 14, nt([Customer], sub: [public chat and portal])),
  node(2, 39, 18.5, 14, nt([Bank staff], sub: [operations console])),

  node(29, 14, 23, 42, fill: tint, {
    nt([nginx])
    linebreak()
    lines([Angular SPA], [`/api` proxy], [security headers], [unbuffered SSE])
  }),
  node(60, 10, 28, 36, fill: f-navy, {
    nt([Spring Boot edge])
    linebreak()
    lines([identity and roles], [quotas and metering], [persistence, audit], [answer sanitising], [administration API])
  }),
  node(60, 53, 28, 12, stroke: s-orange, fill: f-orange, nt([PostgreSQL 16], sub: [Flyway V1–V15])),

  node(96, 10, 22.5, 36, fill: f-red, stroke: s-red, {
    nt([RAGLab], fill: red.darken(15%))
    linebreak()
    lines([retrieval], [sufficiency], [grounded answer], [citation gate], [audit trail])
  }),
  node(96, 53, 22.5, 12, stroke: s-orange, fill: f-orange, nt([Vector index], sub: [ChromaDB, cosine])),

  node(127, 13, 20.5, 14, nt([Embeddings], sub: [pinned, 2048-d])),
  node(127, 32, 20.5, 14, nt([Answer model], sub: [pinned, no fallback])),

  arrow((20.5, 24), (29, 24)),
  arrow((20.5, 46), (29, 46)),
  arrow((52, 28), (60, 28)),
  arrow((74, 46), (74, 53), tail: true),
  arrow((88, 28), (96, 28)),
  arrow((107.2, 46), (107.2, 53), tail: true),
  arrow((118.5, 20), (127, 20)),
  arrow((118.5, 39), (127, 39)),

  badge(24.6, 35, 1),
  badge(56, 28, 2),
  badge(74, 49.5, 3),
  badge(92, 28, 4),
  badge(107.2, 49.5, 5),
  badge(122.8, 29.5, 6),

  key(0, 73, 50, 1, [HTTPS; only the web tier is reachable]),
  key(50, 73, 50, 2, [same-origin `/api`, server-sent events]),
  key(100, 73, 50, 3, [JDBC; the edge is the only writer]),
  key(0, 79, 50, 4, [HTTP with `X-Service-Token`]),
  key(50, 79, 50, 5, [local, fingerprinted index]),
  key(100, 79, 50, 6, [outbound calls to the pinned models]),
)

// Sequence diagram: the life of one customer question -------------------------
#let fig-sequence = {
  let xs = (browser: 13, edge: 57, db: 99, rag: 137)
  let bottom = 101
  let head(x, title, sub, fill: tint, stroke: s-navy) = node(x - 12.5, 0, 25, 9.5, fill: fill, stroke: stroke, nt(title, sub: sub))
  let life(x) = seg((x, 9.5), (x, bottom), color: faint, thickness: 0.5pt, dash: "dashed")
  let msg(y, a, b, n, body, dashed: false, color: ink) = {
    arrow((a, y), (b, y), color: color, dash: if dashed { "dashed" } else { none })
    let lo = calc.min(a, b)
    let hi = calc.max(a, b)
    label(lo + 5.4, y - 3.75, hi - lo - 6.5, pos: left, size: 6.9pt, bg: paper, body)
    badge(lo + 2.7, y - 2.5, n)
  }
  let act(y, x, n, w, body, h: 7.6, fill: f-navy, stroke: 0.5pt + navy.lighten(40%)) = {
    node(x + 2.6, y, w, h, fill: fill, stroke: stroke, radius: 1, inset: 1.1, pos: left + horizon, text(size: 6.9pt, body))
    badge(x, y + h / 2, n)
  }
  canvas(150, 102,
    life(xs.browser), life(xs.edge), life(xs.db), life(xs.rag),
    head(xs.browser, [Browser], [Angular SPA, via nginx]),
    head(xs.edge, [Spring Boot edge], [the only writer], fill: f-navy),
    head(xs.db, [PostgreSQL], [schema owner], fill: f-orange, stroke: s-orange),
    head(xs.rag, [RAGLab], [external engine], fill: f-red, stroke: s-red),

    msg(18.5, xs.browser, xs.edge, 1, [`POST /api/chat/message/stream`]),
    act(22, xs.edge, 2, 36, [per-session lock, then the gate: new-session limit and quota]),
    msg(37, xs.edge, xs.db, 3, [open the exchange row]),
    msg(45.5, xs.db, xs.edge, 4, [masked customer context], dashed: true),
    msg(54, xs.edge, xs.rag, 5, [`POST /answer` with `X-Service-Token`]),
    act(57.5, xs.rag - 39.5, 6, 34, h: 10.6, fill: f-red, stroke: 0.5pt + red.lighten(40%),
      [retrieve, check sufficiency, generate, verify citations, scrub]),
    msg(75.5, xs.rag, xs.edge, 7, [status, answer, claims, sources], dashed: true),
    act(79, xs.edge, 8, 36, [strip provenance, or substitute the bank's own refusal wording]),
    msg(94, xs.edge, xs.db, 9, [close the row, settle usage]),
    msg(100, xs.edge, xs.browser, 10, [SSE frames: `delta`, then `done`], dashed: true),
  )
}

// ═════════════════════════════════════════════════════════════════════════════
// Chapter 4 — RAGLab
// ═════════════════════════════════════════════════════════════════════════════

#let fig-evolution = {
  let card(x, w, title, tag, items, stroke: s-navy, fill: paper, tag-fill: navy) = {
    node(x, 4, w, 39, stroke: stroke, fill: fill, pos: left + top, inset: (x: 2 * u, top: 4.4 * u, bottom: 2 * u), {
      text(weight: "semibold", fill: tag-fill, size: 1.03em, title)
      v(0.4mm)
      set text(size: 6.9pt, fill: ink)
      for it in items { block(above: 0.62em, below: 0pt, grid(columns: (2mm, 1fr), text(fill: tag-fill, [–]), it)) }
    })
    pill(x + 2, 1.9, tag.len() * 1.3 + 4.5, tag, fill: paper, color: tag-fill)
  }
  canvas(150, 55,
    card(0, 36, [Flat retrieval laboratory], "GENERATION 1", (
      [several embedding providers],
      [machine-translated query variants],
      [dense, RRF and blend modes],
      [answer fallback chain],
      [test sheets, web-compiled corpus],
    ), stroke: s-soft, tag-fill: muted),
    card(39.5, 33, [Methodological reset], "PIVOT", (
      [reverse-engineered specification],
      [gap analysis against the target],
      [the four real documents only],
      [step-and-plan protocol],
      [linguistic repair of the corpus],
    ), stroke: s-orange, fill: f-orange, tag-fill: orange.darken(22%)),
    card(76, 37, [Four governed layers], "GENERATION 2", (
      [corpus and structure],
      [knowledge: units, relations, numbers],
      [understanding: intent, sufficiency],
      [delivery: gate, scrub, audit trail],
      [frozen, additive HTTP contract],
    ), stroke: s-navy, fill: f-navy, tag-fill: navy),
    card(116.5, 33.5, [Question-to-corpus link], "CURRENT · V1.5.0", (
      [source-grounded topic map],
      [guided round fixed in service],
      [French intent rule corrected],
      [duplicate pushes blocked],
      [re-aimed answers disclosed],
    ), stroke: s-red, fill: f-red, tag-fill: red.darken(12%)),
    arrow((36, 23.5), (39.5, 23.5), size: 1.5),
    arrow((72.5, 23.5), (76, 23.5), size: 1.5),
    arrow((113, 23.5), (116.5, 23.5), size: 1.5),
    node(0, 47, 150, 7.5, fill: tint, stroke: 0.5pt + hair, radius: 1.2, {
      text(weight: "semibold", fill: navy, [Unchanged core])
      h(2.2mm)
      text(fill: muted, [pinned embedding model · local cosine index · pinned answer model · deterministic citation gate])
    }),
  )
}

// Chunking: fixed window versus structure-aware --------------------------------
#let fig-chunking = {
  // A stylised page: headings are dark bars, body lines are light bars.
  // `rows` lists (kind, width-fraction); kinds: h1, h2, p.
  let doc = (
    ("h1", 0.62), ("p", 0.96), ("p", 0.9),
    ("h2", 0.46), ("p", 0.97), ("p", 0.93), ("p", 0.98), ("p", 0.6),
    ("h2", 0.5), ("p", 0.95), ("p", 0.98), ("p", 0.42),
    ("h2", 0.4), ("p", 0.97), ("p", 0.92), ("p", 0.96), ("p", 0.9), ("p", 0.55),
    ("h2", 0.52), ("p", 0.94), ("p", 0.7),
  )
  let pitch = 2.25
  let page-top = 12
  let draw-doc(x, w) = {
    for (i, r) in doc.enumerate() {
      let y = page-top + 2.2 + i * pitch
      if r.at(0) == "h1" { bar(x + 2.5, y, (w - 5) * r.at(1), 1.25, fill: navy, radius: 0.3) }
      else if r.at(0) == "h2" { bar(x + 2.5, y, (w - 5) * r.at(1), 1.1, fill: navy.lighten(35%), radius: 0.3) }
      else { bar(x + 2.5, y + 0.15, (w - 5) * r.at(1), 0.8, fill: hair.darken(6%), radius: 0.3) }
    }
  }
  let page-h = doc.len() * pitch + 4
  let row-y(i) = page-top + 2.2 + i * pitch - 0.62
  let cut(x, w, i, color: red) = seg((x - 1.5, row-y(i)), (x + w + 1.5, row-y(i)), color: color, thickness: 0.8pt, dash: "dashed")
  let brace(x, i0, i1, body, color: navy, w: 30) = {
    let y0 = row-y(i0) + 0.6
    let y1 = row-y(i1) - 0.6
    seg((x, y0), (x, y1), color: color, thickness: 1.1pt)
    label(x + 1.8, (y0 + y1) / 2 - 1.3, w, pos: left, size: 6.7pt, fill: ink, body)
  }
  let lx = 2
  let rx = 78
  let pw = 34
  canvas(150, page-top + page-h + 12.5,
    label(lx, 0, 70, pos: left, weight: "semibold", fill: navy, size: 8.2pt, [Fixed window · `size` 220 / 40]),
    label(lx, 4.2, 70, pos: left, fill: muted, size: 7pt, [A boundary every 220 tokens, wherever it falls]),
    label(rx, 0, 70, pos: left, weight: "semibold", fill: navy, size: 8.2pt, [Structure-aware · `restructure`]),
    label(rx, 4.2, 70, pos: left, fill: muted, size: 7pt, [Boundaries follow titles, articles and paragraphs]),

    node(lx, page-top, pw, page-h, stroke: 0.5pt + hair, radius: 1, []),
    draw-doc(lx, pw),
    cut(lx, pw, 5), cut(lx, pw, 10), cut(lx, pw, 15), cut(lx, pw, 20),
    brace(lx + pw + 3.5, 0, 5, [stops one line into an article], color: faint),
    brace(lx + pw + 3.5, 5, 10, [tail of one article, head of the next], color: faint),
    brace(lx + pw + 3.5, 10, 15, [opens without its own heading], color: faint),
    brace(lx + pw + 3.5, 15, 20, [a definition cut in two], color: faint),

    node(rx, page-top, pw, page-h, stroke: 0.5pt + hair, radius: 1, []),
    draw-doc(rx, pw),
    cut(rx, pw, 3, color: teal), cut(rx, pw, 8, color: teal), cut(rx, pw, 12, color: teal), cut(rx, pw, 18, color: teal),
    brace(rx + pw + 3.5, 0, 3, [title and preamble], color: teal),
    brace(rx + pw + 3.5, 3, 8, [one article, whole], color: teal),
    brace(rx + pw + 3.5, 8, 12, [one article, whole], color: teal),
    brace(rx + pw + 3.5, 12, 18, [one article, whole], color: teal),
    brace(rx + pw + 3.5, 18, 21, [one article, whole], color: teal),

    node(lx, page-top + page-h + 3.5, 70, 8, fill: f-red, stroke: 0.5pt + red.lighten(45%), radius: 1.2,
      text(size: 7pt, [Meaning is split across chunks; a retrieved fragment may lack its own context.])),
    node(rx, page-top + page-h + 3.5, 70, 8, fill: f-teal, stroke: 0.5pt + teal.lighten(45%), radius: 1.2,
      text(size: 7pt, [Each chunk is a unit of meaning and carries its breadcrumb (title, chapter, article) above it.])),
  )
}

// The four governed layers ----------------------------------------------------
#let fig-layers = {
  let row(i, n, title, color, fillc, modules, promise) = {
    let y = 2 + i * 17.2
    node(0, y, 150, 14.6, fill: fillc, stroke: 0.6pt + color.lighten(35%), radius: 1.6, [])
    node(0, y, 31, 14.6, fill: color, stroke: none, radius: 1.6, pos: left + horizon, inset: 2.4, {
      text(fill: paper.transparentize(25%), size: 6.3pt, weight: "semibold", tracking: 0.09em, [LAYER #n])
      linebreak()
      text(fill: paper, weight: "semibold", size: 8.2pt, title)
    })
    at(33.5, y + 2.3, box(width: 71 * u, {
      set par(leading: 0.62em)
      for m in modules {
        box(inset: (x: 1.5mm, y: 0.75mm), radius: 0.9mm, fill: paper, stroke: 0.5pt + color.lighten(55%), baseline: 0.75mm,
          text(size: 6.8pt, fill: ink, m))
        h(1.1mm)
      }
    }))
    label(107, y + 2.6, 41, pos: left, size: 7pt, fill: color.darken(15%), weight: "semibold", promise)
  }
  canvas(150, 71,
    row(0, 4, [Delivery and audit], red, f-red,
      ([`grounded-v1` prompt], [citation gate], [sufficiency commitment], [PII scrub], [audit trail]),
      [A cited answer, or a reasoned refusal]),
    row(1, 3, [Understanding], navy, f-navy,
      ([intent rules], [evidence plan], [sufficiency states], [bounded interrogation], [topic map]),
      [Deterministic first, model second, never twice]),
    row(2, 2, [Knowledge], teal, f-teal,
      ([198 law units], [77 cross-references], [53 number records], [6 governance axes], [unit index]),
      [Declarative data, reviewable line by line]),
    row(3, 1, [Corpus and structure], orange.darken(12%), f-orange,
      ([loader], [restructure], [chunker], [document store], [vector and BM25 store]),
      [A self-describing index that refuses to serve when stale]),
  )
}

// Request lifecycle inside the engine -----------------------------------------
#let fig-lifecycle = {
  let step(x, y, w, n, title, sub, fill: paper, stroke: s-navy, h: 13.5) = {
    node(x, y, w, h, fill: fill, stroke: stroke, nt(title, sub: sub))
    badge(x + 0.4, y + 0.4, n)
  }
  canvas(150, 101,
    // Row 1 — understanding and retrieval
    step(0, 5, 25, 1, [Pre-checks], [token, greeting, private or live request, ingest seal]),
    step(31, 5, 25, 2, [Intent], [declared rules, first match wins]),
    step(62, 5, 25, 3, [Evidence plan], [what must be present to answer]),
    step(93, 5, 25, 4, [Dense retrieval], [original question, pool 20, window 5]),
    step(124, 5, 22, 5, [Sufficiency], [plan against the evidence], fill: f-navy),
    arrow((25, 11.75), (31, 11.75)), arrow((56, 11.75), (62, 11.75)), arrow((87, 11.75), (93, 11.75)), arrow((118, 11.75), (124, 11.75)),

    // Row 2 — the three sufficiency outcomes
    arrow((135, 18.5), (135, 30)),
    arrow((135, 24.5), (15, 24.5), (15, 30)),
    arrow((75, 24.5), (75, 30)),
    node(0, 30, 44, 14, fill: f-teal, stroke: s-teal, nt([Covered], sub: [direct generation, no extra model call], fill: teal.darken(15%))),
    node(53, 30, 44, 14, fill: f-orange, stroke: s-orange, nt([Partly covered], sub: [one bounded regeneration on the covered points], fill: orange.darken(25%))),
    node(106, 30, 40, 14, fill: f-red, stroke: s-red, nt([Nothing covered], sub: [one bounded interrogation, then a new retrieval], fill: red.darken(12%))),
    // the single guided round loops back to retrieval
    arrow((146, 37), (149, 37), (149, 1.7), (105.5, 1.7), (105.5, 5), color: muted, dash: "densely-dashed"),
    label(109, 0.55, 40, pos: left, size: 6.5pt, fill: muted, bg: paper, [once, with the re-expressed question]),

    // Row 3 — generation and verification
    arrow((15, 44), (15, 55)),
    arrow((75, 44), (75, 49.5), (15, 49.5), head: false),
    step(0, 55, 30, 6, [Context assembly], [3,000-token budget, no chunk is ever cut]),
    step(35, 55, 28, 7, [Generation], [strict JSON: claims with evidence]),
    step(68, 55, 32, 8, [Citation gate], [quotes, numbers, policy], fill: f-navy),
    arrow((30, 61.75), (35, 61.75)), arrow((63, 61.75), (68, 61.75)),

    // Outcomes
    node(106, 50, 44, 38, fill: f-red, stroke: s-red, pos: left + top, inset: 2.2, {
      text(weight: "semibold", fill: red.darken(12%), size: 8.2pt, [Reasoned refusal])
      linebreak()
      text(size: 6.9pt, fill: muted, [a stable reason and, where it exists, what is missing])
      v(0.7mm)
      set text(size: 6.4pt, fill: ink)
      set par(leading: 0.5em)
      raw("private_or_live_request\nno_context\nevidence_insufficient\ninsufficient_evidence\nunsourced_number\ninvalid_output")
    }),
    arrow((126, 44), (126, 50), color: red, dash: "dashed"),
    label(128, 45.6, 18, pos: left, size: 6.6pt, fill: red.darken(10%), [still nothing]),
    arrow((100, 61.75), (106, 61.75), color: red, dash: "dashed"),
    label(99.5, 57.6, 7, pos: center, size: 6.6pt, fill: red.darken(10%), [fails]),

    arrow((84, 68.5), (84, 75), color: teal),
    label(86, 70.4, 14, pos: left, size: 6.6pt, fill: teal.darken(15%), [passes]),
    node(0, 75, 100, 13, fill: f-teal, stroke: s-teal, nt([PII scrub, then a cited answer],
      sub: [e-mail, phone, RIB and identity-number patterns are masked; every claim keeps its verbatim quote], fill: teal.darken(15%))),

    node(0, 92.5, 150, 7.5, fill: tint, stroke: 0.5pt + hair, radius: 1.2, {
      text(weight: "semibold", fill: navy, [Audit trail])
      h(2.2mm)
      text(fill: muted, [one JSONL trace per request, answered or refused: status, sufficiency state, model, counters, latency])
    }),
  )
}

// Citation gate ---------------------------------------------------------------
#let fig-gate = {
  let gate(x, n, title, rule, reason) = {
    node(x, 0, 32, 27, fill: f-navy, stroke: s-navy, pos: left + top, inset: 2, {
      text(size: 6.3pt, weight: "semibold", fill: red, tracking: 0.09em, [CHECK #n])
      linebreak()
      text(weight: "semibold", fill: navy, size: 8pt, title)
      v(0.5mm)
      text(size: 6.9pt, fill: ink, rule)
    })
    arrow((x + 16, 27), (x + 16, 34), color: red, dash: "dashed")
    node(x + 1, 34, 30, 7.5, fill: f-red, stroke: 0.5pt + red.lighten(40%), radius: 1.1, text(size: 6.9pt, reason))
  }
  canvas(150, 42,
    node(0, 0, 22, 27, fill: tint, stroke: s-soft, pos: left + top, inset: 2, {
      text(weight: "semibold", fill: navy, size: 8pt, [Model output])
      v(0.5mm)
      text(size: 6.9pt, fill: ink, [Strict JSON: claims, each with evidence items made of a source id and a quote])
    }),
    arrow((22, 13.5), (27, 13.5)),
    gate(27, 1, [Quote membership], [After normalisation, every quote is a contiguous substring of the chunk it cites. Unknown ids are rejected.], [`invalid_output`]),
    arrow((59, 13.5), (63.5, 13.5)),
    gate(63.5, 2, [Numeric gate], [Every number written in digits in a claim appears in that claim's quotes, across digit systems and separators.], [`unsourced_number`]),
    arrow((95.5, 13.5), (100, 13.5)),
    gate(100, 3, [Policy gate], [The source was really retrieved, belongs to the deployed corpus and, where registered, is in force.], [`invalid_output`]),
    arrow((132, 13.5), (136, 13.5), color: teal),
    node(136, 0, 14, 27, fill: f-teal, stroke: s-teal, {
      text(weight: "semibold", fill: teal.darken(15%), size: 8pt, [Scrub])
      linebreak()
      text(size: 6.9pt, fill: muted, [then])
      linebreak()
      text(weight: "semibold", fill: teal.darken(15%), size: 8pt, [answer])
    }),
    label(0, 34.6, 25, pos: left, size: 6.9pt, fill: red.darken(10%), weight: "semibold", [Refusal reason sent to the caller]),
  )
}

// ═════════════════════════════════════════════════════════════════════════════
// Chapter 5 — Bank Assistant
// ═════════════════════════════════════════════════════════════════════════════

#let fig-metering = {
  let st(x, w, title, sub, fill: paper, stroke: s-navy) = node(x, 13, w, 16, fill: fill, stroke: stroke, nt(title, sub: sub))
  canvas(150, 50,
    // lock span
    seg((0, 6.5), (150, 6.5), color: navy, thickness: 0.9pt),
    seg((0, 5), (0, 8), color: navy, thickness: 0.9pt),
    seg((150, 5), (150, 8), color: navy, thickness: 0.9pt),
    label(35, 4.9, 80, pos: center, size: 6.9pt, weight: "semibold", fill: navy, bg: paper, [per-session lock held (64 striped locks, safe for virtual threads)]),

    st(0, 30, [Phase 1 · gate], [new-session limit, then token and message quota], fill: f-navy),
    st(36, 24, [Open exchange], [row written before the call], stroke: s-orange, fill: f-orange),
    st(66, 24, [Engine call], [`POST /answer`], stroke: s-red, fill: f-red),
    st(96, 24, [Sanitise], [provenance, refusal wording]),
    st(126, 24, [Phase 2 · settle], [add real usage, complete the row], fill: f-navy),
    arrow((30, 21), (36, 21)), arrow((60, 21), (66, 21)), arrow((90, 21), (96, 21)), arrow((120, 21), (126, 21)),

    arrow((15, 29), (15, 36.5), color: red, dash: "dashed"),
    node(0, 36.5, 44, 10.5, fill: f-red, stroke: 0.5pt + red.lighten(40%), radius: 1.1,
      text(size: 6.9pt, [Over quota or too many new sessions: `429`, and nothing has been spent])),
    arrow((78, 29), (78, 36.5), color: red, dash: "dashed"),
    node(53, 36.5, 50, 10.5, fill: f-red, stroke: 0.5pt + red.lighten(40%), radius: 1.1,
      text(size: 6.9pt, [Engine unreachable: the open row is closed as `FAILED`, so the failure stays visible])),
    node(110, 36.5, 40, 10.5, fill: tint, stroke: 0.5pt + hair, radius: 1.1,
      text(size: 6.9pt, [Counters and limits travel back with the answer])),
    arrow((138, 29), (138, 36.5), color: faint),
  )
}

#let fig-masking = {
  let item(body, ok: false) = block(above: 0.58em, below: 0pt, grid(
    columns: (3mm, 1fr),
    text(fill: if ok { teal } else { red }, weight: "bold", if ok { sym.checkmark } else { sym.times }),
    text(size: 6.9pt, body),
  ))
  let rule(body) = block(above: 0.62em, below: 0pt, text(size: 6.9pt, body))
  canvas(150, 44,
    node(0, 0, 43, 44, pos: left + top, inset: 2.2, stroke: s-soft, fill: tint, {
      text(weight: "semibold", fill: navy, size: 8pt, [Customer records])
      linebreak()
      text(size: 6.9pt, fill: muted, [PostgreSQL, read-only for the application])
      v(0.5mm)
      item[name, e-mail, phone, address]
      item[national identity number]
      item[IBAN and RIB]
      item[card numbers]
      item[exact balances and amounts]
      item[individual transactions]
      block(above: 1.05em, below: 0pt, text(size: 6.8pt, fill: red.darken(10%), weight: "semibold", [None of these leaves the edge]))
    }),
    arrow((43, 22), (52, 22)),
    node(52, 5, 40, 34, fill: f-navy, stroke: s-navy, pos: left + top, inset: 2.2, {
      text(weight: "semibold", fill: navy, size: 8pt, [Masking at question time])
      rule[Built only for a signed-in customer.]
      rule[Amounts become one of eight bands.]
      rule[Identifiers become counts.]
      rule[Dates become a month.]
      rule[One switch turns the feature off.]
    }),
    arrow((92, 22), (101, 22)),
    node(101, 0, 49, 44, pos: left + top, inset: 2.2, stroke: s-teal, fill: f-teal, {
      text(weight: "semibold", fill: teal.darken(15%), size: 8pt, [Masked block, one request])
      linebreak()
      text(size: 6.9pt, fill: muted, [prepended to the question, never indexed])
      v(0.5mm)
      item(ok: true)[segment, branch and city, KYC status]
      item(ok: true)[number and types of accounts]
      item(ok: true)[total available balance as a band]
      item(ok: true)[number of cards, number blocked]
      item(ok: true)[per financing: product, status, instalment band, instalments left, next month]
      item(ok: true)[number of beneficiaries]
    }),
  )
}

// ═════════════════════════════════════════════════════════════════════════════
// Chapter 7 — security
// ═════════════════════════════════════════════════════════════════════════════

#let fig-trust = canvas(150, 92,
  zone(0, 4, 21, 55, [Untrusted], color: red),
  zone(24, 4, 23, 55, [Edge proxy], color: orange.darken(15%)),
  zone(50, 4, 73, 55, [Private network, no ingress from the Internet], color: navy),
  zone(126, 4, 24, 55, [Third parties], color: muted),

  node(2, 22, 17, 18, nt([Browser], sub: [customer or staff])),
  node(26, 22, 19, 18, fill: f-orange, stroke: s-orange, nt([TLS proxy], sub: [HSTS, rate limit, WAF])),
  node(52.5, 12, 18, 16, fill: tint, nt([nginx], sub: [SPA, headers])),
  node(76.5, 12, 20, 16, fill: f-navy, nt([Edge], sub: [Spring Boot])),
  node(76.5, 38, 20, 14, fill: f-orange, stroke: s-orange, nt([PostgreSQL], sub: [customer data])),
  node(102.5, 12, 18, 16, fill: f-red, stroke: s-red, nt([RAGLab], sub: [corpus, index], fill: red.darken(12%))),
  node(128, 12, 20, 16, nt([Model APIs], sub: [embeddings, answers])),

  arrow((19, 31), (26, 31)),
  arrow((45, 31), (48.5, 31), (48.5, 20), (52.5, 20)),
  arrow((70.5, 20), (76.5, 20)),
  arrow((86.5, 28), (86.5, 38), tail: true),
  arrow((96.5, 20), (102.5, 20)),
  arrow((120.5, 20), (128, 20)),

  badge(22.5, 31, 1), badge(48.5, 25.5, 2), badge(73.5, 20, 3), badge(86.5, 33, 4), badge(99.5, 20, 5), badge(124.3, 20, 6),

  key(0, 64, 75, 1, [TLS terminated at the edge; redirect to HTTPS, HSTS]),
  key(75, 64, 75, 2, [CSP, frame denial, no-sniff, referrer and permissions policies]),
  key(0, 71, 75, 3, [JWT with single-use refresh rotation; roles and permissions]),
  key(75, 71, 75, 4, [One writer; schema validated at boot; check constraints]),
  key(0, 78, 75, 5, [`X-Service-Token`, constant-time check; masked context only]),
  key(75, 78, 75, 6, [Question and retrieved excerpts leave the bank: open item]),
  label(0, 86.2, 150, pos: left, size: 6.7pt, fill: muted, [No customer record is ever written to the retrieval index; the engine keeps no conversation state.]),
)

// ═════════════════════════════════════════════════════════════════════════════
// Chapter 8 — delivery pipeline
// ═════════════════════════════════════════════════════════════════════════════

#let fig-pipeline = {
  let st(x, w, title, sub, fill: paper, stroke: s-navy, y: 8, h: 17) = node(x, y, w, h, fill: fill, stroke: stroke, nt(title, sub: sub))
  canvas(150, 56,
    st(0, 21, [Commit], [clean tree only]),
    st(26, 30, [Continuous integration], [changes, migrations, backend, frontend, optional Sonar], fill: f-navy),
    st(61, 24, [Images], [tagged by commit SHA, never `latest`], fill: f-orange, stroke: s-orange),
    st(90, 17, [Dev], [throwaway data]),
    st(111.5, 17, [Staging], [one-week soak]),
    st(133, 17, [Production], [canary, then ramp], fill: f-teal, stroke: s-teal),
    arrow((21, 16.5), (26, 16.5)), arrow((56, 16.5), (61, 16.5)), arrow((85, 16.5), (90, 16.5)),
    arrow((107, 16.5), (111.5, 16.5)), arrow((128.5, 16.5), (133, 16.5)),

    seg((90, 30.5), (150, 30.5), color: teal, thickness: 0.9pt),
    seg((90, 29), (90, 32), color: teal, thickness: 0.9pt),
    seg((150, 29), (150, 32), color: teal, thickness: 0.9pt),
    label(95, 28.9, 50, pos: center, size: 6.9pt, weight: "semibold", fill: teal.darken(15%), bg: paper, [the same image digests, never rebuilt]),

    node(0, 38, 46, 15, fill: tint, stroke: 0.5pt + hair, radius: 1.2, pos: left + horizon, inset: 2,
      text(size: 6.9pt, [*Migrations job.* The whole Flyway chain is applied to a real PostgreSQL 16 on every relevant push.])),
    node(52, 38, 46, 15, fill: tint, stroke: 0.5pt + hair, radius: 1.2, pos: left + horizon, inset: 2,
      text(size: 6.9pt, [*Promotion is a script.* It refuses a dirty tree and the target only pulls the tag it is given.])),
    node(104, 38, 46, 15, fill: tint, stroke: 0.5pt + hair, radius: 1.2, pos: left + horizon, inset: 2,
      text(size: 6.9pt, [*Verification.* The running containers must report the commit that was promoted.])),
  )
}

// ═════════════════════════════════════════════════════════════════════════════
// Chapter 6 — charts
// ═════════════════════════════════════════════════════════════════════════════

#let c-base = faint.lighten(15%)
#let c-main = navy
#let hits = ([hit\@1], [hit\@3], [hit\@5])

#let panel(title, chart) = block(breakable: false, {
  align(left, text(font: sans, size: 8pt, weight: "semibold", fill: navy, title))
  v(-0.55em)
  chart
})

#let two-up(left-panel, right-panel) = grid(columns: (72mm, 72mm), column-gutter: 6mm, left-panel, right-panel)

#let chart-chunking = two-up(
  panel([Offline stage · BM25 only, k = 20], barchart(
    hits, (([`size`], c-base), ([`restructure`], c-main)),
    ((42, 62), (60, 82), (62, 87)), w: 72, h: 50,
  )),
  panel([Live stage · dense retrieval, real models], barchart(
    hits, (([`size`], c-base), ([`restructure`], c-main)),
    ((51, 71), (64, 80), (71, 87)), w: 72, h: 50,
  )),
)

#let chart-modes = two-up(
  panel([All 45 evaluable questions], barchart(
    hits, (([`vector`], c-main), ([`rrf`], orange), ([`blend`], c-base)),
    ((71, 71, 62), (80, 80, 80), (87, 82, 84)), w: 72, h: 50,
  )),
  panel([French questions only], barchart(
    hits, (([`vector`], c-main), ([`rrf`], orange), ([`blend`], c-base)),
    ((50, 33, 33), (67, 33, 33), (67, 50, 67)), w: 72, h: 50,
  )),
)

#let langs = ([Arabic], [English], [French])
#let chart-language = two-up(
  panel([hit\@1 by question language], barchart(
    langs, (([`size`], c-base), ([`restructure`], c-main)),
    ((47, 70), (67, 89), (50, 50)), w: 72, h: 50,
  )),
  panel([hit\@5 by question language], barchart(
    langs, (([`size`], c-base), ([`restructure`], c-main)),
    ((67, 90), (89, 89), (67, 67)), w: 72, h: 50,
  )),
)

#let chart-units = two-up(
  panel([Unit index · the 12 law questions], barchart(
    hits, (([structural chunks], c-base), ([unit index], teal)),
    ((67, 100), (92, 100), (92, 100)), w: 72, h: 50,
  )),
  panel([Target categories · 10 Arabic cases], barchart(
    ([compound], [implicit], [ambiguous], [synonyms], [colloquial]),
    (([hit\@1], c-main), ([hit\@5], orange)),
    ((100, 100), (50, 100), (50, 100), (50, 50), (0, 0)), w: 72, h: 50, bar-w: 4.4, group-size: 6.5pt,
  )),
)

#let chart-models = stackedbars(
  (
    ([`qwen3.8-max` (pinned)], (37, 6, 7, 0)),
    ([`kimi-k3` (comparison)], (27, 7, 7, 9)),
  ),
  (
    ([Answered], navy, paper),
    ([Other refusals], c-base, ink),
    ([Refused by the citation gate], orange, ink),
    ([Provider error], red, paper),
  ),
  w: 150, ml: 36,
)
