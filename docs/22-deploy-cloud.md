# 22. Several gateways, and cloud deploys

## Shared state

Set `SETHUCMS_STATE_URL` to a PostgreSQL address and any number of gateways can run against the same state.

What is shared: connections, tokens and sessions, the audit log (one hash chain per gateway process, all verifiable through `/v1/admin/audit/verify`), Idempotency-Key answers, live events (relayed with LISTEN/NOTIFY), the change feed and webhook deliveries (doc 24), and migration job records with a heartbeat so one gateway does not take over a job another is still running.

What is **not** shared:
- **Rate limits are per gateway.** With N gateways the effective limit is up to N times the setting.
- Open database connections stay in the gateway that opened them.
- Token revocation and connection edits reach other gateways within `SETHUCMS_STATE_POLL_MS` (default 1000) or sooner by notification.

Rules in shared mode: secrets must come from the environment (the vault key, cursor secret and preview secret must be the same on every gateway), and the data-folder lock is skipped. Use `SETHUCMS_DATA_DIR=memory` on hosts without a disk.

**Status:** tested with two gateways on a real PostgreSQL 16 (concurrent writes, revocation, audit chains, idempotency across gateways, event relay). Not tested under real load or with a managed Postgres.

## The worker

Webhooks (doc 24) are sent by a worker. By default each gateway runs one inline; deliveries are claimed with `FOR UPDATE SKIP LOCKED`, so several never send the same one twice at the same time. To run it apart: `SETHUCMS_WORKER=off` on the gateways and `node dist/src/worker.js` (same image, different command) with the same `SETHUCMS_STATE_URL` and secrets.

## Deploy workflows

The files are in `deploy/github-workflows/`. GitHub only reads `.github/workflows/`, so copy them there (they could not be written there from the tool that made them).

| File | Does |
| --- | --- |
| `sethucms-ci.yml` | Checks out all four repositories, builds, runs the tests with a Postgres service. |
| `sethucms-release-image.yml` | On a `v*` tag, builds the image and pushes it to GHCR with provenance and an SBOM. |
| `deploy-cloud-run.yml` | Builds into Artifact Registry and deploys to Cloud Run (Workload Identity Federation, secrets from Secret Manager). Uses `--min-instances 1 --no-cpu-throttling` so the inline worker keeps running. |
| `deploy-vps-compose.yml` | Copies `compose.production.yml` and the Caddyfile to your server over SSH (pinned host key) and restarts. Secrets stay in `/opt/sethucms/.env` on the server. |

Before first use: set the repository variables named at the top of each file, and set `SETHUCMS_OWNER` if the other three repositories are under another owner. Pin the actions to commit SHAs (they use version tags now; the SHAs could not be looked up when they were written).

**Status:** the YAML parses and passes actionlint. None of the workflows, the image build, the compose file or Caddy have been run. Expect to fix small things on the first run. The image is built for amd64 only.
