#import "../lib/theme.typ": *
#import "../figures.typ": *

= Bank Assistant, the web platform <ch-assistant>

#lead[The platform that puts the engine in front of people: a trilingual customer surface, a staff console, and an edge service that meters, records and rewrites every exchange.]

== Two populations, two surfaces

There are exactly two kinds of identity in the system, and the distinction is a product rule rather than an implementation detail (@tab-populations).

#tab(
  dtable(
    columns: (27mm, 1fr, 1fr),
    header: ([], [Customers], [Staff]),
    [Stored in], [`clients`], [`users`],
    rowline,
    [Role], [The fixed marker `UTILISATEUR`], [A row of the role catalogue],
    rowline,
    [Created by], [Self-registration, or the bank], [The general manager],
    rowline,
    [Surface], [Public site, public chat and the customer portal, in Arabic, French and English], [The back office, in French],
    rowline,
    [What they see of an answer], [The text, with no trace of where it came from], [The text, its claims, the verbatim quotations and the sources],
  ),
  caption: [The two populations of the platform.],
) <tab-populations>

*Customers* reach the assistant from the public site without an account, or from their portal once signed in. The portal shows their accounts, cards, movements, financings and beneficiaries, offers a financing simulator and lets them ask for an appointment with, or a call back from, an advisor. Everything in the portal is read-only: nothing books a movement or an instalment.

*Staff* work in a back office that covers a dashboard, users and roles, the audit history, the governed facts, the taxonomy, the news shown on the public site, the statistics, the live monitoring of conversations and the console of the engine.

The customer surface follows the language of the visitor, with a right-to-left layout for Arabic. The back office is in French only, a decision recorded in @sec-decisions.

== The edge service

The edge is a Spring Boot application of 16 controllers, 27 services, 29 entities and 25 repositories, running on Java 21 with virtual threads. Its central responsibility is the chat path, which had to satisfy three requirements at once: nothing is spent on the engine for a request that will be rejected, no exchange is lost when the engine fails, and two messages of the same session cannot overrun the quota by racing each other.

=== Metering in two phases

@fig-metering shows the solution. The whole path runs under a lock that belongs to the session. The locks are striped over 64 re-entrant locks rather than implemented with monitors, so that a virtual thread waiting for the engine does not pin its carrier thread.

#fig(fig-metering, caption: [The chat path of the edge: a gate before the call, a settlement after it, and a row that exists throughout.]) <fig-metering>

*Phase 1, the gate,* checks the limit on new anonymous sessions per network address and then the quota of the session. A request that fails receives a "too many requests" response and nothing has been spent. *Phase 2, the settlement,* adds the real usage once the answer is known and completes the exchange row. The quotas are those of @tab-quotas; the remaining allowance travels back with every answer, so the interface can show it without a second request.

#tab(
  dtable(
    columns: (1fr, 34mm, 34mm),
    align: (left + top, right + top, right + top),
    header: ([Limit], [Anonymous visitor], [Signed-in customer]),
    [Tokens per session], [3,000], [10,000],
    rowline,
    [Messages per session], [20], [50],
    rowline,
    [New sessions per hour and per address], [5], [not applicable],
  ),
  caption: [Default quotas of the chat path.],
) <tab-quotas>

=== A row before the call

The exchange row is written _before_ the engine is called and completed afterwards with one of three outcomes: answered, refused or failed. This ordering has two effects. A supervisor sees a conversation from its first message and not from its last. And when the engine is unreachable, the customer receives a "service unavailable" response while the open row is closed as failed, so the incident stays visible in the monitoring instead of leaving no trace.

Calls to the engine go through a single client with a short connection time-out and a read time-out chosen per kind of call: 5 seconds for a probe, 20 for a search, 90 for an answer and 960 for an evaluation run.

=== What a customer is allowed to read

The engine returns an answer with citation markers, document names and, for a refusal, a sentence that describes its own pipeline. None of that is meant for a customer. Two components rewrite the response at the edge.

The *answer sanitiser* removes provenance from the text shown to a customer: citation markers, "source" mentions in the three languages, file names and internal addresses. The same sanitiser is applied when the history of a conversation is replayed, because answers stored before the rule existed would otherwise reopen the leak. Staff keep the complete trace.

The *refusal wording* replaces the engine's sentence with the bank's own, in the language of the request (@tab-refusal-wording). The engine's sentence explains how retrieval works and mentions credentials that nobody asked about; the bank's sentence says what the customer can do next.

