#import "../lib/theme.typ": *
#import "../figures.typ": *

= Delivery and operations <ch-operations>

#lead[How a commit becomes a running service, how the running service is observed, and what real use revealed that no test had shown.]

== From commit to production

@fig-pipeline shows the delivery path of the web platform. Its principle is that continuous integration builds and tests, and does not deploy: registry credentials and the target host belong to the operator, and promotion is a human decision.

#fig(fig-pipeline, caption: [Delivery path of the web platform: one build, promoted unchanged through three environments.]) <fig-pipeline>

Promotion is a script that enforces the rules a person forgets under pressure.

- It refuses to promote a working tree that is not clean: an uncommitted fix is not a release.
- It tags images with the commit identifier and never with a floating tag.
- On the target, it only pulls the tag it has just pushed and restarts. It never builds there, so the image that was tested is the image that serves.

The same image digests move from development to staging and to production and are never rebuilt between environments; only configuration and secrets differ, and the three secrets (the signing key of the tokens, the database password and the service token of the engine) are injected by the environment.

=== Which build is running?

Debugging an answer at the level of its symptoms cannot distinguish "the policy is wrong" from "the policy is right and this container predates it": the screen looks the same. Every image therefore carries the commit it was built from, exposed by the edge on its information endpoint, by the web tier in a version file and by a label on the image itself. The promotion script has a verification mode that compares these values with the promoted commit and lists the commits that a lagging host is missing.

=== Schema changes without downtime

Migrations are additive: they add columns, tables and indexes, and never drop or rename something in the release that stops using it. Removal happens one release later, following the sequence _expand, migrate, contract_. The consequence is a simple rollback: redeploying the previous image is enough, because the previous code runs correctly on the newer schema. The deployment guide adds daily backups with point-in-time recovery and a retention of at least thirty days.

== Observability

The edge exposes three metrics on the chat path: the number of exchanges by outcome, their duration, and the estimated number of tokens. Its logs are structured and carry three identifiers (request, session and exchange) that allow one exchange to be followed across the two systems. The engine adds its own audit trail, with the sufficiency state of every request. @tab-alerts gives the starting set of alerts defined in the deployment guide.

#tab(
  dtable(
    columns: (1fr, 44mm),
    align: (left + top, left + top),
    header: ([Condition], [Threshold]),
    [The health of the edge is not "up"], [for 2 minutes],
    rowline,
    [The engine is unreachable], [for 2 minutes],
    rowline,
    [Share of refused exchanges], [above 40 % over 15 minutes],
    rowline,
    [95th percentile of the answer latency], [above 20 s over 10 minutes],
    rowline,
    [Connection errors to the database], [any],
  ),
  caption: [Starting set of alerts.],
) <tab-alerts>

The alert on the share of refusals is specific to this kind of system. A refusal is a valid response, so it raises no error; but a sudden rise in refusals is the signature of a corpus that was not re-indexed, of a model that changed behaviour, or of a link that is misconfigured.

The operations runbook is written for the person on call and follows one pattern: symptom, diagnosis, action. Its entry for "a visitor is refused although the corpus holds the answer" begins with a sentence that summarises the whole design: a refusal is the engine's verdict on its own evidence, not a fact about the bank.

== Launch plan

The plan defined for a launch has four steps. None of them was executed during the internship; they are an operational action outside the repositories.

+ *Staging soak.* One week on the real corpus, during which administrators use the console daily.
+ *Canary.* The assistant is published behind a feature flag for 5 % of visitors and observed for 48 hours.
+ *Ramp.* From 25 % to 100 % over a week, each step being conditional on a stable share of refusals, a 95th percentile of latency below 12 seconds, and the absence of a major incident.
+ *Rollback.* The feature flag is switched off, which takes seconds, or the previous tag is redeployed, which takes minutes.

== Operating the engine

The engine is deliberately a single process: one profile, one index, one indexing run at a time. This is a limit for scale and a simplification for operations, since there is no shared state to reconcile. Its running cost was kept close to zero during the internship by two choices: freely accessible models, verified by a live price check before use, and caches addressed by content for embeddings and for answers, so that a repeated measurement costs nothing.

== What real use revealed

The defects in @tab-defects reached a real environment. They are listed with their causes, because the causes are more instructive than the fixes.

#tab(
  dtable(
    columns: (43mm, 1fr, 43mm),
    size: 8.5pt,
    pad: 4.4pt,
    header: ([Symptom], [Root cause], [Fix]),
    table.cell(colspan: 3, fill: tint.lighten(40%), overline-label([Engine], fill: muted, size: 7pt)),
    [The guided second search never ran in the deployed service], [The service called the sufficiency check without a retrieval function; invisible on the test bench], [Function supplied; verified on the running service],
    rowline,
    [A procedural French question was treated as a definition], [The pattern for _Quelle_ matched inside _Quelles_], [Patterns anchored; French procedural markers added],
    rowline,
    [The index doubled in size], [A document already in the corpus was pushed and indexed again: 859 of 1,713 chunks were duplicates], [An identical push is refused by content hash, not by name],
    rowline,
    [A refusal about missing evidence read as "no access to your accounts"], [One sentence served all six refusal reasons], [One wording per reason; the vocabulary of reasons unchanged],
    rowline,
    [Configuration silently ignored in a container], [A token written in the composition file took precedence over the environment file], [Removed from the composition file; precedence documented],
    table.cell(colspan: 3, fill: tint.lighten(40%), overline-label([Web platform], fill: muted, size: 7pt)),
    [Migrations silently not applied], [The new major version of the framework needs the migration _starter_, not the core library alone], [Starter added; the build asserts that it is packaged],
    rowline,
    [The edge refused to start after an update], [A migration renamed account types _before_ dropping the constraint that listed the old names], [Order corrected: drop, rename, add again],
    rowline,
    [A rebuilt site was served without styles], [The web tier let the entry document be cached], [Entry document never cached],
    rowline,
    [Customers saw document names], [Provenance was rendered by the chat component], [Removed at the edge; staff keep it],
    rowline,
    [Old conversations reopened the leak], [The history endpoint replayed rows as stored], [Sanitised on read, and a one-off correction at rest],
    rowline,
    [Production could start with a known administrator account], [Start-up seeding ran unconditionally], [Seeding behind a flag, off by default; no password in logs],
    rowline,
    [A production build signed visitors in as demo accounts], [The build had no environment replacement, so the "production" switch was always false], [Replacement added; fixtures compiled out of production],
    rowline,
    [A read-only operator was ejected from the console], [The landing route redirected everyone to a screen that this operator's permissions refused], [The landing guard chooses the first permitted screen],
  ),
  caption: [Defects that reached a real environment, with their root causes.],
  breakable: true,
) <tab-defects>

Three observations follow from this table.

#runin[A test bench measures what it simulates.] The three most expensive defects of the engine were invisible in a suite of several hundred tests and obvious in real use. The rule adopted at the end of the internship follows directly: any statement about the deployed service must be verified on the deployed service.

#runin[Removing a feature leaves its assumptions behind.] The last three defects of the web platform were found during a final reading of the repository, after the in-house answering service had been removed, and two of them were live in the shipped application. A repository should be read as a whole after a period of deletions.

#runin[A leak is a property of every path to the data.] Hiding provenance in the chat component was not enough: the same text reached customers through the history endpoint and remained in the database. The correction had to be made at the source, on read and at rest.
