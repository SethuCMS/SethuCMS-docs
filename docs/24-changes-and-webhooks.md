# 24. Change feed and webhooks

Every create, update and delete made **through the gateway** gets a number in an ordered feed.

## Reading the feed

`GET /v1/changes?since=<n>&limit=<k>` returns `{ data, next, head, gap }`. Keep `next` and ask for it next time to resume. `gap: true` means the feed no longer holds changes from your `since`; do a full re-read. Callers only see changes to records they are allowed to see.

## Webhooks (admin only, API only)

- `POST /v1/admin/webhooks` `{ name, url, events }` (`events` is a list of event types, or `["*"]`) returns the signing secret `whsec_…` **once**. Also `GET`, `PATCH /:id`, `DELETE /:id`, and `GET /:id/deliveries`.
- Delivery is at least once. Use the `X-Sethu-Delivery` header (`evt_<number>`) to ignore repeats.
- In production the URL must be https. The address is checked by the network guard on every attempt, the connection is pinned to the checked IP, redirects are not followed, 10 s timeout.
- Retries wait 10 s, 30 s, 2 min, 10 min, 30 min, 1 h, 3 h; after 8 attempts the delivery is marked dead.

Verify a delivery (Node):

```js
import { createHmac, timingSafeEqual } from 'node:crypto';
function verify(rawBody, header, secret) {
  const parts = Object.fromEntries(header.split(',').map((p) => p.split('=')));
  if (Math.abs(Date.now() / 1000 - Number(parts.t)) > 300) return false;
  const expected = createHmac('sha256', secret).update(`${parts.t}.${rawBody}`).digest('hex');
  const a = Buffer.from(expected), b = Buffer.from(parts.v1 ?? '');
  return a.length === b.length && timingSafeEqual(a, b);
}
```
Header: `X-Sethu-Signature: t=<unix>,v1=<hex>`.

## Not built

- **Native change capture.** MongoDB change streams, Postgres logical decoding and Firestore listeners are not used. Changes made directly in the database, bypassing the gateway, do not appear.
- No admin app screen for webhooks yet.
- Live events (SSE) cannot resume with `Last-Event-ID`; use the feed to catch up.
- The file-based feed keeps up to one second of changes at risk in a crash; the Postgres feed does not.

**Status:** tested (16 tests plus a standalone worker with two gateways on Postgres 16). Not tested against real receivers on the internet.
