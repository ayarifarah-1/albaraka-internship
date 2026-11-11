#import "../lib/theme.typ": *
#import "../figures.typ": *

= Security, privacy and compliance <ch-security>

#lead[What is protected, by which mechanism, at which boundary; and, stated as plainly, what is not yet protected.]

== Trust boundaries

@fig-trust shows the platform as a sequence of trust zones. Each crossing between zones carries a control, numbered in the figure.

#fig(fig-trust, caption: [Trust zones of the platform and the control applied at each crossing.]) <fig-trust>

+ *From the Internet to the edge proxy.* The deployment guide requires a reverse proxy that terminates TLS, redirects to HTTPS, sets strict transport security and applies rate limiting and a web application firewall. It is the only component reachable from outside. This proxy belongs to the hosting infrastructure and is not part of the repositories.
+ *The web tier.* nginx serves the application with a content security policy restricted to the site's own origin for scripts, forbids framing, disables content sniffing, limits the referrer and the browser permissions, and hides its version. The entry document is never cached, so that a new release is picked up at once.
+ *The edge.* Sessions are stateless. Every route requires authentication except the chat, the authentication endpoints, the public news and the health probes. Cross-origin requests are accepted only from a configured list of origins, and the production profile disables the interactive API documentation.
+ *The database.* Only the edge writes to it. The schema is owned by versioned migrations and validated by the application at start-up, and check constraints enforce the invariants that must hold whatever the code does.
+ *From the edge to the engine.* The call carries a service token that never reaches a browser, and the engine compares it in constant time. Of a customer's situation, only the masked block of @sec-masking crosses this boundary.
+ *From the engine to the model providers.* The question and the retrieved excerpts leave the bank's network. This crossing has no technical control beyond the choice of pinned providers; it is the first of the open items below.

== Defence in depth

#tab(
  dtable(
    columns: (27mm, 1fr, 31mm),
    header: ([Layer], [Control], [Enforced by]),
    [Browser], [Content security policy, frame denial, no content sniffing, strict referrer policy, restricted browser permissions], [Web tier; frame denial and referrer policy repeated at the edge],
    rowline,
    [Passwords], [Stored as BCrypt hashes, never in clear and never logged], [Edge],
    rowline,
    [Tokens], [Access tokens carry a type, so a refresh token cannot be used as an access token; refresh tokens are single-use, rotated, and revoked as a family on reuse], [Edge],
    rowline,
    [Authorisation], [Permissions are computed from the database on every request and not read from the token, so a change of role takes effect immediately; checks at the route, at the controller and at the method], [Edge and web application],
    rowline,
    [Roles], [Roles exist only among staff; only the general manager grants them; every grant and withdrawal is audited], [Edge and database constraints, with a test in continuous integration],
    rowline,
    [Abuse], [Quota checked before the engine is called; limit on new sessions per address; the forwarded address is trusted only when it comes from the web tier], [Edge],
    rowline,
    [Service to service], [Shared token on every call, compared in constant time], [Edge and engine],
    rowline,
    [Answers], [Deterministic citation gate; output scrubbing of personal-data patterns; provenance removed for customers], [Engine, then edge],
    rowline,
    [Logs], [Structured logs carry a request, session and exchange identifier, never an e-mail address or the text of a question; correlation headers are restricted to 64 safe characters], [Edge],
    rowline,
    [Metrics], [The metrics endpoint requires the general manager's role unless it is explicitly opened to an internal scraping network], [Edge],
    rowline,
    [Secrets], [No key in the tree; environment files ignored; an example file documents every variable], [Repositories],
    rowline,
    [Fixtures], [Development accounts are created only when a dedicated flag is set; it is off by default and its use is logged], [Edge],
  ),
  caption: [Layered controls and the component that enforces each.],
) <tab-defence>

== Threats specific to language models

A system that passes text to a language model has an attack surface of its own. @tab-llm maps the controls of the platform to the risk categories of the OWASP list for applications built on large language models @owasp2025.

#tab(
  dtable(
    columns: (38mm, 1fr, 39mm),
    header: ([Risk category], [Control in the platform], [Residual risk]),
    [Prompt injection], [The instruction declares the question and the excerpts to be untrusted data; the model has no tool and no ability to act; an injected instruction cannot produce a quotation that the gate accepts unless the source really contains it], [A poisoned document, once approved into the corpus, would be quoted faithfully],
    rowline,
    [Sensitive information disclosure], [No customer record in the index; masked context with a lifetime of one request; scrubbing of the output; provenance hidden from customers], [Personal data typed by the customer into a question],
    rowline,
    [Improper output handling], [The output of the model is parsed as data and validated against a strict shape; in the browser it is inserted through the framework's sanitiser, and the content security policy forbids inline scripts], [Sanitised markup is still markup; rendering as plain text would be stricter],
    rowline,
    [Excessive agency], [The model performs no action: no tool, no account access, no transaction], [None by design],
    rowline,
    [Vector and embedding weaknesses], [Fingerprinted index, refusal to serve a stale index, ingest seal, rejection of duplicate documents by content hash], [Single-tenant index: no per-user filtering of documents],
    rowline,
    [Misinformation], [Evidence sufficiency before generation; quote and number verification after it; explicit refusal], [A correctly sourced claim can still be an abusive interpretation],
    rowline,
    [Unbounded consumption], [Token and message quotas per session, limit on new sessions, bounded number of model calls per request, time-outs per kind of call], [Volumetric attacks are left to the edge proxy],
  ),
  caption: [Controls of the platform against risk categories of the OWASP list for LLM applications.],
) <tab-llm>