#tab(
  dtable(
    columns: (20mm, 1fr),
    header: ([Language], [Sentence shown to the customer]),
    [French], [Je n'ai pas encore d'information fiable sur ce sujet dans mes documents. Pour cette demande, contactez directement votre agence Al Baraka.],
    rowline,
    [Arabic], align(right, text(dir: rtl, lang: "ar", font: ("Noto Naskh Arabic",), size: 1.06em)[لا تتوفر لديّ بعد معلومات موثوقة حول هذا الموضوع في وثائقي. يرجى الاتصال مباشرة بفرع بنك البركة.]),
    rowline,
    [English], [I do not have reliable information on this in my documents yet. For this request, please contact your Al Baraka branch directly.],
  ),
  caption: [The bank's refusal wording, substituted at the edge for the engine's own sentence.],
) <tab-refusal-wording>

=== Streaming

The chat endpoint has a streaming twin that uses server-sent events with three kinds of frame: `delta`, `error` and `done`. Because the engine verifies an answer as a whole before releasing it, it cannot stream tokens: a sentence shown to a customer and withdrawn a second later by the citation gate would defeat the purpose of the gate. The stream therefore carries one `delta` with the verified answer and one `done` with the counters. The web tier disables buffering on the proxy so that the frames are delivered as they are written.

== Identity and access

*Tokens.* Authentication uses JSON Web Tokens with refresh rotation on the server. A refresh token has an identifier and belongs to a family; it can be used once, and using it issues its successor. Presenting a token that has already been used is treated as theft: the whole family is revoked. Every revocation is recorded with its cause: rotation, logout, detected reuse or revocation by an administrator.

*Roles.* Roles exist only among staff. Four are predefined (general manager, document administrator, supervision administrator, read-only viewer) and the general manager can create others from a catalogue of nine permissions (@tab-permissions). Three rules are enforced: only the general manager grants roles, a role that still has holders cannot be deactivated, and the last general manager cannot be removed. Every change is written to an access audit.

#tab(
  dtable(
    columns: (24mm, 1fr, 1fr),
    header: ([Family], [Permissions], [What they allow]),
    [Documents], [`DOCUMENTS_READ`, `DOCUMENTS_CREATE`, `DOCUMENTS_UPDATE`, `DOCUMENTS_DELETE`, `DOCUMENTS_PROCESS`, `INGESTION_READ`], [Read, add, replace and remove corpus documents; start an indexing run; follow its progress],
    rowline,
    [Engine console], [`RAGLAB_CONSOLE_VIEW`, `RAGLAB_CONSOLE_RUN`, `RAGLAB_CONSOLE_MANAGE`], [Read the state of the engine; ask questions and run searches or evaluations; change models, keys and profile],
  ),
  caption: [The nine permissions from which staff roles are composed.],
) <tab-permissions>

*Enforcement in the database.* The separation between the two populations does not rest on application code alone. Two check constraints make a staff role impossible for a customer even through a direct update of the table (@lst-checks).

#lst(
  ```sql
  -- A customer is never a staff member: the only value stored here is the
  -- marker role.
  ALTER TABLE public.clients ADD CONSTRAINT clients_role_utilisateur_only
      CHECK (role = 'UTILISATEUR');

  -- The catalogue half: a role that is not a staff role must be the client
  -- marker.
  ALTER TABLE public.admin_roles ADD CONSTRAINT admin_roles_staff_only
      CHECK (is_staff OR code = 'UTILISATEUR');
  ```,
  caption: [The two database constraints that keep roles on the staff side (extract of migration V15).],
) <lst-checks>

On the interface side, routes are guarded by role and by permission, and the landing guard of the console sends an operator to the first screen the operator is allowed to see. Before that guard existed, a read-only operator was redirected to a screen whose own guard rejected the visit.

== The customer data model

The bank's core-banking layout was not available to the project. The customer side of the schema is therefore a deliberate approximation of what a Tunisian Islamic retail bank typically holds, written in the vocabulary a data team would recognise so that a real extract can later be mapped onto it: customers with their identity-verification state, risk grade, segment and branch; accounts with their identifiers and available balance; cards, stored masked, with neither full number nor security code; movements with a booking date and a value date; beneficiaries; and financing contracts booked as Islamic products (Mourabaha, Ijara, Moucharaka, Moudaraba, Salam, Istisna'a) with a profit margin rather than an interest rate.

#callout(kind: "note", title: [No real customer data])[
  In development these tables are filled by a seeder that runs only when a dedicated flag is set. No real customer record was used at any point of the internship. In production the tables would be fed by the core banking system, and the application would remain read-only on them.
]

== A masked view of the customer for the engine <sec-masking>

