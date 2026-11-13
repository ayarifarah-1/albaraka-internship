#import "../lib/theme.typ": *

// ── Dedication ───────────────────────────────────────────────────────────────
#page(header: none)[
  #v(1fr)
  #align(right, block(width: 62%, {
    set par(justify: false, leading: 0.9em, spacing: 1.5em)
    set text(font: serif, style: "italic", size: 12pt, fill: ink)
    overline-label([Dedication], fill: red, size: 8pt)
    v(0.2em)
    line(length: 14mm, stroke: 1.4pt + red)
    v(0.6em)
    [To my family, whose unwavering support made this journey possible.]
    parbreak()
    [To Mrs. Ahlem Ben Haddoud, whose guidance, rigour and trust shaped every decision in this work.]
    parbreak()
    [And to everyone who believes that technology, when it is governed, can serve trust.]
  }))
  #v(2fr)
]

// ── Acknowledgements ─────────────────────────────────────────────────────────
#plain-chapter[Acknowledgements]

I express my deepest gratitude to *Mrs. Ahlem Ben Haddoud*, my internship supervisor at Al Baraka Bank Tunisia, for her availability, her precise feedback and the clarity of her decisions. At every critical junction, from the choice of the corpus to the final choice of a single answering engine, her judgement turned a technical possibility into a responsible banking feature. The discipline she asked for, a written plan before each step and a measurement before each decision, is the backbone of this report.

I thank the teams of Al Baraka Bank Tunisia for their welcome, for the documents they entrusted to this project, and for the operational feedback that revealed defects no test had shown. Several of the corrections described in these pages exist because someone at the bank ran the system for real and reported what happened.

I thank the faculty of ESPRIT for the training that made this project possible, and in particular for its insistence on engineering that can be measured rather than merely demonstrated.

Finally, I thank my family and friends for their patience and encouragement throughout this period.

#v(1.2em)
#block(inset: (left: 12pt, y: 3pt), stroke: (left: 1.5pt + hair), text(size: 9.4pt, fill: muted, style: "italic")[
  This report presents the work as it stands at the end of the internship. By design, it contains no account identifier, no repository address and no credential. All diagrams and charts were drawn for this report; the only external images are the two institutional logos on the cover.
])

// ── Abstract ─────────────────────────────────────────────────────────────────
#plain-chapter[Abstract]

In a regulated bank, a wrong answer about a rate, a deadline or a sanction is not an inaccuracy: it is a legal risk. This report presents the design, construction and evaluation of a platform that answers banking questions from documents under that constraint. The platform is made of two cooperating systems.

*RAGLab* is a retrieval-augmented generation engine built on four real Arabic documents: the banking law n° 2016-48, the Central Bank of Tunisia's circular n° 2019-08, an internal guide to Islamic banking operations and a training primer on Islamic finance. Every claim it returns carries a verbatim quote from the cited source, every number in a claim must appear in that quote, and when the evidence is insufficient the engine refuses and states what is missing.

*Bank Assistant* is a trilingual web platform (Angular, Spring Boot, PostgreSQL) for customers and bank staff. Its edge service owns identity, quotas, persistence and audit, and it consumes the engine through a frozen, authenticated contract. Customers never see the internal provenance of an answer; staff see every claim with its quotation.

Each design choice was settled by paired measurements on frozen question sets. Structure-aware chunking raises hit\@1 from 51 % to 71 % on the live retrieval arm. Dense retrieval outperforms lexical fusion on this corpus, most clearly for French questions. A knowledge-unit index places every question about the law at rank 1. Two different answer models cite identical sources whenever the retrieved context is fixed. The report also documents what the system does not guarantee: it verifies that quotes and numbers exist in the sources, not that a claim logically follows from them, and it is suited to a supervised pilot rather than to unattended production.

#v(0.4em)
#block(above: 1.2em)[
  #overline-label([Keywords], fill: muted, size: 7.6pt) \
  #text(font: sans, size: 9.8pt)[retrieval-augmented generation #sym.dot.c Islamic banking #sym.dot.c grounded answers #sym.dot.c citation verification #sym.dot.c evidence sufficiency #sym.dot.c Arabic NLP #sym.dot.c AI governance #sym.dot.c Spring Boot #sym.dot.c Angular]
]

// ── Résumé ───────────────────────────────────────────────────────────────────
#plain-chapter(outlined: false)[Résumé]

