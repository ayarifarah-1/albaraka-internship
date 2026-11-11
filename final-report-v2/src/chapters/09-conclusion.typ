#import "../lib/theme.typ": *

// Sections of an unnumbered chapter carry no number.
#set heading(numbering: none, outlined: false)

#heading(level: 1, outlined: true)[General conclusion and perspectives]

#lead[The internship set out to make a language model answerable for what it says. The result is a system that cites, doubts, refuses and traces, together with an exact account of where its guarantees stop.]

== Assessment

The internship produced a complete, measured and documented question-answering platform that works today on a real Arabic banking corpus. The table below confronts the objectives of @ch-context with what was delivered.

#block(above: 1.3em, below: 1.5em, dtable(
  columns: (9mm, 43mm, 1fr),
  header: ([N°], [Objective], [Result]),
  [O1], [A complete chain on the real documents], [Delivered: repair, structural chunking, embedding, local index, dense and lexical retrieval, grounded generation, verification],
  rowline,
  [O2], [Accessible, reproducible models and measured comparisons], [Delivered: one pinned pair of models with no fallback; every default chosen by a paired measurement],
  rowline,
  [O3], [Refusal as a first-class behaviour], [Delivered: six stable reasons, refusal before generation when nothing covers the question, the bank's own wording for customers],
  rowline,
  [O4], [The engine as an integrated service under a stable contract], [Delivered: 27 routes, version 1.5.0, frozen and additive contract, consumed by the web platform as its single answering path],
  rowline,
  [O5], [Instrumented quality], [Delivered: 472 unit tests and 133 offline checks on the engine, 214 tests on the web platform, frozen question sets, audit trail],
  rowline,
  [O6], [A trilingual assistant for customers, a console for staff], [Delivered: public chat and portal in three languages; monitoring with full provenance; a five-tab console for the engine],
  rowline,
  [O7], [No customer record in the retrieval index], [Delivered by construction: a masked view derived per question and never indexed. The transfer of the question itself to external providers remains open],
))

Four measured results summarise the technical contribution: 20 points of hit\@1 gained by structure-aware chunking, from 51 % to 71 %; a knowledge-unit index that places every question about the law at rank 1; two different answer models that cite identical sources when the context is fixed; and six adversarial scenarios out of six rejected by a citation gate that involves no model.

== Lessons

#callout(kind: "lesson", title: [Measurement replaces opinion])[
  Every structuring choice was settled by paired figures: structural chunking rather than a fixed window, dense retrieval rather than fusion, the lexicon left off, relational expansion abandoned. Several reasonable intuitions, among them the common recommendation of hybrid retrieval, were rejected by the data.
]

#callout(kind: "lesson", title: [The governance of decisions is part of the architecture])[
  The step-and-plan protocol, the activation switches and the frozen question sets are not bureaucracy. They are what allowed a project interrupted several times to be resumed without silent regression, and what distinguishes progress from a displacement of the problem.
]

#callout(kind: "lesson", title: [Reality is the only judge])[
  The most serious defects were invisible in the tests and obvious in operation: a guided search that never ran in the deployed service, a French question misclassified by one letter, an index doubled by duplicates, a production build that signed visitors in. Any statement about the system must be verified on the system.
]

#callout(kind: "lesson", title: [Boundaries carry the guarantees])[
  Most properties of the platform come from where a responsibility was placed rather than from how it was coded: one writer on the database, one answering engine, customer data that never crosses into the index, provenance that stops at the edge. When a boundary was blurred, as with two engines side by side, behaviour came to depend on a setting.
]

== Limits

The limits have been stated where they apply and are gathered here. The citation gate verifies that words and numbers come from the source, not that a claim follows from them. Retrieval has no similarity threshold: safety rests on sufficiency and refusal. The engine is a single process without conversational memory, and a replaced document keeps serving its old chunks until the next indexing run. The question sets are small and were written by the project. The personal-data gaps of @ch-security are open. The platform is suited to a supervised pilot.

== Perspectives

*Before any pilot with customers.* Close the high-severity items of @ch-security: scrubbing on the input side before a question leaves the bank, a retention policy, masking of network addresses, a mandatory service token, and a contractual and legal decision on the external providers. Hosting the embedding and answer models inside the bank's network would remove the last of these at its root, at the price of the hardware the project did not have.

*For the engine.* Add topical metadata to chunks (path, level, parent) in an isolated collection; measure topical and faceted retrieval arms on the same frozen sets; then run a closing campaign that re-measures every arm before any default changes. Two further steps would extend the guarantees themselves: a verification of entailment between a claim and its quotation, and an independent, larger evaluation set written by domain experts of the bank.

*For the web platform.* Feed the governed facts into the answering path, so that a figure stated by the bank outranks a document in an answer as it already does in the simulator. Run the database tests on a real PostgreSQL, bring the end-to-end smoke test into a scheduled job, and add a start-up assertion on production secrets.

*For industrialisation.* Multi-tenancy with document filtering by role, incremental updating of the index, conversational memory under the same verification rules, metrics and tracing on the engine, and continuous adversarial evaluation.

== Personal assessment

This internship was an apprenticeship in a way of working as much as in a set of techniques. On the technical side it covered the whole chain of a retrieval-augmented system on Arabic text, the design of a versioned HTTP contract between two teams, a secured Spring Boot service with its schema migrations, and an Angular application in three languages. On the methodological side it taught me to write the plan before the code, to freeze what is being measured, to state a limit in the same sentence as a result, and to treat a refusal as a feature to be designed rather than as a failure to be hidden.

Working in a bank changed my understanding of what "done" means. A feature is not finished when it answers correctly in a demonstration; it is finished when someone other than its author can verify what it did, on what evidence, and why it declined to do more.
