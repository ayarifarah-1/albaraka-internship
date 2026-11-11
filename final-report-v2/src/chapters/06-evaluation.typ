#import "../lib/theme.typ": *
#import "../figures.typ": *

= Evaluation and quality assurance <ch-evaluation>

#lead[Every default of the system was chosen by a paired measurement on frozen question sets. This chapter reports the measurements, the decisions they led to, and what they do not prove.]

#kpis((
  ([+20 pts], [hit\@1 gained by structure-aware chunking on the live arm]),
  ([100 %], [of law questions at rank 1 on the knowledge-unit index]),
  ([1.000], [overlap of cited sources between two answer models]),
  ([6 / 6], [adversarial scenarios rejected by the citation gate]),
))

== Corpus and question sets

The evaluation corpus is the one described in @ch-raglab: four real documents, repaired and adopted, giving 339 chunks on the structural arm. Two question sets are frozen and versioned with the code (@tab-sets).

#tab(
  dtable(
    columns: (30mm, 30mm, 1fr),
    header: ([Set], [Size], [Composition]),
    [Main set], [50 questions, of which 45 can be evaluated], [10 verbatim, 20 paraphrases, 15 cross-lingual (6 French, 9 English) and 5 out of scope; 32 questions in Arabic, 8 in French, 10 in English; 12 on the law, 10 on the circular, 11 on the guide, 12 on the primer],
    rowline,
    [Target set], [10 Arabic questions], [Two per difficulty: colloquial wording, synonyms, implicit request, compound request, ambiguous request],
  ),
  caption: [The two frozen question sets.],
) <tab-sets>

Each question carries the passage that a correct result must contain. Every expected passage was verified automatically for two properties: it occurs literally in the expected document, and it is distinctive in the corpus. Concepts shared by several documents, such as the Mourabaha, therefore carry a piece of evidence that is specific to each document. The five out-of-scope questions have no expected passage: the correct result for them is a refusal.

== Measure and protocol

Retrieval is measured by *hit\@k*: over a set $Q$ of questions, the share of those for which a chunk of the expected document containing the expected passage appears among the first $k$ results,

$ "hit@"k = 1 / abs(Q) sum_(q in Q) bb(1) lr([ "rank"(q) <= k ]) $

reported here for $k = 1$, $3$ and $5$. Final behaviour is measured separately, by the status of each response (grounded answer or reasoned refusal) and by the conformity of its citations. Four rules govern every comparison.

- *Paired comparison.* The two arms of a comparison are measured in the same run.
- *Tolerance.* Any comparison between runs is read with a tolerance of ±2 points, because served models are not bit-reproducible.
- *Two stages.* An _offline_ stage, lexical only, deterministic and free, serves as a fast filter. A _live_ stage, with the real embedding and answer models, decides.
- *Decision rule.* A default changes only if the new arm wins _without_ regression on the verbatim and out-of-scope questions.

== Chunking: fixed window against structure

@fig-chart-chunking compares the two chunking modes on the main set, at both stages.

#fig(chart-chunking, caption: [Retrieval accuracy of the two chunking modes on the 45 questions that can be evaluated (percentages).]) <fig-chart-chunking>

The gain is clear and reproduced at both stages: *20 points of hit\@1* on the live arm, from 51 % to 71 %, and 16 points of hit\@5, from 71 % to 87 %. @tab-chunk-cat breaks the live measurement down by category of question.

