# 30. Workspaces: one isolated space per person

With workspaces on, anyone who signs in gets a workspace of their own and is its admin. They connect their own databases, issue their own tokens and invite their own teammates. They never see anyone else's connections, content, tokens or audit log. This is the same idea as organizations in Sanity.

**Status:** built and tested against a fake Firebase and a fake Firestore (9 tests). Not yet run on a real Vercel, Firestore and Firebase setup. Try it with two accounts before you rely on it.

## Two kinds of people

| Who | Where they land |
|---|---|
| People named in the gateway's own settings (`SETHUCMS_FIREBASE_ADMINS` and friends) | The **main** workspace, exactly as before. Their sign-in answer has `workspace: null` |
| Everyone else with a verified e-mail address | A workspace made for them, where they are admin |

The owner of the deployment (the first group) keeps the main workspace and its connections. Nobody in a personal workspace can reach it.

## Turn it on

| Setting | Meaning |
|---|---|
| `SETHUCMS_WORKSPACES=open` | Turns workspaces on |
| `SETHUCMS_WORKSPACE_SECRET` | 24 or more random characters (`openssl rand -hex 32`). Signs workspace ids and derives each workspace's private bootstrap token. Falls back to `SETHUCMS_VAULT_KEY` |
| `SETHUCMS_FIREBASE_AUTH_PROJECT`, `SETHUCMS_FIREBASE_AUTH_API_KEY` | Required: workspaces use Firebase sign-in (doc 21) |
| `SETHUCMS_FIREBASE_DOMAINS` | Optional. Only these e-mail domains may open a workspace |

The gateway refuses to start when workspaces are on without Firebase sign-in, without a long enough secret, or together with PostgreSQL shared state (use Firestore or a data folder).

## How it stays isolated

- Each workspace is a complete gateway of its own: its own state (Firestore collections with the prefix `<prefix>_<id>`, or a data folder `workspaces/<id>`), connections, tokens, people, invites, files and audit log. There is no shared table to forget a filter on.
- A workspace is reached at `/w/<id>/v1/...`. The id is minted only at sign-in and carries a signature, so an invented id gets `404` without any lookup and nobody can make the server create workspaces by guessing addresses.
- A personal workspace has no OIDC or GitHub sign-in, cannot reach private networks (`allowPrivateNetworks` is off), has no demo data, no metrics endpoint and no background worker. The owner's schema file (doc 29) does not apply to it.
- The built-in admin of a workspace uses a token derived from the secret. Nobody ever sees it.
- A deployment keeps up to 8 workspaces open per instance. The least recently used idle one is closed and reopened on its next request.

## Sign in and teammates

1. A person clicks Google or GitHub. The admin app sends the Firebase ID token to `POST /v1/workspaces/signin`.
2. The gateway checks the token. For a verified address it creates the workspace if needed, records the person as its admin and returns `{ token, expiresAt, name, role: "admin", workspace }`.
3. The admin app remembers the workspace and sends every later request to `/w/<id>/v1/...`.
4. To add a teammate, an admin opens Access and invites an e-mail address. The page shows an invite link that ends in `?workspace=<id>`. The invited person signs in at `/w/<id>/v1/auth/firebase`, which accepts only invited addresses.

## Not built yet

- Quotas per workspace (connections, storage, requests).
- More than one organization per person.
- Billing and plans (doc 27).