== Personal data

Personal data protection in Tunisia is governed mainly by Organic Law n° 2004-63 of 27 July 2004 @loi2004, under the supervision of the national authority for the protection of personal data (INPDP), to which banking secrecy is added. The project produced an inventory of the personal data held by the platform, field by field, and an assessment of the controls. The inventory identifies conversations as the highest-risk category: free text typed by customers, stored with a session and a network address.

What the platform does today has been described in the previous chapters: no customer data in the index, a masked view for the engine, output scrubbing, provenance hidden from customers, role separation enforced in the database. @tab-pii lists what it does not do yet. The list is reproduced from the project's own assessment, with its severities.

#tab(
  dtable(
    columns: (17mm, 1fr, 1fr),
    header: ([Severity], [Gap], [Proposed remedy]),
    [High], [The "location" column stores the full network address and appears in conversation lists], [Mask it in lists; keep the full value on the detail path, with a record of who read it],
    rowline,
    [High], [No retention policy, no deletion job: anonymous conversations and addresses accumulate], [A scheduled job with declared durations for anonymous sessions, addresses, closed accounts],
    rowline,
    [High], [Free text is not scrubbed at rest: an account identifier typed in a question stays in the database, in backups and on the monitoring screen], [Mask on display first, then at storage, with patterns for identity, account and telephone numbers],
    rowline,
    [High], [The engine and its providers are external: the text of the question leaves the bank], [A data-processing agreement, a decision on cross-border transfer and a documented choice for the masked context in production],
    rowline,
    [Medium], [The read-only role sees the text of customers' questions in the live feed], [An explicit decision: redefine the role, or show it the outcome and the timing only],
    rowline,
    [Medium], [No column-level encryption of the most sensitive fields], [Verified disk encryption, or application-level encryption of those fields],
    rowline,
    [Medium], [No path for a customer to export or erase personal data], [An export of everything held; closure that restricts access instead of deleting accounting records],
    rowline,
    [Medium], [Self-registration without verification of the address and without a record of consent], [Verification before activation; a dated, versioned consent],
    rowline,
    [Low], [Identifiers in token and audit rows; no change history on identity-verification fields], [Document the first as intended; add a change log for the second],
  ),
  caption: [Open personal-data gaps of the web platform, as assessed by the project.],
  placement: auto,
) <tab-pii>

These are questions for the bank's legal and compliance functions before they are tasks for a developer: which declaration or authorisation the processing requires, how long each category may be kept, and whether the text of a question may be sent to a service outside the country, and under which guarantees.

== Open items of the engine and of the delivery

A boundary audit of the engine, carried out at the end of the internship, left four items open. They await a decision of the sponsor and none is hidden by a default (@tab-open).

#tab(
  dtable(
    columns: (13mm, 1fr, 1fr),
    header: ([Item], [Finding], [Why it matters]),
    [H-1], [No scrubbing or rejection on the _input_ side before a question is sent to an external provider], [An identifier typed into a question leaves the bank; the output scrubber acts too late],
    rowline,
    [H-2], [The embedding cache stores a raw preview of 120 characters of each text], [The cache should not hold clear text in a service deployment],
    rowline,
    [H-3], [The service token is optional], [It must be mandatory as soon as a customer-facing platform connects],
    rowline,
    [H-4], [The sub-processors (embedding provider, model gateway) are not named in a client contract], [The bank must know, and be able to state, who processes the text],
    table.hline(stroke: 0.6pt + navy),
    [P-1], [A provider key found in a transcript file was removed and rotated, but not yet revoked], [A removal does not purge the history of a repository],
    rowline,
    [P-2], [The compose file ships development defaults: signing secret, service token, schema mode], [A start-up assertion refusing them under the production profile is safer than documentation],
    rowline,
    [P-3], [Static analysis is wired in the pipeline but no server is configured], [The job reports "not configured" instead of a result],
  ),
  caption: [Open security items: H, from the boundary audit of the engine; P, from the closing review of the web platform.],
) <tab-open>

== Readiness

#callout(kind: "limit", title: [A supervised pilot, not a production banking service])[
  The repository of the engine states it explicitly, and this report repeats it: the system is suitable for a supervised pilot on approved, non-confidential documents. It is _not_ ready for unsupervised, customer-facing banking advice. Moving beyond the pilot requires, at the least, the high-severity items of @tab-pii, the four items of the boundary audit, and an evaluation on a larger and independent question set.
]
