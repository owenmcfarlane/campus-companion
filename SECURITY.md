# Security and privacy

This is a single-student self-hosted application, not a multi-user university system. It has not undergone an independent security audit.

- Keep `.local/`, login keys, SQLite files, imports, backups and configured native copies private.
- Use HTTPS for remote access and a private persistent disk. The server rejects non-loopback HTTP origins. Protect the host with normal OS controls and keep Node updated.
- Sessions use HttpOnly, SameSite=Strict cookies and Secure on HTTPS. Write requests require the configured Origin. Login attempts are rate-limited per process/remote address; use a trusted reverse proxy's own limits for Internet deployment. Restarting the app resets the in-memory limiter.
- A reverse proxy's client-IP headers are not trusted by this app. Shared proxy traffic may share a rate-limit bucket.
- The browser's offline data is not encrypted by the application. Use a trusted device and sign out when appropriate. Sign out cannot proceed until pending edits are saved.
- Source packets are validated but may contain sensitive student data. Never import unreviewed content from another student's account.
- The Swift bridge checks the exact configured origin and validates the schedule before storing it. Review the actual host, timezone, entitlements and signing in your private build.
- No university credentials, browser cookies or hidden API keys are collected by this repository.

For a suspected vulnerability, use GitHub's private vulnerability reporting if enabled. Otherwise open a minimal issue asking for a private reporting channel without exploit details or private data. Do not post active credentials. Rotate compromised planner keys and revoke server sessions through a deliberate local administrative recovery; do not distribute the replacement key publicly.
