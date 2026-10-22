# A larger setup, a much smaller maintenance loop

**Initial setup can take a lot of tokens. Routine upkeep should take far fewer.** The first pass must discover the institution's course structure, confirm access, interpret syllabi and grading policies, map stable IDs, configure the phone and validate results. Those are substantial tasks; do not sell setup as a one-prompt, nearly-free process.

The recurring loop reuses that work. Token savings come from smaller context and fewer model calls, not from skipping required sources. There is no universal percentage saving, fixed token budget or promise of accuracy without verification.

## Route work by what actually needs reasoning

| Work | Default route |
|---|---|
| Dates, sorting, grades, hashes, imports, sync, rendering | Local code; no model inference |
| Course-list review and extraction of changed facts | An available economical capable model |
| A source conflict, grading-policy ambiguity or progress-loss risk | Stronger reasoning on just the affected records |
| A new schedule or major design change | One scoped planning pass |
| No change, waiting for Wi-Fi, repeated status checks | No planning pass; no idle model polling |

Choose model names from the recipient's actual product. Availability and prices change; do not hardcode the original author's model lineup. This repo does not switch a chat's model or create agents itself.

## The small recurring packet

1. Read `setup-state.local.md` and run `npm run context` once.
2. Check complete current announcements, calendar, assessment/grade lists and content indexes for the selected courses. Handle pagination. Include email/external tools only if explicitly configured.
3. Inspect changed entries and their linked instructions. Reuse stable documents only when a trustworthy version check says they are unchanged; unknown versions require reinspection. Review relevant material again for imminent deadlines or conflicts.
4. Store the extracted facts, source links, successful review times and unresolved gaps in the private import packet. Do not send entire chat histories, screenshots, PDFs or the whole repository to every reasoning step.
5. Fetch full task details only for affected IDs: `npm run context -- TASK_ID`. Produce one import per changed batch. No change means no import and no replanning.
6. Preview, apply against the expected revision, then verify the affected result. Report changes and blockers briefly.

The compact summary currently retains a full small identity catalog. If a deployment grows large, add bounded selection without dropping overdue, undated or conflicting tasks. Fewer tokens do not justify incomplete coverage.

## Stop conditions

One ordinary retry is enough before diagnosis. Permission denials, MFA, uncertain saves, login failures and revision conflicts need a concrete resolution. Do not run repeated expensive agents while the laptop is locked or offline. A failed check leaves the last successful source receipt intact and records the failure separately.

Source review, server import and device sync have separate success checks. Cloud hosting can sync saved data while the laptop sleeps; it cannot inspect the laptop's signed-in browser. A recurring schedule must be created using the user's actual scheduler, with an explicitly chosen cadence. A prompt file alone is not an automation.

## Measure without inventing numbers

Record actual model input/output tokens only when the platform exposes them. Otherwise record calls, elapsed seconds and context bytes separately, with token usage unknown. Do not label byte counts as tokens or subscription usage as API charges. Compare runs with the same verified coverage. The goal is a smaller accurate maintenance loop, not a misleading low number obtained by doing less work.
