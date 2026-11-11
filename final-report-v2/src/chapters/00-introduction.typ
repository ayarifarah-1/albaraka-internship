#import "../lib/theme.typ": *

// Sections of an unnumbered chapter carry no number and stay out of the contents.
#set heading(numbering: none, outlined: false)

#heading(level: 1, outlined: true)[General introduction]

#lead[A language model always answers. \ A bank needs a system that knows when it must not.]

Banks produce and consume a large body of regulatory and procedural text: laws, central-bank circulars, internal guides, training material. Finding a reliable piece of information in these documents is costly, and handing the task to a raw language model is dangerous. A generative model answers even when it does not know, and nothing in its output distinguishes a sentence copied from a source from a sentence it invented. In a regulated environment the consequence is concrete: a wrong statement about a rate, a deadline or a sanction is a legal risk for the institution that made it.

The internship reported here was carried out at Al Baraka Bank Tunisia during the academic year 2025–2026. Its subject was the design and integration of a governed question-answering system for banking knowledge, and it produced a platform made of two cooperating systems:

- *RAGLab*, a retrieval-augmented generation engine that answers only from a corpus of four real Arabic banking documents and that can prove, quote by quote, what each answer rests on;
- *Bank Assistant*, a trilingual web platform through which customers ask their questions and through which the bank's staff supervise, audit and operate the assistant.

== Three commitments

The whole project is organised around three commitments, which recur in every chapter.

+ *Traceability.* Every claim in an answer is backed by a verbatim extract of the cited document, and every number stated in a claim appears in that extract.
+ *Honest refusal.* When the evidence is missing, the system refuses to answer and explains what is missing, instead of producing a plausible reply. A refusal is treated as a valid result, not as a failure.
+ *Measurement.* No architectural choice, whether a chunking strategy, a model, a retrieval mode or a default setting, is adopted without a reproducible comparison and an explicit decision rule.

== Contributions

The work delivered the following results, each of which is described and measured in the body of the report.

- A complete document pipeline on real Arabic sources: loading and linguistic repair of the texts, structure-aware chunking, embedding, a local vector index, dense and lexical retrieval, grounded generation and verification.
- A deterministic verification layer, made of an evidence-sufficiency check that decides whether the engine may answer at all and a citation gate that checks quotes, numbers and source policy after generation.
- A knowledge layer built on the banking law: 198 stable knowledge units, 77 cross-references, 53 structured number records and six governance axes, all stored as reviewable data.
- An HTTP service of 27 routes under a frozen, versioned contract, with an audit trail and output scrubbing of personal data.
- A web platform in which a single edge service owns identity, quotas, persistence and audit, exposes a trilingual customer surface and a staff console, and passes to the engine nothing more than a masked view of a customer's situation.
- A measurement discipline, with frozen question sets, paired comparisons and activation gates, whose results are reported together with the limits of what they prove.

== Organisation of the report

The report is organised by ideas rather than by chronology. @ch-context presents the host organisation, the regulatory setting, the business problem and the working method. @ch-background situates the technical choices within the state of the art of retrieval-augmented generation. @ch-architecture describes the architecture of the platform as a whole and the path of a question through it. @ch-raglab details the engine, layer by layer, and @ch-assistant details the web platform. @ch-evaluation reports the measurements. @ch-security examines security, privacy and compliance, including the items that remain open. @ch-operations covers deployment, operations and the defects that only real use revealed. The general conclusion assesses the result and sets out the perspectives.
