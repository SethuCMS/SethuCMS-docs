# 26. Hosted gateway, admin app and your first content connection

This page covers the first live setup: the gateway on Vercel, the admin web app that comes with it, and how a website reads its content from a database it owns. It is written from the real 0.1.0 launch, including the mistakes worth avoiding.

## What is running

| Piece | Where | Notes |
|---|---|---|
| Gateway and admin web app | Vercel, one origin | The admin app is served by the gateway. It uses a hash router and keeps the sign-in token in `sessionStorage`, so closing the tab signs you out |
| Gateway state | A Firestore project, collection prefix `sethucms` | Connections, tokens, sessions, the audit log, idempotency answers. Serverless functions share no disk, so state must live in a database (doc 22) |
| Your content | Your own database, added as a **connection** | Kept separate from the state project |
| Packages | npm, scope `@sethucms`, version 0.1.0 | Ten packages: core, adapter-sdk, sql-kit, postgres, mysql, sqlite, mongodb, firestore, memory, sdk-ts |

Keep two Firebase projects: one for the gateway's own state and one for your content. If they are the same project, the state collections (connections, tokens, audit) sit next to your content and are one mistake away from being exposed.

## Sign in to the admin app

1. Open the gateway address in a browser.
2. Paste the admin token. It is an **admin** token created when the gateway first started; it is not a viewer token.
3. Create a separate viewer token for each website (Access, then New token). Give it the least role it needs.

Treat the admin token like a root password: never paste it into a chat, a ticket or a screenshot, and clear your terminal after printing it.

## Add your content database

In the admin app go to Connections, then Add, then choose Firestore. You need:

- `projectId`: the Firebase project that holds your content.
- `databaseId`: leave as `(default)` unless you made a named database.
- A **service-account key** (JSON) for that project. Download it from the Firebase console, store it as a file with mode 600, and paste it into the credentials box. The vault encrypts it; it is never shown again.

Then set:

- **Mode: read only.** A website that only shows content never needs to write.
- **Expose: none.** Start with every collection hidden, then expose only the ones the site reads, for example `projects`.

Check the result with the connection detail page. It should list only the collections you chose as exposed, and the health check should be green.

### The mistake to avoid

During the launch the first connection was created with expose set to all, and it was pointed at the state project. That published twelve internal collections (connections, tokens, audit and others) to every viewer token. The connection was deleted, every token revoked and new ones issued. The rules that came out of it:

- Never use `expose: all` on a project that also holds gateway state.
- Create connections with `expose: none` and add collections one at a time.
- After any change, list what a viewer token can see (`GET /v1/connections/:id/collections`) and confirm it is only what you intended.

## Read the content from a website

Install the SDK in the website, never in browser code that a visitor can inspect.

```sh
npm install @sethucms/sdk
```

Put three values in the website's server environment:

| Variable | Value |
|---|---|
| `SETHUCMS_BASE_URL` | The gateway address (https) |
| `SETHUCMS_TOKEN` | A **viewer** token made for this site |
| `SETHUCMS_CONNECTION_ID` | The id of the content connection (it starts with `conn_`) |

```ts
import { SethuClient, eq } from '@sethucms/sdk';

const cms = new SethuClient({
  baseUrl: process.env.SETHUCMS_BASE_URL!,
  token: () => process.env.SETHUCMS_TOKEN!,
});

export async function listProjects() {
  return cms
    .collection(process.env.SETHUCMS_CONNECTION_ID!, 'projects')
    .where(eq('published', true))
    .limit(50)
    .list();
}
```

In Next.js, call this from a Server Component or a route handler and cache the page (for example `revalidate: 60`) so the gateway is asked at most once a minute, not once per visitor. The token stays on the server.

## The state store in serverless mode

Several functions can handle requests at the same moment, so the shared state store updates the state document with a revision check: read the revision, write the change only if the revision is unchanged, otherwise wait a short random time and try again, up to twenty times. If all twenty attempts lose, the request fails with a clear error instead of overwriting someone else's change.

The audit log in this mode writes one document per entry. Each entry carries an ascending **newest-first key** (a padded timestamp counter subtracted from a large constant), so "latest entries" is an ascending scan with a limit. This is done because the Firestore emulator, and some Firestore setups, do not support descending key scans.

**Status:** seven live tests pass against the Firestore emulator (concurrent updates, revision conflicts, audit order across two gateways). The Firestore content adapter itself is still lightly tested; run it against a test project before relying on it (doc 18).

## Operating notes

- Redeploy after changing code: build the Vercel bundle, then deploy it to production. Environment variables are read at deploy time.
- Turn off Vercel Deployment Protection for the gateway project, otherwise browsers and the SDK get a login page instead of JSON.
- Rate limits are per function instance, so the real limit is higher than the configured one (doc 22).
- Rotate any secret that has been pasted into a chat, a screenshot or a terminal log. Revoke one-day publishing tokens as soon as the release is done.
