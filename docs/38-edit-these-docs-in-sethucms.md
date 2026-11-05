# Edit this whole website in SethuCMS (no redeploy)

This website, and especially its docs, changes almost every day. Rebuilding and redeploying the website for each typo is slow, so the site reads its guides, its "What's new" and "Security" cards and its package list from SethuCMS. You edit a guide in the editor, press Publish, and the site shows it within about a minute.

The markdown files in `content/docs` stay as a safety net: if SethuCMS is not set up, or the gateway is down, the site still shows the last copy of every guide.

## How it works

1. A collection called `docs` holds one record per guide: `slug`, `number`, `title`, `body` (markdown).
2. The docs site asks the gateway for those records on the server and caches the answer for 60 seconds.
3. A guide in SethuCMS wins over the file with the same slug. A guide that only exists in SethuCMS gets its own page, built on first visit. No deploy.

## Set it up (about ten minutes)

1. Create the `docs` collection in your database with these fields: `slug` (text, required), `number` (integer), `title` (text, required), `body` (long text).
2. In the admin app open **Tokens** and make a **Viewer** token. This is the only token the website gets.
3. On the website host (for example Vercel) add these environment variables:

   | Name | Value |
   |---|---|
   | `SETHUCMS_BASE_URL` | your gateway address |
   | `SETHUCMS_VIEWER_TOKEN` | the Viewer token |
   | `SETHUCMS_DOCS_CONNECTION` | the connection id of the database |

   Never put an Editor or Admin token on the website.
4. Copy the existing guides in once, from your own computer, with an Editor token:

   ```bash
   SETHUCMS_BASE_URL=https://your-gateway \
   SETHUCMS_EDITOR_TOKEN=... \
   SETHUCMS_DOCS_CONNECTION=conn_xxxx \
   node scripts/seed-docs-to-cms.mjs           # shows what it would add
   node scripts/seed-docs-to-cms.mjs --apply   # adds them
   ```

   It skips guides already there, so running it twice is safe.
5. Redeploy the website once so it picks up the variables.

## The home page and packages too

Three more optional collections hold the other words on the site:

| Collection | Fields | Shows |
|---|---|---|
| `whats_new` | `title`, `text`, `highlight` (yes/no), `position` (number) | the "What's new" cards |
| `security` | `title`, `text`, `highlight`, `position` | the "Security first" cards |
| `packages` | `name`, `text`, `group`, `command`, `position` | the Packages page |

Create them like `docs`, then copy the current text in once (needs Node 22.18 or newer):

```bash
node scripts/seed-site-content-to-cms.mjs           # shows what it would add
node scripts/seed-site-content-to-cms.mjs --apply   # adds it
```

Cards are ordered by `position`. A package's `group` must match one of the group titles on the Packages page ("Use SethuCMS in your app" and so on); any other group goes under "More". If a collection is missing or empty, the site shows the text kept in `lib/content.ts`, so nothing ever goes blank.

## Every day after that

- **Change a guide:** open it in the editor, change the text, press Publish.
- **Add a guide:** create a record with a new slug such as `40-release-notes`, a title and a body.
- **Remove a guide:** delete the record. If a file with the same slug exists, the file shows again.
- **Change a card or a package:** edit its record and Publish. Same minute, same no-deploy.

Changes appear within a minute. To see one at once, open the guide twice (the first visit after the minute is up refreshes the page for the next one).

## If a change does not show

- Wait a minute and open the page again.
- The record needs a `slug` of lowercase letters, digits and dashes, and a `title`. Records missing either are ignored.
- Check the website host has the three variables. Without them the site silently uses the files.
- Check the gateway lists your website under allowed origins only if the page reads in the browser; this site reads on the server, so CORS is not involved.