#tab(
  dtable(
    columns: (1fr, 14mm, 26mm, 26mm, 26mm),
    align: (left + top, right + top, center + top, center + top, center + top),
    header: ([Category], [Questions], [hit\@1], [hit\@3], [hit\@5]),
    [Verbatim], [10], [50 #sym.arrow.r 50], [50 #sym.arrow.r 60], [70 #sym.arrow.r 80],
    rowline,
    [Paraphrase], [20], [45 #sym.arrow.r *80*], [65 #sym.arrow.r *90*], [65 #sym.arrow.r *95*],
    rowline,
    [Cross-lingual], [15], [60 #sym.arrow.r 73], [73 #sym.arrow.r 80], [80 #sym.arrow.r 80],
    table.hline(stroke: 0.6pt + navy),
    text(weight: "semibold")[All], text(weight: "semibold")[45], text(weight: "semibold")[51 #sym.arrow.r 71], text(weight: "semibold")[64 #sym.arrow.r 80], text(weight: "semibold")[71 #sym.arrow.r 87],
  ),
  caption: [Live retrieval by category of question: fixed window #sym.arrow.r structure-aware chunking (percentages).],
) <tab-chunk-cat>

The paraphrases benefit most, which is the expected effect: a chunk that is a whole unit of meaning with its breadcrumb matches a reworded question better than a window that begins in the middle of an article. @fig-chart-language shows the same measurement by language of the question.

#fig(chart-language, placement: auto, caption: [Live retrieval by language of the question, for the two chunking modes (percentages).]) <fig-chart-language>

Arabic and English questions improve; French questions do not. Two cautions apply. The French subset has only six questions, so that one question weighs 17 points. And the offline stage shows the same picture more sharply: French stays at 33 % for every value of k and both chunking modes, a lexical ceiling that only the dense stage could cross, since a French question shares almost no word with an Arabic corpus.

#callout(kind: "decision", title: [Structure-aware chunking becomes the default])[
  The structural mode wins on every aggregate and loses on no category. The fixed-window mode stays available as an explicit option, and the fingerprint of the index prevents the two from being mixed.
]

A complementary observation came out of this campaign: the questions missed by the dense arm were often found by the lexical arm. It motivated the trial of a deterministic reranker, which raised the offline hit\@3 from 82 % to 89 % and hit\@5 from 87 % to 89 % without regression on verbatim or out-of-scope questions, and which is on by default.

== Retrieval modes: fusion does not pay

Hybrid retrieval is the usual recommendation. On this corpus, measured live on the structural arm, it brings nothing (@fig-chart-modes).

#fig(chart-modes, caption: [Live retrieval accuracy of the three retrieval modes on the structural arm (percentages).]) <fig-chart-modes>

Reciprocal rank fusion equals dense retrieval at rank 1 and at rank 3 and falls behind at rank 5 (82 % against 87 %). Score blending falls behind at rank 1 (62 % against 71 %). On French questions the gap is wider: dense retrieval obtains 50 / 67 / 67, against 33 / 33 / 50 for fusion and 33 / 33 / 67 for blending. The explanation is the one given above: for a French question on an Arabic corpus, the lexical arm contributes noise, and fusion gives that noise a vote.

#callout(kind: "decision", title: [Dense retrieval stays the default])[
  Under the decision rule, the default does not change. The two hybrid modes remain available as explicit options of a request, and the decision is to be revisited on new data, in particular if French or English documents join the corpus.
]

== Independence of the answer model

A campaign measured two answer models on _identical retrieval_: the same question, the same chunks (@fig-chart-models).

#fig(chart-models, caption: [Outcome of the 50 questions of the main set for two answer models given identical retrieved context.]) <fig-chart-models>

The two models agree on the status of the response for 36 questions out of 50, an agreement of 0.720. The more important result concerns the cases in which both answer: the sources they cite are _identical_, with a Jaccard similarity of 1.000. With the context fixed, models diverge on whether to answer, not on what to cite. The comparison model also failed nine times at the provider, against none for the pinned model, and each model had seven drafts rejected by the citation gate.

This result supports an architectural choice. Retrieval is independent of the answer model, since the model never sees the question as a search query, and the remaining work moves to the completeness of the evidence rather than to the choice of model. It also shows the gate at work: fourteen drafts that a system without verification would have served were withheld.

The pinned pair of models had been selected earlier by a measured comparison of freely accessible models. On the selected pipeline, that regression recorded 13 of 14 development checks, 18 of 18 held-out answer checks and 3 of 3 synthetic source-injection fixtures, while 9 of 9 requests for private or live data were refused by the local guard without any model call.

== The knowledge layer

@fig-chart-units reports two measurements of the knowledge and understanding layers.

#fig(chart-units, placement: auto, caption: [Left: the knowledge-unit index against structural chunks on the 12 questions about the law. Right: live retrieval on the target set, two questions per category (percentages).]) <fig-chart-units>

*The unit index.* The 198 descriptive lines of the articles, indexed in an isolated collection and judged by the same rule as the reference arm, place every question about the law at rank 1, including the cross-lingual ones, where the structural chunks reach 67 % at rank 1 and 92 % at ranks 3 and 5. A short, descriptive line per article is a better search surface than the article's text.

*The target categories.* Compound requests are well covered. Implicit and ambiguous requests are recovered within the first three results. Synonyms are partly covered. Colloquial wording is not covered at all by retrieval alone: this is a documented gap, and it is precisely the case that the bounded interrogation of the understanding layer was built for. With two questions per category, these figures indicate where the difficulty lies; they do not quantify it.

One negative result deserves a mention. Activating an institutional lexicon of 16 entries (abbreviations, equivalents, colloquial to formal) improved the lexical arm and brought _nothing_ on the dense arm. The lexicon was therefore left off, a decision that is documented and can be revised.

== The final campaign

The last campaign of the internship measured the link between a question and the space of subjects of the corpus, after the topic map had been rebuilt on the sources (@tab-final).

#tab(
  dtable(
    columns: (62mm, 1fr),
    header: ([Measurement], [Result]),
    [Retrieval alone, 7 cases that carry evidence], [5 of 7 at ranks 1, 3 and 5, in dense mode],
    rowline,
    [Comparison of the topic map, 12 live calls], [12 of 12 outputs parsed without error; target subjects reached: 4 of 5 before, 5 of 5 after],
    rowline,
    [End-to-end probe, 6 unchanged questions], [3 grounded answers and 3 refusals; every generated answer validated; no provider error],
    rowline,
    [Number of chunks retrieved: 5, then 12, then 20], [No change in any result],
  ),
  caption: [Measurements of the final campaign.],
) <tab-final>

The insensitivity to the number of chunks is informative: when the right passage is not among the first five, it is not among the first twenty either. The limiting factor is the formulation of the question, not the depth of the search, which again points to the understanding layer.

== Robustness of the gate

Six adversarial scenarios are verified automatically against the citation gate: a fabricated quotation, a quotation borrowed from another source, a computed number ("12 % of 1000"), an unknown citation identifier, a citation marker placed inside the text of a claim, and an instruction injected into the question or into an excerpt. All six are rejected by the deterministic checks.

Beyond these scenarios, a harness of 469 reviewed families of questions in the three languages records, for each family, the expected behaviour, the facts required and the claims forbidden.

== Automated quality gates

#tab(
  dtable(
    columns: (27mm, 1fr, 1fr),
    header: ([], [Engine], [Web platform]),
    [Tests], [472 unit tests in three suites (pipeline, harness, service) and 133 deterministic offline checks], [123 tests in 24 classes on the edge; 91 tests in 20 files on the web application],
    rowline,
    [On every push], [Compilation, offline checks, unit tests, offline inspection of the corpus, dependency verification; build of the container image and import test], [Five jobs: change detection, the full migration chain on a real PostgreSQL 16, edge build and tests, web build and tests, optional static analysis],
    rowline,
    [On deliberate trigger], [Campaigns on real models (real-model tests, heavy harness, retrieval judge, answer comparison, provider catalogues), started by hand, by a dedicated tag or by a change of the campaign's plan], [End-to-end smoke test of nine checks through the web tier, against a deployed environment],
    rowline,
    [Gates that fail a build], [Index fingerprints, ingest seal, no model fallback, refusal before generation, fail-closed interrogation], [Line coverage of 80 % on three security-critical classes; 50 % of lines and statements on the web application],
  ),
  caption: [Automated quality gates of the two systems.],
) <tab-quality>

Two choices in @tab-quality are deliberate. On the engine, an ordinary push never starts a campaign on real models: these are the only runs that consume quota, so they are started deliberately, they are bounded, and each publishes its figures in the summary of the run. On the web platform, the coverage gates have a narrow, honest scope, namely the governed-facts service, the refresh-token service and the correlation filter, rather than a global percentage that a young code base would have met by testing accessors.

The migration job deserves a word. Unit tests of the edge run on an in-memory database, which says nothing about PostgreSQL. The job therefore applies the fifteen migrations, in order, to a real instance on every relevant push. It caught a migration that renamed account types before dropping the constraint that forbade the new names, a defect no unit test could see.

== What the measurements do not prove <sec-validity>

#callout(kind: "limit", title: [Limits of the evidence])[
  - *Small, correlated sets.* Fifty questions and ten target cases, written by the project, are neither a security guarantee nor a legal one. Several subsets are too small for their percentages to be more than indications.
  - *One corpus.* Every result holds for four Arabic documents. The ranking of the retrieval modes, in particular, may change with a multilingual corpus.
  - *Retrieval more than answers.* hit\@k measures whether the right passage was found. The quality of the final answer was measured on far fewer cases.
  - *Citation is not entailment.* The gate guarantees that words and numbers come from the source, not that the claim follows from them.
  - *Tests measure what they simulate.* The three most expensive defects of the engine were found only by real use (@ch-operations).
]