#[
  #set text(lang: "fr", region: "FR")
  Dans une banque, une réponse fausse sur un taux, un délai ou une sanction n'est pas une imprécision : c'est un risque juridique. Ce rapport présente la conception, la réalisation et l'évaluation d'une plateforme qui répond aux questions bancaires à partir de documents, sous cette contrainte. Elle réunit deux systèmes.

  *RAGLab* est un moteur de génération augmentée par la recherche, construit sur quatre documents réels en arabe : la loi bancaire n° 2016-48, la circulaire n° 2019-08 de la Banque Centrale de Tunisie, un guide interne des opérations bancaires islamiques et un support de formation à la finance islamique. Chaque affirmation renvoyée porte une citation littérale de la source, chaque nombre doit figurer dans cette citation et, lorsque la preuve est insuffisante, le moteur refuse en indiquant ce qui manque.

  *Bank Assistant* est une plateforme web trilingue (Angular, Spring Boot, PostgreSQL) destinée aux clients et au personnel de la banque. Son service de bordure porte l'identité, les quotas, la persistance et l'audit, et consomme le moteur au travers d'un contrat gelé et authentifié. Le client ne voit jamais la provenance interne d'une réponse ; le personnel voit chaque affirmation avec sa citation.

  Chaque choix a été tranché par des mesures appariées sur des jeux de questions gelés. Le découpage structurel fait passer le hit\@1 de 51 % à 71 % sur le bras de recherche réel. La recherche dense devance la fusion lexicale sur ce corpus, en particulier pour les questions en français. Un index d'unités de connaissance place chaque question portant sur la loi au premier rang. Deux modèles de réponse différents citent des sources identiques lorsque le contexte est fixé. Le rapport documente enfin ce que le système ne garantit pas : il vérifie que les citations et les nombres existent dans les sources, non qu'une affirmation en découle logiquement, et il convient à un pilote supervisé plutôt qu'à une mise en production sans surveillance.

  #block(above: 1.6em)[
    #overline-label([Mots-clés], fill: muted, size: 7.6pt) \
    #text(font: sans, size: 9.8pt)[génération augmentée par la recherche #sym.dot.c finance islamique #sym.dot.c réponses ancrées #sym.dot.c vérification des citations #sym.dot.c suffisance de la preuve #sym.dot.c traitement de l'arabe #sym.dot.c gouvernance de l'IA #sym.dot.c Spring Boot #sym.dot.c Angular]
  ]
]

// ── ملخص (Arabic abstract, right-to-left) ───────────────────────────────────
#[
  #let naskh = ("Noto Naskh Arabic", "Source Sans 3")
  #set text(font: naskh, lang: "ar", dir: rtl)
  #heading(level: 1, numbering: none, outlined: false, text(font: naskh, weight: "bold")[ملخّص])

  #set text(size: 12pt, top-edge: 0.8em, bottom-edge: -0.28em)
  #set par(justify: true, leading: 0.78em, spacing: 1.25em)

  في المصرف، الجواب الخاطئ عن نسبة أو أجل أو عقوبة ليس مجرد عدم دقة، بل هو خطر قانوني. يعرض هذا التقرير تصميم وإنجاز وتقييم منصة تجيب عن الأسئلة المصرفية انطلاقًا من الوثائق في ظل هذا القيد، وهي تتكوّن من نظامين متكاملين.

  النظام الأول هو #text(dir: ltr, lang: "en")[RAGLab]، وهو محرّك للتوليد المعزَّز بالاسترجاع بُني على أربع وثائق حقيقية باللغة العربية: القانون عدد 48 لسنة 2016 المتعلق بالبنوك والمؤسسات المالية، ومنشور البنك المركزي التونسي عدد 8 لسنة 2019، ودليل داخلي للعمليات المصرفية الإسلامية، ومدخل تكويني إلى الصيرفة الإسلامية. كل معلومة يقدّمها المحرّك مسنودة باقتباس حرفي من المصدر، وكل رقم يجب أن يرد في ذلك الاقتباس، وإذا لم يكفِ الدليل امتنع المحرّك عن الإجابة وبيّن ما ينقص.

  النظام الثاني هو #text(dir: ltr, lang: "en")[Bank Assistant]، وهو منصة ويب بثلاث لغات موجّهة إلى الحرفاء وإلى أعوان البنك. تتولّى خدمتها الطرفية الهوية والحصص والحفظ والتدقيق، وتستعمل المحرّك عبر عقد ثابت وموثَّق. لا يرى الحريف أبدًا المصدر الداخلي للجواب، أما العون فيرى كل معلومة مع اقتباسها.

  وقد حُسم كل اختيار تقني بقياسات مقترنة على مجموعات أسئلة مجمَّدة: التقطيع البنيوي يرفع نسبة الإصابة في المرتبة الأولى من 51% إلى 71%، والبحث الدلالي يتقدّم على الدمج المعجمي في هذه المدوّنة، وفهرس وحدات المعرفة يضع كل سؤال متعلق بالقانون في المرتبة الأولى، ونموذجا إجابة مختلفان يستشهدان بالمصادر نفسها عند تثبيت السياق. ويوثّق التقرير كذلك ما لا يضمنه النظام: فهو يتحقق من وجود الاقتباسات والأرقام في المصادر، لا من أنّ المعلومة تترتب عنها منطقيًا، وهو ملائم لتجربة نموذجية تحت الإشراف لا لتشغيل دون رقابة.

  #block(above: 1.7em)[
    #text(weight: "bold", fill: muted, size: 9.6pt)[الكلمات المفتاحية] \
    #text(size: 11pt)[التوليد المعزَّز بالاسترجاع #sym.dot.c الصيرفة الإسلامية #sym.dot.c الإجابات المسنودة #sym.dot.c التحقق من الاقتباسات #sym.dot.c كفاية الدليل #sym.dot.c معالجة اللغة العربية #sym.dot.c حوكمة الذكاء الاصطناعي]
  ]
]

