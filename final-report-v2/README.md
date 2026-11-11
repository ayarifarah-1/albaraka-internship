# Internship report — A Governed Intelligence for Islamic Banking

The internship report of Farah AYARI (Software Engineering, ESPRIT), carried
out at Al Baraka Bank Tunisia in the academic year 2025–2026. It presents the
design, construction and evaluation of the integrated **RAGLab** (retrieval-
augmented generation engine) and **Bank Assistant** (web platform) system.

The finished document is
[`Farah_Ayari_Internship_Report_v2.pdf`](Farah_Ayari_Internship_Report_v2.pdf)
(64 pages, A4, with bookmarks and PDF metadata). It supersedes the earlier
draft in `../final-report/`.

## Building

```bash
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
python build.py            # writes Farah_Ayari_Internship_Report_v2.pdf
python build.py --preview  # also renders every page to build/pages/ for checking
```

`build.py` drives the Typst compiler over `src/main.typ`. All fonts are
vendored under `fonts/` (SIL Open Font License, see `fonts/licenses/`), so the
output is identical on every machine and needs no network access. All
diagrams and charts are drawn natively as Typst vector graphics; the only
raster images are the two institutional logos in `assets/`.

## Layout

```
build.py            build script (compile + optional page previews)
fonts/              vendored OFL fonts and their licences
assets/             ESPRIT and Al Baraka logos
src/
  main.typ          entry point: metadata, cover, front matter, body, back matter
  figures.typ       the 20 figures and charts, drawn as vectors
  lib/
    theme.typ       design system: template, callouts, tables, lists
    draw.typ        vector-drawing kit used by figures.typ
  front/
    cover.typ       title page
    preliminaries.typ  dedication, acknowledgements, abstracts (EN/FR/AR),
                       contents, lists of figures, tables and listings,
                       abbreviations
  chapters/         00 introduction, 01–08 chapters, 09 conclusion
  back/
    refs.yml        bibliography (Hayagriva data)
    references.typ  IEEE-style reference list
    appendices.typ  A glossary, B technical environment and provenance,
                    C reproducing the results, D database migrations
```

## Conventions

- Every number in the report comes from the two project repositories; the
  provenance of the main figures is tabulated in Appendix B.
- The report contains no account identifier, repository address or credential.
- The text is set in Source Serif 4 with Noto Naskh Arabic as the Arabic
  fallback; headings and tables use Source Sans 3.
