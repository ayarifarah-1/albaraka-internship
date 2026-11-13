#import "../lib/theme.typ": *

#counter(heading).update(0)
#set heading(numbering: "A.1", supplement: [Appendix])

= Glossary <app-glossary>

#lead[Terms of Islamic banking, of the Arabic corpus and of retrieval-augmented generation, as they are used in this report.]

#block(above: 1.2em, dtable(
  columns: (30mm, 23mm, 1fr),
  pad: 3.7pt,
  header: ([Term], [Arabic], [Meaning in this report]),
  table.cell(colspan: 3, fill: tint.lighten(40%), overline-label([Islamic banking], fill: muted, size: 7pt)),
  [Mourabaha], ar[المرابحة], [Sale at cost plus a margin known to the buyer],
  rowline,
  [Ijara], ar[الإجارة], [Lease of an asset, possibly with an option to purchase],
  rowline,
  [Moudaraba], ar[المضاربة], [Partnership between a provider of capital and a manager],
  rowline,
  [Moucharaka], ar[المشاركة], [Partnership in which all parties contribute capital],
  rowline,
  [Istisna'a], ar[الاستصناع], [Order to manufacture or build an asset to specification],
  rowline,
  [Salam], ar[السلم], [Sale paid in advance for goods delivered later],
  rowline,
  [_Al-ṣīgha_], ar[الصيغة], [The contractual form of an operation],
  table.cell(colspan: 3, fill: tint.lighten(40%), overline-label([Corpus and governance], fill: muted, size: 7pt)),
  [_ʿUnwān_, _bāb_, _faṣl_], ar[العنوان، الباب، الفصل], [Title, chapter and article: the three levels of the law's hierarchy],
  rowline,
  [_Nāfidh_], ar[نافذ], [In force: the validity status required of a cited document],
  rowline,
  [_Kāfin_], ar[كافٍ], [Sufficient: the evidence plan of the question is covered],
  rowline,
  [_Ghayr kāfin_], ar[غير كافٍ], [Insufficient: required evidence is missing],
  rowline,
  [_Mutaʿāriḍ_], ar[متعارض], [Conflicting: two sources disagree],
  rowline,
  [_Ghayr maḥsūm_], ar[غير محسوم], [Undetermined: the state could not be settled],
  table.cell(colspan: 3, fill: tint.lighten(40%), overline-label([Retrieval-augmented generation], fill: muted, size: 7pt)),
  [Chunk], [], [A fragment of a document, the unit that is embedded, indexed and cited],
  rowline,
  [Embedding], [], [Vector that represents a text in a space where proximity reflects meaning],
  rowline,
  [hit\@k], [], [Share of questions whose expected passage is among the first k results],
  rowline,
  [BM25], [], [A classical lexical ranking function of information retrieval],
  rowline,
  [RRF], [], [Reciprocal rank fusion: a merge of several ranked lists based on ranks alone],
  rowline,
  [Knowledge unit], [], [One article of the law with a stable identifier, independent of chunking],
  rowline,
  [Evidence plan], [], [What must be present in the retrieved text for a question to be answerable],
  rowline,
  [Sufficiency], [], [The confrontation of the evidence plan with what was actually retrieved],
  rowline,
  [Citation gate], [], [The deterministic check of quotations, numbers and source policy],
  rowline,
  [Interrogation], [], [The single bounded model call that re-expresses an uncovered question],
  rowline,
  [Edge], [], [The Spring Boot service through which every request of the web platform passes],
  rowline,
  [Governed fact], [], [A statement of the bank about its products, stored with a reason and an audit trail],
  rowline,
  [Masked context], [], [The banded, identifier-free view of a customer's situation sent with a question],
))

= Technical environment and provenance of the figures <app-provenance>

== Technical environment

#tab(
  dtable(
    columns: (30mm, 1fr),
    header: ([Component], [Versions]),
    [Engine], [Python 3.11; FastAPI 0.141.1 with uvicorn 0.52.4; ChromaDB 1.5.9; pypdf 6.17.0; tiktoken 0.14.0],
    rowline,
    [Models], [One pinned embedding model with 2,048 dimensions and one pinned answer model, both reached through their providers' APIs, with no fallback],
    rowline,
    [Edge], [Java 21; Spring Boot 4.1.0; Flyway migrations V1 to V15],
    rowline,
    [Database], [PostgreSQL 16],
    rowline,
    [Web application], [Angular 21 with standalone components; Vitest; nginx as web tier],
    rowline,
    [Delivery], [Docker and Docker Compose; GitHub Actions: eight workflows on the engine, five jobs on the web platform],
    rowline,
    [This report], [Typeset with Typst @typst; all diagrams and charts are drawn natively as vector graphics],
  ),
  caption: [Technical environment of the project.],
) <tab-environment>

== Size of the two code bases

#tab(
  dtable(
    columns: (38mm, 1fr, 1fr),
    header: ([], [Engine (RAGLab)], [Web platform (Bank Assistant)]),
    [History], [376 integrated commits], [255 commits],
    rowline,
    [Source code], [86 Python modules, about 40,800 lines], [164 Java files and 14,637 lines, tests included; 9,369 lines of TypeScript, tests excluded; 5,039 lines of HTML and 7,134 of CSS],
    rowline,
    [Interfaces], [27 HTTP routes], [16 controllers on the edge; 18 screens behind 32 routes],
    rowline,
    [Automated tests], [472 unit tests and 133 offline checks], [123 tests in 24 classes on the edge; 91 tests in 20 files on the web application],
    rowline,
    [Documentation], [68 Markdown documents], [30 Markdown documents],
  ),
  caption: [Size of the two code bases at the end of the internship.],
) <tab-size>

== Where each figure comes from