// ── Contents ─────────────────────────────────────────────────────────────────
#plain-chapter(outlined: false)[Contents]
#contents()

// ── Lists ────────────────────────────────────────────────────────────────────
#plain-chapter[List of figures]
#list-of(image)

#v(1.8em)
#block(sticky: true, text(font: sans, size: 13.2pt, weight: "semibold", fill: navy)[List of listings])
#v(0.3em)
#list-of(raw)

#plain-chapter[List of tables]
#list-of(table)

// ── Abbreviations ────────────────────────────────────────────────────────────
#plain-chapter[Abbreviations]

#let abbr(items) = {
  set text(font: sans, size: 9.4pt)
  set par(justify: false, leading: 0.52em)
  table(
    columns: (15mm, 1fr),
    stroke: none,
    inset: (x: 0pt, y: 4.2pt),
    column-gutter: 3.5mm,
    ..items.map(pair => (text(weight: "semibold", fill: navy, pair.at(0)), pair.at(1))).flatten(),
  )
}

#let abbreviations = (
  ([AAOIFI], [Accounting and Auditing Organization for Islamic Financial Institutions]),
  ([API], [Application programming interface]),
  ([BCT], [Banque Centrale de Tunisie, the Central Bank of Tunisia]),
  ([BM25], [Best Matching 25, a lexical ranking function]),
  ([CI], [Continuous integration]),
  ([CIN], [Carte d'identité nationale, the national identity card]),
  ([CSP], [Content Security Policy]),
  ([ECS], [Elastic Common Schema, a structured log format]),
  ([HSTS], [HTTP Strict Transport Security]),
  ([IBAN], [International Bank Account Number]),
  ([INPDP], [Instance Nationale de Protection des Données à caractère Personnel]),
  ([JORT], [Journal Officiel de la République Tunisienne]),
  ([JSONL], [JSON Lines, one JSON object per line]),
  ([JWT], [JSON Web Token]),
  ([KYC], [Know your customer, the verification of a customer's identity]),
  ([LLM], [Large language model]),
  ([OWASP], [Open Worldwide Application Security Project]),
  ([PII], [Personally identifiable information]),
  ([RAG], [Retrieval-augmented generation]),
  ([RBAC], [Role-based access control]),
  ([RIB], [Relevé d'identité bancaire, the domestic account identifier]),
  ([RRF], [Reciprocal rank fusion]),
  ([SPA], [Single-page application]),
  ([SSE], [Server-sent events]),
  ([TLS], [Transport Layer Security]),
  ([TND], [Tunisian dinar]),
  ([WAF], [Web application firewall]),
)

#let half = calc.ceil(abbreviations.len() / 2)
#grid(
  columns: (1fr, 1fr),
  column-gutter: 10mm,
  abbr(abbreviations.slice(0, half)),
  abbr(abbreviations.slice(half)),
)
