# Private deployment

The source repository is public; each student's running application and data must remain private. GitHub Pages cannot run this Node/SQLite backend.

## Smallest deployment

Use a Node 24+ host with a persistent local disk and an HTTPS reverse proxy. One server process and one data directory serve one student. Do not run independent replicas against copied databases or place SQLite on an unreliable network share.

1. Clone the repository to the host. Run `npm test` and `npm run check`.
2. Set `CAMPUS_ORIGIN=https://your-real-hostname` and `CAMPUS_TIMEZONE` before running `npm run setup`. Keep the generated key private. Existing installations should edit only the non-secret origin/host/port fields in their local config after stopping the server.
3. Keep the Node listener at 127.0.0.1:4173 when the reverse proxy is on the same machine. Proxy the entire HTTPS origin to it. Do not expose Node's plain-HTTP port to the public internet.
4. Use your hosting provider's process manager to run `npm start` from this directory. Ensure the data directory survives restarts and deployments.
5. Open the exact HTTPS origin, sign in and test both devices. Secure session cookies are automatically enabled for an HTTPS origin. No broad CORS allowlist is needed.

Example Caddy reverse-proxy block, after configuring your own DNS and installing Caddy from its official distribution:

```text
planner.your-real-domain.example {
    reverse_proxy 127.0.0.1:4173
}
```

The example hostname is not a service. Use one you control. Public DNS/certificates, hosting costs and provider accounts are separate setup steps. The AI assistant should present concrete options and get the user's choice before creating paid resources.

## Container option

The supplied Dockerfile uses Node 24, no package installation, and an unprivileged user. Build with `docker build -t campus-companion .`. Mount a private persistent volume at `/data` and set `CAMPUS_DATA_DIR=/data` for setup and start. Run setup inside the container once; configure its host as `0.0.0.0` for container networking and its origin as the external HTTPS address. Route port 4173 through your HTTPS proxy. Do not expose a remote HTTP origin or log the generated key.

## Backups and updates

Use the app's Export for a human-inspectable data copy. Preserve the private data directory using a SQLite-aware backup process or stop the service before copying its database and associated WAL files. Backups contain private records and should be encrypted/access-controlled by the host.

Before updating, inspect the changelog, back up, and sync pending edits on all devices. Pull the reviewed release, run tests, restart, then verify phone sync. Service-worker updates do not force-reload active clients. Close/reopen the app after saving to activate a new cached shell. Never delete local browser data while it contains unsynced work.

The web export is not an automatic restore endpoint. For recovery, stop edits, preserve the current database, inspect the backup schema, and perform a deliberate reviewed migration. Do not blindly overwrite newer progress with an older export.
