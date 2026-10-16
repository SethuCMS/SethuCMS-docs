# 21. Single sign-on (OpenID Connect)

People sign in to the admin app with your company login (Okta, Google Workspace, Microsoft Entra, Keycloak, Auth0 and so on). The gateway never sees their password.

**Status:** tested against a small fake identity provider written for the tests, not against a real Okta, Google or Entra. Try yours in a staging setup first.

## How it works

1. The admin app shows "Sign in with single sign-on" when `GET /v1/auth/config` says it is on.
2. The browser goes to `/v1/auth/oidc/login`, then to your provider (authorization code flow with PKCE).
3. The provider sends the browser back to `/v1/auth/oidc/callback`. The gateway checks the ID token (signature RS256, PS256 or ES256; issuer, audience, expiry, nonce) and maps a claim to a role.
4. The gateway makes a short-lived session token and sends the browser to the admin app with it in the URL fragment (after `#`, which is never sent to a server). The admin app stores it and clears the address bar.

The login attempt is kept in an encrypted, HttpOnly cookie, so the callback may land on any gateway when several share state (doc 22).

## Set it up

Register an application at your provider. Redirect URI: `https://YOUR-CMS/v1/auth/oidc/callback`. Then set:

| Setting | Meaning |
| --- | --- |
| `SETHUCMS_OIDC_ISSUER` | The provider's issuer address (https, except loopback for tests). Turns SSO on. |
| `SETHUCMS_PUBLIC_URL` | The address people use to reach the CMS. |
| `SETHUCMS_OIDC_CLIENT_ID`, `SETHUCMS_OIDC_CLIENT_SECRET` | From the provider. |
| `SETHUCMS_OIDC_SCOPES` | Default `openid profile email`. `openid` is required. |
| `SETHUCMS_OIDC_ROLE_CLAIM` | Claim that holds groups. Default `groups`. |
| `SETHUCMS_OIDC_ADMIN_VALUES`, `_EDITOR_VALUES`, `_VIEWER_VALUES` | Comma-separated group values per role. Highest match wins (admin, editor, viewer). |
| `SETHUCMS_OIDC_DEFAULT_ROLE` | Role for people who match no group: `editor` or `viewer`. Never `admin`. Leave empty to refuse them. |
| `SETHUCMS_OIDC_ALLOWED_DOMAINS` | Optional email domains allowed. Needs `email_verified` true. |
| `SETHUCMS_OIDC_SESSION_HOURS` | Session length. Default 8. |
| `SETHUCMS_ADMIN_URL` | Where to send the browser afterwards. |

## Sign in with Google

Google is an OpenID Connect provider, so it uses the same flow with fewer settings. Google has no groups, so you list people by e-mail address. An address counts only when Google reports it as verified; case does not matter.

1. In Google Cloud Console > APIs & Services > Credentials, create an **OAuth client ID** of type *Web application*. Redirect URI: `https://YOUR-CMS/v1/auth/oidc/callback`.
2. Set:

| Setting | Meaning |
| --- | --- |
| `SETHUCMS_GOOGLE_CLIENT_ID`, `SETHUCMS_GOOGLE_CLIENT_SECRET` | From the OAuth client. Turns Google sign-in on. |
| `SETHUCMS_PUBLIC_URL` | The address people use to reach the gateway. |
| `SETHUCMS_GOOGLE_ADMINS`, `_EDITORS`, `_VIEWERS` | Comma-separated e-mail addresses. At least one is needed, so nobody is let in by accident. |
| `SETHUCMS_GOOGLE_DOMAINS` | Optional. Only these e-mail domains may sign in. |

You can use Google or another provider through `SETHUCMS_OIDC_*`, not both: the gateway has one OpenID Connect provider. Using Google through `SETHUCMS_OIDC_*` also works: set `SETHUCMS_OIDC_ISSUER=https://accounts.google.com` and `SETHUCMS_OIDC_ROLE_CLAIM=email`.

## Sign in with GitHub

GitHub is not an OpenID Connect provider (it sends no ID token), so SethuCMS has a separate OAuth flow. It exchanges the code, asks GitHub for the account's id and user name, then revokes GitHub's token. It asks for no scopes and keeps nothing from GitHub.

