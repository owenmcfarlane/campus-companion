# Setup guide

Use [START-HERE.md](../START-HERE.md) as the ordered AI checklist. This page explains the decisions behind it.

## Requirements and first launch

- Node.js 24+ and Git on macOS, Windows or Linux. SQLite is built into Node; no package installation or cloud account is required for local use.
- A private folder you control. Each deployment is for one student.
- An AI assistant with authorized browser control only if you want assisted course review. Manual JSON imports work without AI.
- HTTPS hosting for phone installation/sync beyond localhost. Xcode on a Mac is needed only for the optional native iOS app.

Run `npm run setup` once, then `npm start`. Add `-- --demo` to setup only for fictional sample data. Setup writes a private config, a generated login key and a SQLite database into `.local/`. It refuses to replace an existing configuration.

The configuration's `origin` must match the address actually used in the browser, including its port. `http://localhost:4173` and `http://127.0.0.1:4173` are different origins. Host is initially loopback-only. Edit the local config after stopping the server if you need a different port; change origin and port together.

Before setup, you may set `CAMPUS_TIMEZONE` to your IANA zone, `CAMPUS_ORIGIN` to the final HTTPS origin, or `CAMPUS_DATA_DIR` to another private directory. If using a custom data directory, use it for every command. The default timezone is your computer's configured zone. Do not print configuration or login keys into a public issue.

## Browser access for course review

Use your normal university login in your own browser profile. The planner itself never requests your university password. Connect the AI software's supported browser tool; a cloud assistant does not automatically inherit a laptop's signed-in session.

For the current Codex/ChatGPT desktop workflow:

1. Open **Settings → Computer Use** and select your browser.
2. Install the official plugin/extension when prompted and return to confirm it shows **Manage**.
3. Start the task with **@Chrome** or mention the exact Brightspace tab. Use the profile with your university session.
4. Grant the required website access, preferably scoped to your LMS. Complete MFA and account challenges yourself when needed.
5. Verify that the assistant can read one actual course page, not just a login screen or institution homepage.

**Full Access is a local permission choice, not a Brightspace connection.** It removes local sandbox restrictions; it does not sign in, install the browser connection, or grant website permission. Some workflows may need it deliberately, but narrower permissions can work. Never disable all protections solely because a copied guide says to. See official [browser setup](https://learn.chatgpt.com/docs/chrome-extension) and [permission profiles](https://learn.chatgpt.com/docs/permissions), checked when this repository was prepared. Other AI products need their equivalent supported integration.

## First course baseline

Give the assistant the institution URL, course names/sections and timezone. Confirm optional email/external-tool scope separately. Have it read announcements, the full content index, calendar, assessment/grade lists and relevant syllabus/schedule. See [BRIGHTSPACE.md](BRIGHTSPACE.md).

Create `source-packet.local.json`. Preview with `npm run import -- source-packet.local.json`; then apply with `--apply --revision N`, using the previewed revision. Imports update course facts by stable ID and preserve existing manual completion and notes. Missing rows do not delete tasks. Grade-course records replace that course's grade record as a unit: include all previously verified marks or explicitly review their removal.

Check the result against at least one real source date and one grade calculation. Record coverage gaps as partial/blocked, not as an empty successful review. Never load your records into a public demo server.

## Save setup context once

Keep `setup-state.local.md` private and concise:

```text
Deployment: local or HTTPS URL (no key)
Data directory: private path
Timezone:
LMS and enrolled sections:
Verified browser/tool capabilities:
Source baseline: scopes completed and blocked
Last imported revision:
Phone: web/native, tested or untested
Recurring review: not configured / verified schedule
Next unresolved step:
```

This lets the same or another assistant answer “why isn't this working?” without rediscovering everything. For maintenance read only this file, compact context and the relevant guide. Do not save an entire conversation as setup context.
