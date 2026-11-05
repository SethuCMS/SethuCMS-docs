# 36. Tutorial: your first site, from nothing

About fifteen minutes. You will run a gateway, connect a database, make a site that shows its content, and edit that content from a page on your own site.

## 1. Run the gateway

```sh
git clone https://github.com/SethuCMS/sethucms
cd sethucms
sh scripts/build-all.sh
sh scripts/run-local.sh        # http://127.0.0.1:8080
```

The first start prints a one-time admin token. Keep it for the next step. Production setups are in docs 28 and 15.

## 2. Connect a database

Open the admin app at `http://127.0.0.1:8080`, paste the admin token, then **Connections, New connection**. Pick your database type and paste its address.

- Start **read-only**.
- Expose only the collections the website will read.

No database yet? The memory adapter has demo content, which is enough for this tutorial.

## 3. Make a token for the website

Go to **Roles and access, API tokens**, create a token with the **Viewer** role, and copy it now: it is shown once. A Viewer can read published content and nothing else, so even if it leaked, nobody could change your data.

## 4. Create the site

```sh
npm create sethucms@latest my-site
```

Answer the questions (doc 35). Pick **Next.js website**, paste the Viewer token when asked, choose your connection, tick your collections.

```sh
cd my-site
npm run dev                    # http://localhost:3000
```

The page lists the records of each collection. Change a title in the admin, press **Publish**, wait up to a minute, and reload: it changes.

## 5. Show your own fields

Open `app/page.tsx`. The helper returns plain records, so show any field:

```tsx
const articles = await listArticles(10)
// ...
{articles.map((a) => <li key={String(a.id)}>{String(a.title)}: {String(a.summary)}</li>)}
```

For anything beyond a list, use the query builder in `lib/sethucms.ts`:

```ts
import { eq } from '@sethucms/sdk'
const live = await collection('articles').where(eq('status', 'live')).orderBy('created_at', 'desc').limit(5).list()
```

## 6. Let editors work on your site

Build the content-only editor into your site (doc 32) so editors use `/sethu` on your own domain:

```sh
VITE_API_URL=ask VITE_CONTENT_ONLY=true VITE_DEFAULT_GATEWAY=https://cms.example.com \
  pnpm vite build --base=/sethu/ --outDir ../my-site/public/sethu
```

Then, in the admin app, **CORS origins**, add your site's exact address (for example `https://www.example.com`). Open `/sethu` once and, if it is listed under *Recently refused*, press **Allow this site**.

Give each editor an account with the **Editor** role. They sign in as themselves, edit with autosaved drafts, and see **Unpublished changes** until they publish.

## 7. Go live

- Put the gateway on a server that keeps running (doc 15), behind https.
- Set `SETHUCMS_BASE_URL`, `SETHUCMS_TOKEN` and `SETHUCMS_CONNECTION_ID` in your host's environment settings (for Vercel: Project, Settings, Environment Variables).
- Optional: add a webhook (`npm create sethucms@latest -- --revalidate`, or doc 24) so edits appear at once instead of after a minute.

## If something goes wrong

| You see | Do this |
|---|---|
| The page says it could not reach SethuCMS | Check the three env values and that the gateway is running |
| `401` in the gateway log | The token is wrong or revoked: make a new one |
| `403` | The collection is not exposed, or the token's role is too low |
| The editor says "blocked by CORS policy" | Add your site under **CORS origins** (step 6) |
| Old content after publishing | The page is cached for a minute |
