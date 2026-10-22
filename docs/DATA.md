# Data and connector contract

The executable rules are in `src/model.mjs`; see `examples/source-packet.json` and `examples/demo.mjs` for complete examples. All private data belongs outside version control.

## Import packet

`schemaVersion: 1`, `tasks: []`, `sources: []`, and optional `courses: []`.

Task fields: `id` (stable string), `title`, `course`, `kind`, `dueAt` (ISO timestamp with offset or null), optional `availableAt` (same), optional `sourceUrl` (HTTPS). Existing `done` and `notes` remain student-owned. New imported tasks begin unfinished. Omitted tasks remain; an absence can be a partial scan, not a deletion.

Source fields: `id`, `label`, `status` (`verified`, `partial`, `blocked`, `demo`), `checkedAt` (ISO timestamp or null), optional `note`. A non-verified import cannot advance its prior successful timestamp.

Course fields: `id`, `name`, `marks`, `schemes`. Each mark has `id`, `title`, `score` (percentage or null). A scheme has `name` and `components`; each component has `weight` (course percentage points), `itemIds` and `aggregation`:

- `single`: exactly one assessment ID.
- `mean`: equal weights; set confirmed `totalItems`, including ungraded future assignments. The denominator still includes only recorded items' individual weights.
- `best`: the best numeric mark among listed IDs. Until all are recorded, the result is provisional.

Every imported course record is a complete replacement for that course's grade data. Preserve earlier verified marks when preparing it. A UI export is a backup state, not a source packet or blind overwrite command.

## Private API

| Endpoint | Method | Contract |
|---|---|---|
| `/api/login` | POST | `{key}`; generates HttpOnly/SameSite session cookie |
| `/api/logout` | POST | Invalidates the current server session |
| `/api/state` | GET | `{instanceId, state}`; authenticated, no-store |
| `/api/operations` | POST | `{id, expectedRevision, type, ...}`; authenticated, same-origin |
| `/api/widget-plan` | GET | Version 1 saved-schedule feed for native widgets |

Operations: `complete` with taskId/done; `reminder` with task; `block` with full block; `removeBlock` with blockId. A block has id/title/course/kind, ISO startAt/endAt and optional taskId/location. It must begin/end within a planner calendar day. Input times entered in the browser use the device timezone; the UI labels that timezone explicitly.

Write requests require an `Origin` exactly matching local configuration. Responses never allow cross-origin reads. Reused operation IDs must have identical content. Old revisions return 409 and the current state; they do not overwrite it. Operation and receipt writes occur in the same SQLite transaction.

The server is intentionally single-owner; never add another student's account to the same database. There is no machine API token or unprotected course upload route. The local import CLI accesses the database directly with a previewed revision.

## Phone feed

The native app receives `/api/widget-plan` through its authenticated same-origin WKWebView, or imports an exported `.campusplan` file. It includes generatedAt, planDate, timeZone, revision, validUntil and events. Only today's work and up to seven future days of confirmed classes are exported. Completed task blocks disappear. The feed expires at the next midnight in the configured IANA timezone, including daylight-saving transitions.

All event links resolve to the configured planner origin. Swift validates size, timestamps, event IDs and links before writing the private App Group cache. Widgets and reminders read this cache, not the university account.