1. On GitHub: Settings > Developer settings > OAuth Apps > New. Callback URL: `https://YOUR-CMS/v1/auth/github/callback`.
2. Set:

| Setting | Meaning |
| --- | --- |
| `SETHUCMS_GITHUB_CLIENT_ID`, `SETHUCMS_GITHUB_CLIENT_SECRET` | From the OAuth app. Turns GitHub sign-in on. |
| `SETHUCMS_PUBLIC_URL` | The address people use to reach the gateway. |
| `SETHUCMS_GITHUB_ADMINS`, `_EDITORS`, `_VIEWERS` | Comma-separated GitHub user names or `id:<number>`. At least one is needed. |
| `SETHUCMS_GITHUB_SESSION_HOURS` | Session length. Default 8. |
| `SETHUCMS_GITHUB_URL`, `SETHUCMS_GITHUB_API_URL` | Only for GitHub Enterprise Server. |

There is no default role: anyone not listed is refused, because anyone can have a GitHub account. Prefer `id:<number>` over a user name. A user name can be changed and later taken by someone else; the id cannot. Find the id at `https://api.github.com/users/NAME`.

## Sign in through Firebase Authentication

If your project already uses Firebase, the admin app can open Firebase's Google and GitHub popups. The gateway then checks Firebase's signed ID token (signature, project, expiry, a sign-in within the last 10 minutes) and starts a normal session.

1. In Firebase Console > Authentication, turn on the Google and/or GitHub provider. Add the admin app's address (for example `sethucms-admin.vercel.app`) under Settings > Authorized domains.
2. Set:

| Setting | Meaning |
| --- | --- |
| `SETHUCMS_FIREBASE_AUTH_PROJECT` | Firebase project id. Turns Firebase sign-in on. |
| `SETHUCMS_FIREBASE_AUTH_API_KEY` | The project's web API key. It is public by design; the gateway hands it to the admin app. |
| `SETHUCMS_FIREBASE_AUTH_DOMAIN` | Optional. Default `<project>.firebaseapp.com`. |
| `SETHUCMS_FIREBASE_ADMINS`, `_EDITORS`, `_VIEWERS` | Comma-separated e-mail addresses or `uid:<Firebase uid>`. At least one is needed. |
| `SETHUCMS_FIREBASE_DOMAINS` | Optional. Only these e-mail domains may sign in. |
| `SETHUCMS_FIREBASE_PROVIDERS` | Accepted providers. Default `google.com,github.com`. |

Only the listed providers are accepted, so anonymous and password accounts that anyone could create in the project cannot sign in. An e-mail address counts only when Firebase reports it as verified. GitHub often gives no verified address, so list GitHub users by `uid:`.

The admin app loads the Firebase SDK only when someone clicks a button. If the admin app is served with a strict Content-Security-Policy, it must allow `https://apis.google.com` for scripts and `https://*.firebaseapp.com` and `https://accounts.google.com` for frames; the `vercel.json` in the admin repo does.

## Firebase sign-in and workspaces

With `SETHUCMS_WORKSPACES=open` (doc 30), a person who is not in the lists above still signs in: they get an isolated workspace of their own and are its admin. Only people named in `SETHUCMS_FIREBASE_ADMINS`, `_EDITORS` and `_VIEWERS` use the main workspace. A workspace needs a verified e-mail address. Teammates are added by invitation from inside the workspace.

If the admin app sits inside another website (for example at `/sethu`), that website's Content-Security-Policy must allow the Firebase sign-in popup, or Google sign-in fails with `auth/internal-error` (doc 32).

## Tested and not tested

All three are tested against fake Google, GitHub and Firebase servers that run inside the test suite. That proves SethuCMS's side (token checks, role lists, failures). It does not prove behaviour against the real services. Try each with your own accounts before relying on it.

## Limits

- Three fixed roles (admin, editor, viewer). Custom roles are not built.
- A person has at most 5 live sessions. `POST /v1/auth/logout` ends one; an admin can revoke any token.
- Group changes at the provider apply at the next sign-in, not to a session already running.
- Sign-ins and denials are in the audit log.
