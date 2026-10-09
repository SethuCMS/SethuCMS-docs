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

## Limits

- Three fixed roles (admin, editor, viewer). Custom roles are not built.
- A person has at most 5 live sessions. `POST /v1/auth/logout` ends one; an admin can revoke any token.
- Group changes at the provider apply at the next sign-in, not to a session already running.
- Sign-ins and denials are in the audit log.
