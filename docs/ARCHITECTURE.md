# Architecture

This edition deliberately has no runtime npm dependencies and no build pipeline. Node 24 provides HTTP, cryptography and SQLite; the browser uses ES modules. It is a simpler implementation of the original planner's core contracts, not a deployable copy of the original personal Sites account.

| Path | Owns |
|---|---|
| src/model.mjs | Validation, stable data shape, source merge, grade formulas, priority selection |
| src/store.mjs | SQLite transactions, revision history, immutable operation receipts |
| src/server.mjs | Exact-origin write checks, single-owner session login and bounded static/API routes |
| src/widget.mjs | Timezone-aware saved schedule export; midnight expiry |
| web/app.js | UI, durable browser journal, explicit conflict choices, search and export |
| web/sw.js | Static-only offline shell; no API caching or forced activation |
| scripts/ | Setup, preview/apply import, compact context, private iOS configuration, publication checks |
| ios/ | SwiftUI planner shell, validated WKWebView bridge, WidgetKit, local reminders |
| .agents/skills/ | Two original, small AI workflows |

## Synchronization

A device stores `{instanceId, confirmed, queue}` in one localStorage value before acknowledging an edit. Each operation has a random ID and an expected global revision. Web Locks serialize same-origin tabs where supported. Server writes and receipt insertion happen in one immediate SQLite transaction. Retries return current state without reapplying an already receipted operation.

This small edition intentionally uses whole-state revision conflict detection. Two unrelated simultaneous edits may still require review. That is conservative and easier to audit than silently choosing a winner. A conflict preserves the device queue; explicit reapplication uses new IDs and the latest revision. Choosing the server version first downloads a recovery journal.

LocalStorage can fail or be evicted by the browser. Writes must fail visibly rather than claiming success. Avoid private browsing for durable offline work; keep server backups. Sign out requires the queue to be empty and clears the browser journal. A device cache is not an encrypted vault.

## Boundary with AI

The app never calls an LLM. Browser review is an external, user-authorized workflow that creates a local JSON packet. Imports are revision-checked and preserve personal progress. Model choice and recurrence belong to the user's AI product. The helper skills are instructions, not background services or login integrations.

## Extending safely

Add fields with explicit validation and fixture tests. Extend a grading rule only after understanding its syllabus meaning. Additional LMS adapters should map evidence into the existing packet rather than embed credentials in UI code. Multi-user hosting requires a different authorization and data-isolation design; do not simply remove the single-owner gate.