Every number of this report is taken from the repositories of the project. @tab-provenance gives the source of the main ones, so that each can be checked.

#tab(
  dtable(
    columns: (1fr, 1fr),
    header: ([Figure], [Source in the repositories]),
    table.cell(colspan: 2, fill: tint.lighten(40%), overline-label([Engine], fill: muted, size: 7pt)),
    [4 documents, 339 chunks; repairs 215, 35, 23 and 21], [Master index of the audits; repair logs of each document],
    rowline,
    [50 questions (10, 20, 15, 5) and 10 target cases], [The two question files; the question matrix of the audits],
    rowline,
    [Chunking 42/60/62 #sym.arrow.r 62/82/87 offline and 51/64/71 #sym.arrow.r 71/80/87 live; modes; breakdowns by language and category], [Baseline audit of the measurement phase],
    rowline,
    [Agreement 0.720 and Jaccard 1.000], [Baseline audit, answer-comparison run],
    rowline,
    [Unit index 100/100/100 against 67/92/92; 198 units, 77 relations, 53 number records, 6 axes], [Knowledge-layer audit],
    rowline,
    [Target categories; lexicon without effect], [Interventions audit],
    rowline,
    [Final campaign: 5 of 7; 4 of 5 #sym.arrow.r 5 of 5; 3 answers and 3 refusals], [Structure audit of the last phase],
    rowline,
    [27 routes, version 1.5.0], [Service module, counted route by route; service contract],
    rowline,
    [472 unit tests, 133 offline checks, 8 workflows, 469 harness families], [Test modules and workflow files, counted; full project report],
    table.cell(colspan: 2, fill: tint.lighten(40%), overline-label([Web platform], fill: muted, size: 7pt)),
    [Quotas, locks, time-outs, order of the chat path], [Chat controller and engine client, read in the code],
    rowline,
    [9 permissions, 4 predefined roles, check constraints], [Permission codes class; migrations V14 and V15],
    rowline,
    [8 balance bands; content of the masked block], [Customer-context service, read in the code],
    rowline,
    [Polling 28,800 #sym.arrow.r 4,320 #sym.arrow.r 0 requests per day], [Project report of the web platform, console section],
    rowline,
    [Code size, tests, screens and routes, commits], [Inventory of the repository at its final state],
    rowline,
    [Personal-data gaps and severities], [Customer personal-data report],
    rowline,
    [Alerts and launch plan], [Deployment guide],
  ),
  caption: [Provenance of the main figures of the report.],
  breakable: true,
) <tab-provenance>

Where two documents of the project disagreed, the code was taken as the reference. Three such cases were met: the number of routes, of tests and of workflows, which older documents give for earlier versions of the engine; the place of output scrubbing, which is in the engine and not at the edge; and the content of the masked block, which does not include the language or the risk grade although one document lists them.

= Reproducing the results <app-reproduction>

#lead[Commands that rebuild the results; paths are relative to the root of each repository.]

== The engine

#lst(
  ```bash
  # Environment
  cd raglab
  python3 -m venv .venv && source .venv/bin/activate
  pip install -r requirements.txt

  # Complete offline gate: compilation, unit tests, offline checks (no model call)
  ./run_tests.sh --offline

  # Index the real corpus, then ask a question (requires the provider keys)
  python main.py inspect --data-dir ../docs
  python main.py ingest --reset --data-dir ../docs
  python main.py answer "<question>" --query-lang ar

  # HTTP service, then the integration bench that speaks to it as the edge does
  python -m uvicorn service:app
  python local_front.py --base-url http://localhost:8000
  ```,
  caption: [Rebuilding and running the engine.],
) <lst-repro-engine>

== The web platform

#lst(
  ```bash
  # The three services of the platform; the engine is addressed by RAGLAB_URL
  cp .env.example .env            # then set the secrets and RAGLAB_URL
  docker compose up --build       # the site is served on port 8080

  # Tests
  cd backend  && mvn -B verify
  cd frontend && npm ci && npm test -- --watch=false && npm run build

  # Which commit is running?
  ./deploy/promote.sh --verify http://localhost:8081 http://localhost:8080
  ```,
  caption: [Running and verifying the web platform.],
) <lst-repro-web>

== This report

This document is rebuilt from the sources stored next to it: `python build.py` writes the PDF, and the option `--preview` also renders every page to an image. Only the fonts kept with the sources are used, so the result is identical on every machine.

= Database migrations <app-migrations>

#lead[The schema of the web platform is the result of fifteen migrations applied in order. The history is append-only: a migration, once released, is never edited.]

#tab(
  dtable(
    columns: (16mm, 1fr),
    header: ([Version], [Purpose]),
    [V1], [Baseline: conversations, messages, documents, staff users, customers, accounts, cards, movements],
    rowline,
    [V2], [Governed business facts and their audit],
    rowline,
    [V3], [Taxonomy catalogue],
    rowline,
    [V4], [Refresh tokens],
    rowline,
    [V5], [Error text of ingestion],
    rowline,
    [V6], [Catalogue overview intent],
    rowline,
    [V7], [Monitoring and service exemplars],
    rowline,
    [V8], [Customer portal],
    rowline,
    [V9], [Advisor requests],
    rowline,
    [V10], [News],
    rowline,
    [V11], [Engine administration],
    rowline,
    [V12], [Engine table],
    rowline,
    [V13], [Real-time observability of the chat],
    rowline,
    [V14], [Staff roles and permissions],
    rowline,
    [V15], [Customer model shaped like a core-banking extract: branches, beneficiaries, financings, account types, cards],
  ),
  caption: [The fifteen migrations of the web platform.],
) <tab-migrations>

Migrations V11 and V12 date from the period in which two answering engines coexisted. They remain in the chain after the consolidation because the history is append-only.
