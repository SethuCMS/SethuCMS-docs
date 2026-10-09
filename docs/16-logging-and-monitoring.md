# 16. Logging and monitoring

What the gateway tells you while it runs, and how to watch it. Everything here is built in and tested; no extra package is needed.

## Where things go

| What | Where | Format |
|---|---|---|
| Operational log (requests, errors, migrations, start-up problems) | **stderr** | one JSON object per line (or readable text) |
| Start-up banner (address, first admin token if one was made) | stdout | plain text |
| Audit log (who changed what) | `<data dir>/audit.log` | one JSON object per line, hash-chained |
| Metrics | `GET /v1/metrics` | Prometheus text |

Logs go to **stderr**, not stdout. Docker, Kubernetes and systemd collect both streams, so `docker logs` shows them either way. If you redirect a stream yourself, redirect `2>` to capture the log.

## Settings

| Variable | Default | Meaning |
|---|---|---|
| `SETHUCMS_LOG_LEVEL` | `info` | `debug`, `info`, `warn` or `error` |
| `SETHUCMS_LOG_FORMAT` | `pretty` at a terminal outside production, else `json` | `json` or `pretty` |
| `SETHUCMS_SLOW_REQUEST_MS` | `1000` | requests slower than this are logged as warnings |
| `SETHUCMS_AUDIT_MAX_MB` | `10` | rotate the audit log at this size |
| `SETHUCMS_AUDIT_KEEP` | `5` | rotated audit files to keep |
| `SETHUCMS_METRICS_TOKEN` | unset | lets a scraper read metrics without an admin token |

A bad value stops the gateway at start-up with a message that names the variable.

## What a request line holds

```json
{"time":"2026-10-08T16:37:06.254Z","level":"info","event":"http.request","requestId":"…","traceId":"…","method":"GET","path":"/v1/connections/conn_ab12/collections/articles/records","route":"/v1/connections/:connectionId/collections/:collection/records","status":200,"ms":12,"caller":"tok_9f…","role":"editor"}
```

- `requestId` is also returned in the `X-Request-Id` header and in every error body. A caller's own id is kept when it is 8-64 safe characters, so one id can follow a request through a proxy.
- `traceId` is taken from a W3C `traceparent` header when one is sent.
- `path` never includes the query string. `route` is the pattern, so dashboards can group by it.
- `ip` is added only to 401, 403 and 429 answers.
- `slow: true` is added above the slow-request limit, and the level becomes `warn`. 401, 403 and 429 answers are also `warn`, 5xx answers are `error`, and the health and readiness checks are `debug` so they do not fill the log.
- Unexpected failures write an `error.unexpected` line with the reason. The caller only ever sees a generic `INTERNAL` error.
- Migrations write `migration.start`, `migration.collection` and `migration.finish`.

Never logged on purpose: request bodies, query strings, record values, tokens, passwords. Every field also passes through the redaction filter, which hides keys such as `password` and `token` and credentials inside connection strings.

## Metrics

`GET /v1/metrics` needs `Authorization: Bearer <admin token or SETHUCMS_METRICS_TOKEN>`.

| Metric | Type | Labels |
|---|---|---|
| `sethucms_http_requests_total` | counter | method, route, status |
| `sethucms_http_request_duration_seconds` | histogram | method, route (event streams excluded) |
| `sethucms_http_in_flight_requests` | gauge | |
| `sethucms_errors_total` | counter | code |
| `sethucms_rate_limited_total` | counter | scope |
| `sethucms_events_total` | counter | type |
| `sethucms_event_streams_open` | gauge | |
| `sethucms_connections` | gauge | adapter |
| `sethucms_api_tokens_active` | gauge | |
| `sethucms_audit_entries_total` | counter | |
| `sethucms_migration_records_total` | counter | result |
| `sethucms_process_*` (uptime, memory, heap, CPU) | gauge/counter | |
| `sethucms_event_loop_delay_p99_seconds` | gauge | high values mean the process is overloaded |
| `sethucms_build_info` | gauge | node (the Node.js version) |

Labels are bounded: routes are patterns, never raw paths, and each metric stops adding new label combinations after a fixed limit (`sethucms_metric_series_dropped_total` counts any it ignored). A caller cannot grow memory by inventing URLs.

### Prometheus

```yaml
scrape_configs:
  - job_name: sethucms
    metrics_path: /v1/metrics
    authorization:
      credentials_file: /etc/prometheus/sethucms-metrics-token
    static_configs:
      - targets: ['sethucms:8080']
```

### Alerts worth having

```yaml
- alert: SethuHighErrorRate
  expr: sum(rate(sethucms_http_requests_total{status=~"5.."}[5m])) / sum(rate(sethucms_http_requests_total[5m])) > 0.02
  for: 10m
- alert: SethuSlow
  expr: histogram_quantile(0.95, sum by (le) (rate(sethucms_http_request_duration_seconds_bucket[5m]))) > 1
  for: 10m
- alert: SethuAuthFailures
  expr: sum(rate(sethucms_http_requests_total{status=~"401|429"}[5m])) > 5
  for: 5m
- alert: SethuMigrationFailures
  expr: increase(sethucms_migration_records_total{result="failed"}[15m]) > 0
```

Also alert when `up` is 0 and when the data volume is nearly full.

## The audit log

Every change to connections, content, tokens and drafts is appended to `audit.log`. Each entry carries the hash of the one before it, so editing, removing or reordering a line breaks the chain.

- **Check it:** `GET /v1/admin/audit/verify` (admin, counts as an expensive call) reads every file and reports `ok`, how many entries were checked, and where the chain first breaks.
- **Rotation:** at `SETHUCMS_AUDIT_MAX_MB` the file becomes `audit.log.1`, older ones shift up, and files beyond `SETHUCMS_AUDIT_KEEP` are deleted. The chain continues across files. If rotation deletes the oldest file, `verify` reports `completeHistory: false`.
- **What it proves:** tampering is *shown*, not *prevented*. Someone with write access to the volume can rebuild the whole chain. Keep a copy somewhere the gateway cannot write: ship the file to a log system or object storage with write-once settings.
- Record values appear in audit entries as before/after differences for edits. Treat the audit log as sensitive.

## Shipping logs

Any collector that reads container output works, because each line is one JSON object.

- **Docker:** `docker run --log-driver=json-file --log-opt max-size=20m --log-opt max-file=5 …`, or the `local`, `syslog`, `journald` or `fluentd` drivers.
- **Kubernetes:** nothing to configure; use your cluster's collector (Promtail, Fluent Bit, Vector).
- **Vector example:**
  ```toml
  [sources.sethucms]
  type = "docker_logs"
  include_containers = ["sethucms"]
  [transforms.parse]
  type = "remap"
  inputs = ["sethucms"]
  source = ". = parse_json!(.message)"
  ```
- Also ship `audit.log` (and rotated files) separately; it is not on stderr.

## Honest limits

- Metrics and logs are per process. The gateway is one process per data volume, so there is nothing to aggregate across replicas yet.
- The `GET /v1/ready` check confirms the process is up; it does not test each database.
- Tracing is correlation only (the trace id is copied into logs). No spans are exported.
- Alert rules above are examples, not tested against a live Prometheus.
