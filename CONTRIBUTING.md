# Contributing

Keep Campus Companion small, portable and independent of one student's account. Open an issue describing the problem and a minimal fictional reproduction. Do not post private course records, grades, screenshots, tokens or institutional documents.

For a change:

1. Create a focused branch. Reproduce the issue with fictional fixtures.
2. Preserve stable IDs, explicit unknown grades, user completion and unsynced edits.
3. Run `npm test` and `npm run check`. Test the affected browser flow. For iOS changes, compile the simulator target; label physical-device tests separately.
4. Update the relevant guide and CHANGELOG.md. Refresh screenshots only if the visible behavior changes materially.
5. Bump the static cache version for client releases; do not force-reload pending work.
6. Review the staged diff for personal data and secrets before pushing or opening a PR.

Reusable fixes developed in a personal installation should be ported here with configuration and fictional fixtures. Personal deadlines, marks, account/host details, one-course overrides and private documents stay in the personal installation. Do not blindly mirror whole working directories or Git histories. A maintainer can review and merge independently of the student's personal deployment.

Adding a model or service is not the default fix for deterministic work. New dependencies should solve a concrete problem and include their license and operational cost. Model routing should use the recipient's actual available products, not the author's old model names.
