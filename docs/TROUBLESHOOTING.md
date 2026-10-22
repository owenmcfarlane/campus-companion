# Troubleshooting

Start with the relevant row. Do not restart setup or repeatedly scan every course.

| Symptom | Check and next action |
|---|---|
| `node:sqlite` unavailable | Use Node 24+. Confirm `node --version` in the same terminal that starts the app. |
| Port 4173 in use | Stop only the process you own or choose a different port in private config and update origin to match. |
| “Run npm run setup first” | Confirm working directory and CAMPUS_DATA_DIR. Never generate a replacement database just to hide a path mistake. |
| Login key rejected | Read your own private login-key.txt locally; check you reached the intended server. Ten failed attempts trigger a ten-minute cooldown. |
| Origin mismatch | Match scheme, hostname and port exactly. localhost and 127.0.0.1 differ. For deployment use the public HTTPS origin, not the proxy's internal address. |
| Assistant cannot see Brightspace | Check supported browser integration, correct signed-in profile, site permission and MFA. Full Access alone does not solve this. Stop on denial and explain the specific permission. |
| Course missing | Confirm enrollment/section and the complete source list. Do not reuse another student's course ID. |
| Source marked blocked | Resolve the actual login/network/content issue and review that source. Do not advance its successful timestamp manually. |
| Missing grade | Unknown stays null. Find the returned mark and verify its scheme; a past due date is not zero. |
| Phone sees different data | Confirm both devices use the same HTTPS server and login. Localhost on a phone is the phone itself. |
| “Saved on this device” | Server unreachable or queue pending. Keep the browser data; reconnect and Sync. |
| Sync conflict | Review queued actions versus server state. Export the journal. Apply your choices or use server state explicitly; no silent overwrite. |
| Lost response after saving | Retry the same operation ID/payload; the server's receipt prevents duplicate application. |
| App looks out of date | Sync first, then close all tabs/Home Screen instances and reopen to activate the new shell. Do not force-clear unsynced data. |
| Native build cannot sign | Verify your Apple team, bundle IDs and App Group in the private Xcode copy. The public template has no team configured. |
| Widget rejects a schedule | Verify identical HTTPS host and timezone in server/native config, current schema and valid dates. Export a new schedule. |
| No phone notification | Enable native reminders, refresh the saved schedule, verify a future block more than twenty minutes away, notification permission and Focus settings. Browser digest is on-demand only. |
| Laptop asleep | Local browser source checks and laptop-hosted sync cannot run. Hosted saved-data sync and previously scheduled phone reminders are separate. |

## A useful support report

Share the repository version, OS/Node version, step you attempted, exact non-secret error, expected versus observed behavior, whether sync is pending, and which checks already passed. Redact names, course records, host keys, cookies and private paths. Never attach `.local/`, a database, a full browser session or login-key.txt to a public issue.

Your AI assistant should read `setup-state.local.md`, run compact context if needed, inspect one relevant guide/code path, reproduce once, and fix the concrete cause. One ordinary retry before diagnosis; no idle polling or blanket reinstalls.
