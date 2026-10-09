# 15. Deploy to production

This page is the checklist for running the gateway and admin app for real use. It is written for people and for coding agents.

**Status:** the steps below follow the code and the Dockerfile as written. The gateway, its secrets handling and its production checks are tested. The container image, the compose and Kubernetes files and the GitHub workflows have **not** been run end to end yet, so do the "Verify" steps before trusting any of them. What has been checked: the same build steps the Dockerfile runs, run from a clean copy of the four repositories on Node 22, build everything; the resulting gateway starts in production mode, refuses to start with a missing secret, serves the admin app, and creates a SQLite connection inside `SETHUCMS_SQLITE_DIR` while refusing a path outside it. What has not: `docker build` itself (Docker Hub was not reachable from the test machine), the running container, and `docker/compose.demo.yml`.

## What you deploy

One container. It runs the gateway and serves the built admin app from the same address, so there is one port (8080), one URL and no extra CORS setup.

```mermaid
flowchart LR
  U[Browser or SDK] -->|HTTPS| P[Reverse proxy or load balancer: TLS]
  P -->|HTTP 8080| G[Gateway container + admin app]
  G --> V[(Volume /data: connections, drafts, tokens, audit log)]
  G --> D1[(Customer database 1)]
  G --> D2[(Customer database 2)]
```

## 1. Build the image

Needs the four repositories side by side (`sethucms`, `sethucms-adapter-sdk`, `sethucms-adapters`, `sethucms-admin`).

```sh
cd ~          # the folder that holds them
docker build -f sethucms/docker/Dockerfile.gateway -t sethucms .
```

Or let GitHub build it: push a tag such as `v0.1.0` to the `sethucms` repository. The release workflow pushes `ghcr.io/<owner>/sethucms:<version>`.

## 2. Create the secrets

Make each one once and keep them in a secrets manager (not in git, not in chat):

```sh
openssl rand -base64 32    # SETHUCMS_VAULT_KEY
openssl rand -base64 32    # SETHUCMS_CURSOR_SECRET
openssl rand -base64 32    # SETHUCMS_PREVIEW_SECRET
openssl rand -hex 32       # SETHUCMS_ADMIN_TOKEN (your first administrator)
```

**Back up the vault key separately.** Without it, saved database passwords and drafts cannot be decrypted, even from an intact backup. Changing it makes existing connections unreadable.

**Use Node 22 or newer** in the image. The SQLite adapter needs `node:sqlite` (Node 22.5+). The Dockerfile was written before the SQLite adapter existed; check its `FROM node:` line. Add the peer driver for any adapter you use (`mysql2`, `mongodb`, `@google-cloud/firestore`).

## 3. Run it

```sh
docker run -d --name sethucms --restart unless-stopped \
  -p 127.0.0.1:8080:8080 \
  -v sethucms-data:/data \
  -e SETHUCMS_VAULT_KEY=... -e SETHUCMS_CURSOR_SECRET=... \
  -e SETHUCMS_PREVIEW_SECRET=... -e SETHUCMS_ADMIN_TOKEN=... \
  -e SETHUCMS_TRUST_PROXY=true \
  sethucms
```

In production mode the gateway refuses to start if any secret is missing, turns off the demo connection and, by default, private-network database access. Set `SETHUCMS_ALLOW_PRIVATE_NETWORKS=true` only if your databases really are on a private network you control. Metadata addresses stay blocked either way.

Put a reverse proxy or load balancer in front for HTTPS. Set `SETHUCMS_TRUST_PROXY=true` **only** when such a proxy is in front, and not otherwise (it makes the gateway believe `X-Forwarded-For`).

## 4. Settings reference

| Setting | Production value |
| --- | --- |
| `NODE_ENV` | `production` (set in the image) |
| `PORT` | `8080` |
| `SETHUCMS_DATA_DIR` | `/data` (a persistent volume) |
| `SETHUCMS_ADMIN_DIR` | `/w/sethucms-admin/dist` (set in the image) |
| `SETHUCMS_ALLOWED_ORIGINS` | Only needed if a site on another address calls the API |
| `SETHUCMS_TRUST_PROXY` | `true` behind your proxy, otherwise leave off |
| `SETHUCMS_ALLOW_PRIVATE_NETWORKS` | Off unless needed |
| `SETHUCMS_SQLITE_DIR` | Folder for SQLite files, for example `/data/sqlite`. Unset = SQLite files are disabled |
| `SETHUCMS_FORCE_LOCK` | `1` starts despite a live data-folder lock. Recovery only |

The full list with comments is in `apps/api/.env.example`.

## 5. Verify (do this every time)

```sh
curl -fsS https://your-host/v1/health     # {"status":"ok"}
curl -fsS https://your-host/v1/ready
```

Then sign in with the admin token, add a connection to a test database, expose one collection, create a draft, preview it and publish. Check that **Audit** shows the publish.

## 6. Day-two operations

- **Back up** the `/data` volume (connections, drafts, tokens, audit log) and the secrets. Test a restore.
- **Token expiry and rotation.** When you create a token under **Access** you can give it a lifetime (30 days, 90 days, 1 year or none). An expired token stops working and is shown as expired. **Replace** creates a new token with the same name, role and lifetime and keeps the old one working for 60 more minutes so you can switch over, then it expires. Replace the admin token this way, sign in with the new one, and revoke the old one early if you want. The token value is shown once.
- **Backups.** Stop the gateway or take a filesystem snapshot of `/data` (a copy of a running gateway can catch a file mid-write). Back up the secrets separately. For SQLite connections back up `/data/sqlite` with the SQLite backup command or while stopped. Run a restore test, including starting a gateway on the restored folder.
- **Upgrade:** build or pull the new image, stop the old container, start the new one on the same volume and secrets, run the Verify steps. Keep the previous image for rollback.
- **Logs:** one JSON line per request on **stderr** (see doc 16), with secrets removed. Send them to your log system and alert on 5xx and on repeated 401/429.
- **Database users:** give each connection a database user with the fewest rights you can. Keep new connections read-only until editing is needed.

## 7. Known limits (plan around them)

- **One gateway process per data volume.** State is a file, and rate limits, idempotency keys and live events are per process. The gateway now writes `gateway.lock` in the data folder and **refuses to start** if another live gateway holds it (a lock not refreshed for 30 s is treated as abandoned after a crash). That stops accidental double starts on one machine or volume. It is a guard, not clustering: on network file systems with unreliable timestamps it may not detect a second host. Do not run two replicas on the same data. A shared state store is future work.
- Three fixed roles. No single sign-on yet. Tokens are static bearer tokens (with optional expiry and rotation).
- Live events show only changes made through the gateway.
- The image still contains development dependencies, so it is larger than needed.
- Deploy workflows (Terraform apply, Kubernetes rollout) are not written. `sethucms-infra` still describes an older layout and must be updated to run `Dockerfile.gateway` before you use it.

## 8. Checklist for an agent doing a deploy

1. Read `AGENTS.md` in the `sethucms` repository.
2. Confirm the tests pass: core, gateway, admin type check.
3. Build the image; confirm it starts with all secrets and **refuses** to start with one missing.
4. Confirm `/v1/health` and `/v1/ready`.
5. Never print secrets or tokens in logs, chat or files. Never commit them.
6. Do not run `git commit`, `git push`, `terraform apply` or any change to a live environment unless the owner has said to.
7. Report exactly what was verified and what was not.
