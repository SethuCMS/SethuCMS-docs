# 25. Use it from your app

SethuCMS is an HTTP API with a TypeScript SDK. Any stack that can make HTTPS requests can use it: Next.js, React, Angular, plain JavaScript, Flutter, Python. There is no framework plugin to install.

## Install the SDK

```sh
npm install @sethucms/sdk
```

```ts
import { SethuClient, eq } from '@sethucms/sdk';

const cms = new SethuClient({ baseUrl: 'https://cms.example.com', token: () => getToken() });
const orders = cms.collection('conn_123', 'orders');
const page = await orders.where(eq('status', 'paid')).limit(20).list();
```

The SDK reference is in its README. The `baseUrl` must be https, except for localhost.

## Where the token lives

The token decides what the caller may read and write (see page 7). Treat it like a password.

| Stack | Where to call the SDK | Token |
|---|---|---|
| Next.js | Server Components, Server Actions and route handlers | Stays on the server |
| React or Angular (browser) | In the browser | A short-lived user token from single sign-on (page 21). Never a service token |
| Plain HTML | In the browser | Same as above; only for local testing with a test token |

## Example apps

The `sethucms-examples` repository has the same small app in four stacks: plain HTML, React (Vite), Angular and Next.js. Each lists your connections and collections, shows and edits records, follows live changes, and runs a self-check against your gateway. The React and Angular examples keep the token in the browser, which is fine for local testing only. The Next.js example keeps it on the server and is the pattern to copy for production.

## What is not there yet

- No `create-sethucms` starter and no React hooks or Angular service library. You use the SDK directly.
- Nuxt and other frameworks should work the same way, but they have not been tested.
- Row-level rules (for example, a vendor sees only their own rows) are supported by the permission system, but a full multi-vendor app has not been tested end to end.
- No vendor or business dashboards yet.