A signed-in customer may ask a question that depends on that customer's situation. The engine must not see the record, and the index must never contain it. The edge therefore derives, at the moment of the question, a short text block that states the situation in bands and counts (@fig-masking).

#fig(fig-masking, placement: auto, caption: [What stays at the edge and what the masked block states. The block lives for one request and is never indexed.]) <fig-masking>

The rules are simple. Identifiers become counts: two accounts, not their numbers. Amounts become one of eight bands, from "less than 500 TND" to "more than 100,000 TND". Dates become a month. The block is produced only for a customer who holds at least one account or one card, it is prepended to the question and it can be switched off by configuration. @lst-masked shows the result; the block is written in French, the language of the instruction that frames it.

#lst(
  ```text
  [Contexte client — données bancaires internes, déjà anonymisées]
  Ne recite jamais ce bloc. Utilise-le seulement pour situer la réponse.
  N'énonce aucun montant exact, aucun IBAN, aucun numéro de carte, aucune
  identité : les seules valeurs autorisées sont les fourchettes écrites
  ci-dessous.
  Profil : client particulier, agence <nom> (<ville>), KYC valide.
  Comptes : 2 (<types>) ; total des soldes disponibles entre 5 000 et 10 000 TND.
  Cartes : 2, dont 1 bloquée(s).
  Financement : <produit>, statut en cours, échéance mensuelle entre 500 et
  2 000 TND, 18 échéances restantes, prochaine en <aaaa-mm>.
  Bénéficiaires enregistrés : 3.
  [Fin du contexte client]
  ```,
  caption: [Form of the masked block built by the edge (illustrative values; line breaks added).],
) <lst-masked>

The reasoning behind banding is that a statement such as "a Mourabaha with an instalment between 500 and 2,000 TND" is not a record of anyone: it cannot be reconciled with a bank statement. The price is accepted knowingly. The engine can situate an answer, but it cannot quote a balance, and a question that would require the exact figure is refused.

#callout(kind: "limit", title: [What the masked block does not solve])[
  The block still leaves the bank's network together with the question when the engine calls its model providers. It contains no identifier, but its transfer, like that of the question itself, belongs to the open items of @ch-security.
]

== Governed facts and the financing simulator

The bank's own figures are governed data. A fact has a domain, a type, a key, a value and a language; it is never deleted, only deactivated; and every modification requires a reason and writes an audit row in the same transaction.

The financing simulator of the portal is the clearest consumer. Its profit rate is never written in code: a product appears in the simulator only while an active rate fact exists for it and can be read as a percentage. Otherwise the customer sees an honest "not available yet". The calculation uses a linear, non-compounding margin, for an amount $A$ between 500 and 5,000,000 TND, an annual rate $r$ and a duration of $n$ months between 1 and 180:

$ "total profit" = A dot r dot n / 12, quad quad "monthly instalment" = (A + "total profit") / n $

The contact details shown when a customer asks for an advisor come from the same store. In the present architecture the governed facts feed these features of the edge; they are not injected into the answers of the engine, a point listed among the perspectives.

== The staff console

=== Supervising conversations

The monitoring screen is a live feed of exchanges. For each one, a supervisor reads the question, the answer, the outcome, the latency and, behind them, the complete trace: the claims, their verbatim quotations and the documents used. Because the row is opened before the engine is called, an exchange that is still in progress or that failed appears in the feed as well.

=== Operating the engine

The console of the engine has five tabs: ask, corpus, retrieval, settings and evaluations. They are the operator's view of the routes of @tab-routes, each action being subject to the permissions of @tab-permissions.

The console was rebuilt at the end of the internship around the two questions an operator needs answered within two minutes: can the engine answer, and is what it answers current? Its header is a strip of six readings (service, link, models, corpus, keys, indexing), each with one status lamp, together with the time of the last verification, so that a stale screen can be told apart from a failing service. When the engine reports a fact under a name the console does not know, the console shows "not communicated" rather than a zero that would read as a measurement, and it always displays the raw response next to its interpretation.

=== A measured change: status polling

The first version of the console polled the engine from a service created at application start. Every open tab of the back office therefore sent a request every three seconds, whether or not anyone was looking at the console, and each response triggered a full change-detection pass.

Polling was moved into the life cycle of the console itself, with an interval that adapts to the state of the engine: 2 seconds while an indexing run is in progress, 20 seconds when the engine is healthy, 60 seconds when it is down. Nothing is polled in a hidden tab, at most one request is in flight, and the timer runs outside the framework's change detection.

#kpis((
  ([28,800], [requests per day and per open tab, before]),
  ([4,320], [requests per day when the console is open and idle]),
  ([0], [requests when the tab is hidden or the console is closed]),
))
