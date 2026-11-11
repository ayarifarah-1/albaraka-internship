#import "../lib/theme.typ": *
#import "../figures.typ": *

= Architecture of the platform <ch-architecture>

#lead[Two systems with one boundary between them: an edge that owns identity, state and governance, and an engine that owns retrieval, grounding and generation.]

== Overall view

The platform is composed of three deployable services of the web application (a database, an edge service and a web tier) and of one external service, the engine (@fig-architecture). The division is strict, and most of the properties claimed in this report follow from it.

#fig(fig-architecture, caption: [End-to-end architecture of the platform. Solid frames are services; dashed frames are trust zones.]) <fig-architecture>

*The web tier* is an nginx server that delivers the Angular single-page application and proxies every call under `/api` to the edge. Because the browser only ever talks to this origin, there is no cross-origin request at all. The same server sets the browser-hardening headers and disables response buffering so that streamed answers reach the user as they are produced.

*The edge* is a Spring Boot service. It authenticates users, enforces roles and permissions, meters every session, persists every exchange, rewrites what a customer is allowed to read, and exposes the administration API. It is the only component that writes to the database.

*The database* is PostgreSQL. Its schema is owned by versioned migrations; the application validates the schema at start-up and never alters it.

*The engine*, RAGLab, is a separate FastAPI service addressed by its network location and authenticated by a shared service token. It retrieves, decides whether the evidence suffices, generates a grounded answer, verifies it and records an audit trace. It owns its own index and its own document store, keeps no conversation state and stores nothing in the bank's database.

*The model providers* are reached only by the engine: one pinned embedding model and one pinned answer model, with no fallback. A different model produces an explicit error rather than a silent degradation.

== Who owns what

#tab(
  dtable(
    columns: (38mm, 1fr, 1fr),
    header: ([Concern], [Edge (Bank Assistant)], [Engine (RAGLab)]),
    [Identity and roles], [Customers, staff, roles, permissions, tokens], [None: one shared service token],
    rowline,
    [Conversation state], [Sessions, exchanges, history, counters], [None: each question is answered on its own],
    rowline,
    [Customer data], [Stores it; derives a masked view per question], [Never stores it and never indexes it],
    rowline,
    [Documents and index], [None; operated through console actions], [Document store, chunks, vectors, fingerprints],
    rowline,
    [Answer], [Sanitises it for customers; keeps the trace for staff], [Produces it with claims, quotes and a status],
    rowline,
    [Refusal], [Substitutes the bank's own wording], [Decides it and names the reason],
    rowline,
    [Quotas and abuse], [Token and message quotas, new-session limit], [None],
    rowline,
    [Audit], [Every exchange, every access-control change], [Every request, with its sufficiency state],
  ),
  caption: [Division of responsibilities between the edge and the engine.],
) <tab-ownership>

This division was not the starting point. The first version of the web application contained its own answering service, written in Python, which also wrote to the database. That arrangement meant two writers on one schema and, later, two answering engines side by side with two corpora, two sets of indicators and two refusal wordings. The consolidation that removed the in-house service and left RAGLab as the single serving path is the largest structural decision of the project; @sec-decisions records it with its cost.

== The life of a question <sec-life>

@fig-sequence follows one customer question from the browser to the engine and back.

#fig(fig-sequence, placement: auto, caption: [Sequence of one customer question. Solid arrows are requests, dashed arrows are responses.]) <fig-sequence>

+ The application posts the message with a session identifier and a language, either to the synchronous endpoint or to its streaming twin.
+ The edge takes a per-session lock and runs the admission gate: the limit on new anonymous sessions per address, then the token and message quota of the session. A request that fails the gate is rejected before anything has been spent on the engine.
+ The edge opens the exchange row. A supervisor therefore sees a conversation from its first message, and a failure remains visible even when no answer is ever produced.
+ For a signed-in customer, the edge derives a masked view of that customer's banking situation at that moment (@ch-assistant).
+ The edge calls the engine's answer endpoint with the service token.
+ The engine retrieves, checks sufficiency, generates, verifies the citations and scrubs personal-data patterns from its output (@ch-raglab).
+ The engine returns a status, the answer text, the claims with their quotations, and the sources.
+ The edge removes all provenance from the text shown to a customer, or, for a refusal, substitutes the bank's own wording for the engine's sentence.
+ The edge completes the exchange row with the result, the trace and the latency, and settles the usage of the session.
+ The response returns to the browser. On the streaming endpoint it takes the form of server-sent events: one `delta` frame carrying the answer, then a `done` frame carrying the counters. The engine answers in one piece, so the stream has a single delta.

== Governance principles

Five rules hold across the platform. Each is enforced by a mechanism rather than by convention.

/ Refuse rather than guess: The engine refuses before generation when nothing covers the question, and after generation when a citation or a number cannot be verified. The edge adds no content of its own to an answer.
/ One writer: Only the edge writes to the bank's database. The engine returns data and persists nothing there.
/ The bank's own figures are governed data: A profit rate or a contact detail is never written into code or left to a document. It lives in a store where every modification requires a reason and leaves an audit row, and a feature that depends on it shows nothing when the fact is absent.
/ No customer data in the index: Customer records are never indexed. What the engine may receive is a masked context derived at the moment of the question, with a lifetime of one request.
/ Provenance for staff, never for customers: A customer reads an answer; a member of staff reads the same answer with its claims, its verbatim quotations and its sources.

== Structuring decisions <sec-decisions>

Each of the decisions in @tab-decisions was a fork in the road, and each is recorded with what it cost.

#tab(
  dtable(
    columns: (35mm, 1fr, 1fr),
    header: ([Decision], [Reason], [Cost accepted]),
    [One serving engine], [Two engines meant two corpora, two index worlds, two sets of indicators and a selector that made behaviour depend on a setting], [The in-house service, its queue and its screens were removed; two migrations remain in the append-only history],
    rowline,
    [No customer data in the retrieval index], [A shared index holding customer data is a cross-customer leak waiting for a retrieval bug], [Questions that would need a lookup are refused more often; a refusal is cheap, a leak is not],
    rowline,
    [Roles for staff only, granted by the general manager alone], [A permission system that customers can reach has a second, unowned boundary], [A dedicated screen with two enforced constraints],
    rowline,
    [Development fixtures only behind a flag], [A known password in a live database is the cheapest way to lose it], [Fixtures are not a migration and must be enabled explicitly],
    rowline,
    [French back office, trilingual customer surface], [Language is a product requirement for customers, not for staff working in one language], [Eleven administrative screens are not translated],
    rowline,
    [Governed facts for the bank's own figures], [A circular and an internal guide can disagree about a rate; the bank needs a place to state what holds today, with a name and a reason attached], [A second source of truth to maintain; it feeds the edge's own features and is not yet injected into engine answers],
    rowline,
    [The console is a product, not a debug page], [An operator must learn in two minutes whether the engine can answer and whether its corpus is current], [A redesign and a rewrite of the status polling (@ch-assistant)],
  ),
  caption: [Structuring decisions of the platform, with their reasons and their costs.],
) <tab-decisions>
