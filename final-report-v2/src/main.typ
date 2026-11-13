// ─────────────────────────────────────────────────────────────────────────────
// Internship report — Farah AYARI — ESPRIT / Al Baraka Bank Tunisia — 2025–2026
// Entry point. Build with:  python build.py
// ─────────────────────────────────────────────────────────────────────────────
#import "lib/theme.typ": *

#let meta = (
  title: "A Governed Intelligence for Islamic Banking: The Integrated RAGLab and Bank Assistant Platform",
  author: "Farah AYARI",
  keywords: (
    "retrieval-augmented generation", "Islamic banking", "grounded answers", "citation verification",
    "Arabic NLP", "Spring Boot", "Angular", "AI governance", "internship report",
  ),
  running: [A Governed Intelligence for Islamic Banking],
  footer: [Farah AYARI #h(0.45em) #sym.dot.c #h(0.45em) Internship report #h(0.45em) #sym.dot.c #h(0.45em) 2025–2026],
)

#show: report.with(meta: meta)

// ── Cover (no page number) ───────────────────────────────────────────────────
#include "front/cover.typ"

// ── Front matter (roman numerals) ────────────────────────────────────────────
#set page(numbering: "i")
#counter(page).update(1)
#include "front/preliminaries.typ"

// ── Body (arabic numerals) ───────────────────────────────────────────────────
#set page(numbering: "1")
#counter(page).update(1)
#include "chapters/00-introduction.typ"
#include "chapters/01-context.typ"
#include "chapters/02-background.typ"
#include "chapters/03-architecture.typ"
#include "chapters/04-raglab.typ"
#include "chapters/05-bank-assistant.typ"
#include "chapters/06-evaluation.typ"
#include "chapters/07-security.typ"
#include "chapters/08-operations.typ"
#include "chapters/09-conclusion.typ"

// ── Back matter ──────────────────────────────────────────────────────────────
#include "back/references.typ"
#include "back/appendices.typ"
