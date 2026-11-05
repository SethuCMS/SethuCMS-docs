# 32. The admin app

A Vite and React app. It talks only to the gateway, keeps the sign-in token in `sessionStorage` (so closing the tab signs you out) and uses a hash router.

## Two builds from one codebase

| Build | Who it is for | How it is made |
|---|---|---|
| Hosted admin | Admins: connections, access, audit, migration, settings | `VITE_API_URL=ask`, optional `VITE_DEFAULT_GATEWAY=<gateway address>` |
| Content only (`/sethu`) | Editors on a customer's own website | Add `VITE_CONTENT_ONLY=true`, build with `--base=/sethu/` into the website's `public/sethu` folder |

Everyone sees only Content at `/sethu`. The full admin panel is for admins.

```sh
# content-only build into a Next.js site
rm -rf ~/portfolio/public/sethu
VITE_API_URL=ask VITE_CONTENT_ONLY=true VITE_DEFAULT_GATEWAY=https://YOUR-GATEWAY \
  pnpm vite build --base=/sethu/ --outDir ~/portfolio/public/sethu
```

If the website sets a Content-Security-Policy, `/sethu` needs its own, looser one: scripts from `'self'` and `https://apis.google.com`, connections to the gateway and `https://*.googleapis.com` and `https://*.firebaseapp.com`, frames from `https://*.firebaseapp.com`, `https://accounts.google.com` and `https://apis.google.com`, images from the gateway. Without this, Google sign-in fails with `auth/internal-error`. Keep the strict policy for the rest of the site.

## The content page

- **Left:** the collections, with a button in the top bar that closes and opens the sidebar. The choice is remembered in the browser.
- **Top bar:** the search box. It searches the collection's title field (300 ms after you stop typing).
- **Right:** the list of records, newest first or oldest first, and the editor.
- On a phone the sidebar becomes a drawer.

## Counts, singletons and scheduling

- **Counts.** Each collection in the sidebar shows how many records you can see. A `+` after the number (`1,000+`) means "at least". The numbers refresh a moment after you create or delete a record and are read aloud by screen readers as "1,000 or more records".
- **Singleton collections** (doc 29) open straight into their one record, with no search box, list, **New** or **Delete**.
- **Scheduling.** Under the form, **Schedule** opens a date and time picker (in your own time zone, suggested one hour ahead). A scheduled draft shows **Scheduled for ...** with **Change time** and **Cancel schedule**, and a **Scheduled** chip in the list. If a scheduled publish fails, the editor shows the reason with **Schedule again** and **Dismiss**. It is only shown after the record is opened again. The gateway runs the schedule, so you can close the page. The box is shown on serverless gateways too, where trying it gives a clear error.

## CORS origins page

Admins add and remove the browser sites allowed to call the gateway under **CORS origins**, and see the sites that were just refused with an **Allow this site** button (doc 12). The first time a person connects from a site that is not allowed, the connect screen explains the cause and what to add.

## Branding and accessibility

- Colours and type come from CSS variables in `tokens-base.css`. To rebrand without rebuilding, edit `public/theme.css`: it is loaded after the app's own styles, so write overrides as `:root:root { --accent: ...; }`.
- The status badges (Published, Unpublished changes, Scheduled) meet WCAG 2.2 AA contrast in light and dark themes, checked with axe-core on the content page, the editor, a singleton and the schedule box. A screen-reader pass and real phones have not been tested; only a desktop browser at 390 and 320 pixels wide.

## Choosing which fields you see

Above the form, **Fields** lists every field of the collection with a checkbox. The choice is per collection and stays in your browser. Keys and required fields always show. Hidden fields keep their values and are saved unchanged. Until you choose, fields named `sanity_*` are hidden, and so is anything the schema file hides (doc 29).

## Code and files

- A field that holds JSON or a list is a code box. Only valid JSON is passed on.
- A field that holds a file shows its preview and upload controls. **Edit as code** opens the raw object.
- The schema file can set the label, a description, a hint about the editor (`code`, `image`, `file`, `textarea`) and a title field per collection (doc 29).

## Settings, Schema

Admins see the schema file as the gateway loaded it, and where it disagrees with each connection.

## Projects

When workspaces are on, the sidebar shows a project menu (switch, New project)
and Settings lists your projects with rename and delete for the ones you own.
See [Workspaces](30-workspaces.md#projects-more-than-one-workspace-per-person).
