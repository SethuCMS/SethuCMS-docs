# 35. Start a project with one command

`create-sethucms` asks a few questions in your terminal, checks your gateway, and writes a working client for your site. It works for a new project or one you already have, in TypeScript or JavaScript.

```sh
npm create sethucms@latest          # a new project
npx create-sethucms init            # add SethuCMS to the project in this folder
```

You need Node 20.6 or newer and a running gateway (doc 28). It is a normal npm package, so it works with pnpm, yarn and bun too.

## The questions

```text
✔ Project name › my-site
✔ What are you building? › Next.js website
✔ TypeScript or JavaScript? › TypeScript

Now your SethuCMS gateway.
✔ Gateway address › http://127.0.0.1:8080
  ✔ gateway is reachable
✔ Viewer token (hidden; press Enter to add it later) › ••••••••
✔ Which connection does this site read? › Demo content
✔ Which collections should the site read? › authors, articles
✔ Add a webhook so edits show up at once? › no
✔ Install packages with npm now? › yes
```

Move with the arrow keys, press Space to pick several, Enter to confirm. Three of the answers come from your real gateway, so you do not type ids: the connection list, the collection list, and a check that the address answers. If the gateway is not running yet, you can still finish and fix the address in the env file.

| Choice | What you get |
|---|---|
| Next.js website | A small site that lists your records on the server, cached for a minute |
| Express API | `/api/<collection>` routes that cache answers for a minute |
| Node script | A few lines that print your records, to see it work |
| Just the client file | One file for any other stack |

## What it writes

- `lib/sethucms.ts` (or `.js`): your client, plus one `list…` function per collection you picked.
- `.env.local` for Next.js, `.env` for the others: the gateway address, the token and the connection id. Git ignores it. A second file, `.env.example`, shows the names without the values.
- For a new project: `package.json`, the TypeScript or JavaScript config, a page or server, and a short README.

It never overwrites a file without asking (with `-y` it keeps yours), and in an existing project it only adds the env variables that are missing.

## Skip the questions

Every question has a flag, which is useful in scripts:

```sh
npm create sethucms@latest my-site -- \
  --template next --lang ts \
  --gateway https://cms.example.com \
  --connection conn_abc123 --collections articles,authors -y
```

| Flag | Meaning |
|---|---|
| `--template next\|express\|node\|client` | What to create |
| `--lang ts\|js` | Language |
| `--gateway <url>`, `--connection <id>` | Where the content is |
| `--collections a,b` | Collections to make helpers for |
| `--revalidate` | Add a webhook route that refreshes the cache (Next.js) |
| `--no-install` | Do not install packages |
| `-y` | Take the default for everything not given |

Give the token through the hidden question or the `SETHUCMS_TOKEN` variable. A `--token` flag works but stays in your shell history.

## Use the result

```ts
import { eq } from '@sethucms/sdk'
import { listArticles, collection } from './lib/sethucms'

const latest = await listArticles(10)                                    // the generated helper
const one = await collection('articles').get(7)                          // anything the SDK can do
const live = await collection('articles').where(eq('status', 'live')).list()
```

See doc 34 for counts, singletons, previews and scheduling, and doc 36 for a full walk-through.

## What has been tested

All four project types were generated against a real local gateway in TypeScript and JavaScript. The Next.js project was built with `next build` and served, the Express and Node projects were run and answered with real records, and the arrow-key questions were driven through a terminal. Not tested: Windows, and pnpm, yarn and bun installs.
