#import "../lib/theme.typ": *

= Host organisation and project framing <ch-context>

#lead[The bank, the regulatory texts that govern its products, the problem those texts create for anyone who has to answer questions about them, and the method adopted to solve it.]

== Al Baraka Bank Tunisia

Al Baraka Bank Tunisia is the first Islamic bank established in Tunisia and in the Maghreb. It was created on 15 June 1983 under the name Beit Ettamwil Tounsi Saoudi (BEST Bank) by the Tunisian State and Sheikh Salah Abdallah Kamel, founder of the Dallah Al Baraka group. It took its present name in 2009, when the group unified its commercial identity, and in 2013 it obtained approval for its transformation from a non-resident bank into a resident universal bank @ilboursa2020 @ugfs. It belongs to Al Baraka Group, headquartered in Bahrain, which reported 679 branches and 10,322 employees for 2024 @abg2024. The Tunisian network counted 44 branches at the publication of the 2025 results @ilboursa2026 @universnews2026, and the magazine Global Finance named the bank best Islamic financial institution in Tunisia for 2021 @ilboursa2021.

#tab(
  dtable(
    columns: (34mm, 1fr),
    header: ([Item], [Description]),
    [Name], [Al Baraka Bank Tunisia, formerly Beit Ettamwil Tounsi Saoudi (BEST Bank)],
    rowline,
    [Founded], [15 June 1983; present name since 2009],
    rowline,
    [Status], [Resident universal bank, following the approval obtained in 2013],
    rowline,
    [Activity], [Islamic banking: financing, investment deposits and banking services conducted without interest],
    rowline,
    [Group], [Al Baraka Group, Bahrain],
    rowline,
    [Network], [44 branches in Tunisia],
    rowline,
    [Head office], [Avenue Cheikh Mohamed Fadhel Ben Achour, Centre Urbain Nord, 1082 Tunis],
  ),
  caption: [The host organisation at a glance.],
) <tab-host>

The internship took place at the head office, under the supervision of Mrs. Ahlem Ben Haddoud. The work was carried out in an individual development environment: versioned repositories, containerised services and a continuous-integration pipeline that served both as a quality gate and as the bench on which the real models were measured.

== The regulatory setting of Islamic banking in Tunisia

The products of an Islamic bank are defined by law before they are defined by the bank. Two texts frame them in Tunisia, and both belong to the corpus of this project.

*Law n° 2016-48 of 11 July 2016* on banks and financial institutions @loi2016 is the general banking law. Its Article 11 defines Islamic banking operations as banking operations that give rise to neither the collection nor the payment of interest, in the taking of deposits, placement, financing and investment, in conformity with Islamic banking standards. It names the forms they take, in particular Mourabaha, Ijara with an option to purchase, Moudaraba, Moucharaka, Istisna'a, Salam and investment deposits, and it leaves their detailed definition and the conditions of their exercise to a circular of the Central Bank of Tunisia. Article 54 of the same law provides for a committee that controls the compliance of these operations with Islamic banking standards.

*Circular n° 2019-08 of 14 October 2019* of the Central Bank of Tunisia @bct2019 gives that detailed definition. It states that Islamic banking operations take the form of commercial financing (Mourabaha, Ijara, Istisna'a and Salam), of participative financing, or of investment deposits; it sets the conditions of each contract; and it submits the Sharia aspects of the operations to the approval of the institution's compliance committee, in application of Article 54 of the law.

#tab(
  dtable(
    columns: (25mm, 22mm, 1fr),
    header: ([Operation], [Arabic term], [Principle]),
    [Mourabaha], ar[المرابحة], [Sale of an asset at cost plus a margin that is disclosed to the buyer],
    rowline,
    [Ijara], ar[الإجارة], [Lease of an asset, which the law contemplates with an option to purchase],
    rowline,
    [Istisna'a], ar[الاستصناع], [Order to manufacture or build an asset to specification, at a price agreed in advance],
    rowline,
    [Salam], ar[السلم], [Sale paid at once for goods of defined specification delivered later],
    rowline,
    [Moudaraba], ar[المضاربة], [Partnership in which one party provides the capital and the other the management, with profits shared in an agreed proportion],
    rowline,
    [Moucharaka], ar[المشاركة], [Partnership in which every party contributes capital and shares the result],
    rowline,
    [Investment deposits], ar[ودائع الاستثمار], [Funds entrusted to the bank for investment and remunerated by a share of the result rather than by interest],
  ),
  caption: [The Islamic banking operations named by Article 11 of Law n° 2016-48, with their usual definition.],
) <tab-operations>

This setting has a direct consequence for an assistant. The vocabulary of @tab-operations is technical, its precise conditions are set by regulation, and the figures attached to it (ratios, time limits, ceilings, penalties) are binding. An assistant that paraphrases them loosely, or that completes a missing figure from memory, exposes the bank.

== The business problem

The corpus assembled for the project consists of four real documents, all in Arabic (@tab-corpus-roles). Three concrete difficulties motivated the work.

#tab(
  dtable(
    columns: (47mm, 30mm, 1fr),
    header: ([Document], [Nature], [Role in the corpus]),
    [Law n° 2016-48 of 11 July 2016], [Law], [Highest legal reference: 198 articles in 11 titles],
    rowline,
    [BCT Circular n° 2019-08], [Central-bank circular], [Operational framing of the Islamic operations: 20 sections],
    rowline,
    [Internal guide to Islamic banking operations], [Internal guide], [Internal compliance policy and procedures],
    rowline,
    [Introduction to Islamic finance (_Madkhal_)], [Training primer], [History, definitions, orders of magnitude],
  ),
  caption: [The four documents of the corpus and the role each one plays.],
  placement: auto,
) <tab-corpus-roles>

