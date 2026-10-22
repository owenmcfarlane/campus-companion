# Validation record

Release preparation: 22 October 2026. All sample course records are fictional.

## Automated checks

`npm test` covers known-mark denominators, explicit zeros, bonus scores above 100, alternative grading schemes, stable IDs, preserved completion and notes, failed-source timestamps, atomic imports, idempotent sync receipts, stale-device conflicts, rollback, authentication, same-origin writes, private file access and timezone-aware phone feeds.

`npm run check` checks JavaScript syntax, local documentation links and common private-data publication hazards. This complements a manual staged-file review; it is not a comprehensive security audit.

The iOS app and widget compile successfully for a generic iOS simulator with signing disabled. The public project uses placeholder host/bundle values and contains no Apple signing team.

## Browser checks

The local demo was opened in the browser and its desktop planner, grade calculations and narrow phone layout were inspected. Documentation images are captures of that app, not mockups.

- Completing a task inline persisted after a reload.
- With the server deliberately stopped, reopening that task showed “Saved on this device.” Reloading offline retained the choice and loaded the cached app shell.
- After restarting the server, Sync changed the status to “Synced” and preserved the queued choice.

These checks used fictional records in a local browser. They do not substitute for the recipient's physical-phone round trip.

## What requires the recipient's own verification

- Their institution's Brightspace session, enrolled sections, source coverage and grading policy.
- HTTPS hosting, durable storage, backups and a completion round trip on their real phone.
- Apple provisioning, installation, widget placement and notification delivery on a physical iPhone.
- Any external LMS, email, institution API, hosting provider or third-party AI product adaptation.

Do not promote a simulator build or a browser viewport image into a claim that these device/account checks passed.
