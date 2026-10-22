# Start here: AI setup runbook

You are setting up **Campus Companion**, a single-student, Brightspace-first planner. Do not reconstruct its design or read an old conversation. Follow this checklist and open linked references only when the step needs them.

**Cost expectation:** Initial setup can use a lot of tokens: installation, account/source discovery, syllabus interpretation and cross-device checks are front-loaded. Maintenance should use far fewer because it processes changed evidence and uses deterministic code. Explain this before the first broad course review. Do not invent a token estimate or guarantee.

## 1. Inspect, do not overwrite

- Read `AGENTS.md`, `package.json`, and any existing `setup-state.local.md`.
- Verify Node 24+, the repository path and whether `.local/config.json` already exists. Never print that file or the login key into a tool transcript.
- Run `npm test`. Do not install dependencies; this app has none.
- If configured already, resume the next incomplete check. Setup is idempotent by refusing replacement.

## 2. Start a local planner

- Ask whether the user wants a fictional demo or an empty planner if not already clear.
- Run `npm run setup -- --demo` for a demo, or `npm run setup` for real use. Then `npm start`.
- Open `http://localhost:4173`. Have the user enter the generated key from `.local/login-key.txt` locally. Verify the app opens.
- Add, complete and reopen a harmless reminder. Reload and verify it persists.
- Record the completed checks in `setup-state.local.md`, without secrets. Use [SETUP.md](docs/SETUP.md) for details.

## 3. Connect the student's own course sources

Ask only for missing information: institution/LMS URL, timezone, enrolled courses/sections, and whether email or external tools are in scope. Never inherit the demo's classes or another student's IDs.

Use the AI product's supported browser integration and the student's signed-in profile. In current Codex/ChatGPT desktop, use Settings → Computer Use and the browser extension, then mention @Chrome or the exact tab. Website access is separate from filesystem Full Access. Full Access can be used if deliberately needed for local work, but it does not sign in or grant website permission; do not require it universally. The student handles MFA and unavailable credentials. [SETUP.md](docs/SETUP.md) links to current official guidance.

Inspect [BRIGHTSPACE.md](docs/BRIGHTSPACE.md), then establish one complete baseline for the agreed courses. Use `examples/source-packet.json` and [DATA.md](docs/DATA.md). Dates, points and weights come from actual sources. Unknowns stay null. Record blocked sources as blocked.

## 4. Preview, import, verify

Write the private packet to `source-packet.local.json` and run:

```bash
npm run import -- source-packet.local.json
npm run import -- source-packet.local.json --apply --revision N
```

Use the exact revision printed in the preview, after reviewing changes. If it changed, re-preview. Verify at least one deadline and one grade calculation against their sources. Preserve checkmarks and notes. Remove fictional records only through a deliberate fresh private data directory or a separately reviewed migration; never silently reset a working database.

## 5. Add the phone only when requested

Read [DEPLOYMENT.md](docs/DEPLOYMENT.md) and [PHONE.md](docs/PHONE.md). Configure private HTTPS hosting, use the same server on both devices, and test a completion round trip. PWA installation is the simplest path. Native iOS is optional and requires Xcode, the student's signing identity and an App Group. Do not claim installation, widget delivery or remote sync until tested on the actual device.

## 6. Make maintenance cheap

Read [TOKEN-FRAMEWORK.md](docs/TOKEN-FRAMEWORK.md). Start each later review with `npm run context`, the saved setup state and changed source IDs. Do not reload the whole repo or every course document.

Create a recurring task only if requested, using the user's AI software's supported scheduler and chosen cadence. A laptop browser session needs an available laptop; hosting the planner does not move that session to the cloud. Keep a blocked state instead of reporting false success. No perpetual retry loops.

## Done means verified

Report: working local app, verified source coverage, imported revision, phone status, and any blockers. The project is partially configured if any requested stage is incomplete. Leave a private setup-state note with the next concrete step. This makes follow-up questions answerable without repeating setup.