#runin[The user's question is rarely the document's question.] A customer or a branch officer asks in everyday language, for example whether it is possible to open a shop, where the corpus uses technical wording such as #ar[الصيغة] (the contractual form), #ar[محل العقد] (the object of the contract) or #ar[تمويل] (financing). The answer has to be found across that lexical and syntactic gap.

#runin[Multilingualism is asymmetric.] The corpus is Arabic, but questions also arrive in French and in English. A French question must be able to rest on an Arabic passage without translating either the user or the document.

#runin[Errors are expensive.] In a banking context, a wrong answer on a rate, a time limit or a penalty is not a mere imprecision. It is a legal risk, and it is the reason why the project optimises for traceability and refusal rather than for fluent prose.

== Objectives and scope

The objectives set at the start of the internship were kept throughout the project.

#tab(
  dtable(
    columns: (9mm, 1fr),
    header: ([N°], [Objective]),
    [O1], [Build a complete chain on the real documents: loading, chunking, embedding, indexing, retrieval, grounded generation and verification.],
    rowline,
    [O2], [Use only freely accessible and reproducible models, and document comparative measurements rather than impressions.],
    rowline,
    [O3], [Make explicit refusal a first-class behaviour, with a stable taxonomy of reasons.],
    rowline,
    [O4], [Deliver the engine as a service integrated with the bank's application, under a stable, versioned and tested HTTP contract.],
    rowline,
    [O5], [Instrument quality: offline tests, continuous integration, frozen question sets and an audit trail.],
    rowline,
    [O6], [Give customers a trilingual assistant that never exposes the internal provenance of an answer, and give staff a console to supervise every conversation and to operate the engine.],
    rowline,
    [O7], [Keep customer records out of the retrieval index under all circumstances.],
  ),
  caption: [Objectives of the internship.],
) <tab-objectives>

Three things are deliberately outside the scope. The assistant answers questions; it executes no banking operation. The engine has no access to accounts or to any live data. And the result is a system prepared for a supervised pilot on approved documents, not a production banking service, a point to which @ch-security returns.

== Constraints

The project was carried out under six constraints. None of them was negotiable, and each one shaped the working method (@tab-constraints).

#tab(
  dtable(
    columns: (62mm, 1fr),
    header: ([Constraint], [Consequence for the method]),
    [No network access to the model providers from the development workstation], [Measurements on real models run in continuous integration, on explicit trigger, so that their cost stays under control],
    rowline,
    [No GPU], [Models are consumed through APIs, pinned and versioned],
    rowline,
    [Real corpus only], [No fictitious corpus in the repository; question sets are frozen and versioned],
    rowline,
    [The service was already being integrated by the application], [The HTTP entry points are frozen: every evolution is additive and comes with a version increment],
    rowline,
    [Traceability requirement], [Every published figure is attached to a commit, a log or a run identifier],
    rowline,
    [No Java toolchain or container runtime in the coding sandbox of the web platform], [Each change ends with the exact commands for verification on the host, and continuous integration is the referee],
  ),
  caption: [Constraints of the project and their effect on the working method.],
  placement: auto,
) <tab-constraints>

== Working method <sec-method>

=== The step-and-plan protocol

From the methodological reset described in @ch-raglab onwards, the project followed a protocol in which each step publishes its own plan before a single line of code is written. The plan has eight points: (1) the objective and the scope, including what the step does _not_ do; (2) the inputs (files, decisions, earlier measurements); (3) the actions, numbered and individually verifiable; (4) the outputs (files, reports, named figures); (5) the automatic verification (tests, pipeline, integrity checks); (6) the way the sponsor tests the result personally; (7) the criterion for moving to the next step; and (8) the rollback point.

Two rules complete the protocol. The local gate (compilation, offline checks, unit tests, inspection) must be green _before_ anything is published, and the continuous-integration run must be watched until it is green _afterwards_. Question sets are frozen: a measurement campaign that modified them would be void.

=== A written contract for assisted development

The implementation was carried out with the assistance of a coding agent, under a written working contract kept in each repository. The contract records the constraints, the verified facts and the pitfalls already met; it states what may be decided without asking, what must be asked, how work is committed and what "done" means. Every step remained subject to human validation: the agent proposes, measures and documents, while activation decisions, such as changing a default or opening a new phase, belong to the sponsor. Business rules, regulatory wording, profit rates and data-retention choices were never left to the tool.

This organisation proved decisive for reproducibility. It allowed the project to be resumed after several interruptions without starting again from nothing, and it prevented the same defect from being diagnosed twice.

=== Continuous integration as referee

On both repositories, the pipeline is the arbiter of what works. On the engine, eight workflows separate an offline gate that runs on every push from the campaigns on real models, which are triggered manually. On the web platform, five jobs run on every push, one of which applies the complete chain of database migrations to a real PostgreSQL instance. @ch-evaluation describes these mechanisms and what they do and do not prove.
