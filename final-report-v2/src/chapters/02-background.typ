#import "../lib/theme.typ": *

= Retrieval-augmented generation and its failure points <ch-background>

#lead[What a retrieval-augmented system is, where it breaks in practice, and which technical options were weighed before any of them was adopted.]

== The principle

A retrieval-augmented generation (RAG) system combines two components @lewis2020. An *information-retrieval system* selects relevant extracts from a document base, and a *language model* writes an answer from those extracts. The reasoning is simple: rather than hoping that a model has memorised facts, the system hands it the useful passages at the moment of answering.

The pipeline has two phases. Offline, documents are loaded, cut into fragments called _chunks_, converted into vectors by an embedding model and stored in an index. Online, the question is embedded in the same vector space, the closest chunks are retrieved, and the model is asked to answer from them and from nothing else.

== Where the architecture breaks

This architecture moves the problem more than it solves it. Engineering experience with such systems has identified recurring failure points @barnett2024, and the ones met in this project shaped its whole design (@tab-failures).

#tab(
  dtable(
    columns: (30mm, 1fr, 1fr),
    header: ([Failure point], [Symptom observed in practice], [Answer given in this project]),
    [Arbitrary chunking], [A definition cut in two becomes unusable], [Structure-aware chunking that follows titles, articles and paragraphs],
    rowline,
    [Lexical gap], [The question says "murabaha", the document says #ar[المرابحة]], [Shared Arabic normalisation, cross-script bridges, one bounded re-expression of the question],
    rowline,
    [False positives of similarity], [The five retrieved extracts are off topic and nothing signals it], [A deterministic sufficiency state and an explicit refusal],
    rowline,
    [Hallucination], [A well-formed sentence states an invented figure], [Verification of quotes _and_ of numbers after generation],
    rowline,
    [Loss of traceability], [Nobody can check what the model read], [Verbatim citations, chunk identifiers, an audit trail],
    rowline,
    [Silent regressions], [A local improvement degrades another case], [Frozen question sets and paired comparative measurements],
  ),
  caption: [Failure points of a RAG system and the answer adopted for each.],
) <tab-failures>

== Chunking

The literature distinguishes two families. *Fixed-window chunking* cuts the text every _N_ tokens with an overlap; it is simple, uniform and blind to structure. *Structural chunking* respects the boundaries of the document, such as titles, articles, paragraphs and tables; it produces units of meaning at the price of a prior analysis of the text.

Legal and regulatory texts make the difference acute. Their unit of meaning is the article, their vocabulary is defined once and reused everywhere, and a fragment that begins in the middle of an article can say the opposite of the article as a whole. The project implemented both families and measured them against each other; @ch-raglab describes the structural strategy that was retained, and @ch-evaluation reports its measured effect.

== Embeddings and the difficulties of Arabic

Multilingual embedding models project a text into a space in which proximity reflects proximity of meaning. Two difficulties dominate for Arabic. The morphology is rich: prefixes, suffixes and definite forms multiply the surface forms of a single word. And several writing systems coexist in the same questions, because users often write technical terms in Latin characters.

A third difficulty is specific to the sources. Arabic legal texts distributed as PDF files often come out of extraction in _visual_ order rather than logical order, with corrupted digits, which makes the raw text unusable for retrieval. The project treats this as a corpus problem and repairs the text before anything is indexed.

== Retrieval strategies

Three strategies were implemented and measured.

*Dense retrieval* ranks chunks by the cosine similarity between the question vector and the chunk vectors.

*Lexical retrieval* uses BM25 @robertson2009, which scores a chunk $d$ for a question $q$ from the frequency $f(t, d)$ of each question term $t$:

$ "BM25"(q, d) = sum_(t in q) "IDF"(t) dot (f(t, d) dot (k_1 + 1)) / (f(t, d) + k_1 dot (1 - b + b dot abs(d) / "avgdl")) $

with $k_1 = 1.5$ and $b = 0.75$ in this project, $abs(d)$ being the length of the chunk and $"avgdl"$ the average chunk length.

*Hybrid retrieval* combines the two. Reciprocal rank fusion @cormack2009 merges the ranked lists $R$ produced by the dense and lexical arms:

$ "RRF"(d) = sum_(r in R) 1 / (k + "rank"_r (d)), quad k = 60 $

and score blending mixes the two scores directly, after normalising the lexical one:

$ s(d) = lambda dot cos(q, d) + (1 - lambda) dot hat("BM25")(q, d), quad lambda = 0.7 $

Hybrid retrieval is widely recommended, because lexical matching catches exact terms that embeddings blur. Whether it helps on a given corpus is an empirical question. The three strategies were therefore compared by hit\@k, the share of questions whose expected passage appears among the first $k$ results, and on this corpus the measurement went against the common recommendation (@ch-evaluation).

== From free text to verifiable claims

The most significant design choice of the project concerns verification rather than retrieval. A model that returns free prose cannot be checked mechanically. The engine therefore requires the model to return a structured object in which each claim carries one or more pieces of evidence, each being a _verbatim_ quotation of a supplied extract. Deterministic checks can then be applied: does the quotation really occur in the cited chunk, and does every number of the claim occur in its quotations?

Upstream of generation, a second deterministic mechanism confronts the evidence that the question _requires_ with the evidence that retrieval actually _returned_. It is this sufficiency state, and not a similarity score, that decides whether the system answers, refuses, or attempts a single bounded re-expression of the question.

Both mechanisms are deliberately free of any model call. A check that is itself performed by a language model inherits the weakness it is supposed to control.

== Technology choices

The project made a deliberate choice of sobriety, argued each time it was made (@tab-tech). The engine's repository contains no orchestration framework, no external vector database and no vendor SDK. This constraint makes audit easier, since all behaviour is readable in the code, and it eases operation on an internal host.

#tab(
  dtable(
    columns: (27mm, 1fr, 1fr),
    header: ([Building block], [Choice], [Alternative set aside, and why]),
    table.cell(colspan: 3, fill: tint.lighten(40%), overline-label([Engine], fill: muted, size: 7pt)),
    [Orchestration], [Explicit Python code, module by module], [LangChain or LlamaIndex: opaque behaviour and heavy dependencies],
    rowline,
    [Vector store], [Local, persistent ChromaDB @chroma with cosine distance], [A hosted vector database: cost, and banking data leaving the premises],
    rowline,
    [Provider calls], [`urllib` from the standard library], [Vendor SDKs: extra dependencies and compatibility churn],
    rowline,
    [Service], [FastAPI @fastapi served by uvicorn], [None considered necessary],
    rowline,
    [Tokenisation], [`tiktoken` with a fallback estimate], [None considered necessary],
    rowline,
    [Documents], [`pypdf` for PDF, direct reading of OOXML for DOCX], [Office automation SDKs],
    table.cell(colspan: 3, fill: tint.lighten(40%), overline-label([Web platform], fill: muted, size: 7pt)),
    [Edge service], [Java 21 and Spring Boot 4 @springboot with virtual threads], [The first arrangement: a thin proxy and a second service writing to the same schema],
    rowline,
    [Database], [PostgreSQL 16 @postgresql, schema owned by Flyway migrations], [A schema updated by the object-relational mapper: no reviewable history],
    rowline,
    [Front end], [Angular 21 @angular, standalone components, served by nginx], [None considered necessary],
    rowline,
    [Identity], [JWT access tokens with server-side refresh rotation], [Stateless tokens that the server cannot revoke],
  ),
  caption: [Technology choices and the alternatives that were set aside.],
) <tab-tech>
