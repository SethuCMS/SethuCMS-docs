# 37. Tutorial: move a site from Sanity to SethuCMS

This is the path used to move a real portfolio site. It assumes the content already lives in SethuCMS (copied once from Sanity) and your site reads it through the SDK. The goal: nothing left that mentions Sanity.

## 1. Remove the Sanity code

- Delete the sync script and any test route that used `@sanity/client`.
- Remove the package, then refresh the lock file:

```sh
npm uninstall @sanity/client      # or: npm install, after editing package.json
```

- Search for leftovers: `grep -rni sanity . --exclude-dir=node_modules --exclude-dir=.next`.

## 2. Read files from the record, not from Sanity

A Sanity image used to be stored as an asset reference that your code turned into a `cdn.sanity.io` link. In SethuCMS a file field holds its own link:

```ts
type AssetField = { url?: string | null } | null | undefined
const assetUrl = (field: AssetField) => field?.url ?? null
```

## 3. Move the files out of Sanity's CDN

Records copied earlier may still point at `cdn.sanity.io`. The script below copies each file into SethuCMS storage and rewrites the record. It does a dry run unless you pass `--apply`, and a record that fails keeps its old link, so it is safe to run again.

```sh
# dry run: lists what would move
node --env-file=.env.local scripts/move-assets-to-sethu.mts

# do it (needs an Editor token; make one and revoke it afterwards)
SETHUCMS_EDITOR_TOKEN=... node --env-file=.env.local scripts/move-assets-to-sethu.mts --apply
```

```ts
import { SethuClient } from '@sethucms/sdk'

const OLD_HOST = 'https://cdn.sanity.io/'
const MAX_BYTES = 4_000_000
const apply = process.argv.includes('--apply')
const need = (n: string) => process.env[n] ?? (console.error(`Missing ${n}`), process.exit(1))
const baseUrl = need('SETHUCMS_BASE_URL').replace(/\/+$/, '')
const connectionId = need('SETHUCMS_CONNECTION_ID')
const token = apply ? need('SETHUCMS_EDITOR_TOKEN') : need('SETHUCMS_TOKEN')
const cms = new SethuClient({ baseUrl, token: () => token })

type Json = Record<string, unknown>
const copies = new Map<string, string>()

function oldLinks(value: unknown, found: Json[] = []): Json[] {
  if (Array.isArray(value)) value.forEach((v) => oldLinks(v, found))
  else if (value && typeof value === 'object') {
    const o = value as Json
    if (typeof o.url === 'string' && o.url.startsWith(OLD_HOST)) found.push(o)
    else Object.values(o).forEach((v) => oldLinks(v, found))
  }
  return found
}

async function copy(url: string): Promise<string> {
  const known = copies.get(url)
  if (known) return known
  const res = await fetch(url)
  if (!res.ok) throw new Error(`the old link answered ${res.status}`)
  const bytes = Buffer.from(await res.arrayBuffer())
  if (bytes.length > MAX_BYTES) throw new Error('larger than 4 MB')
  const name = new URL(url).pathname.split('/').pop() || 'file'
  const up = await fetch(`${baseUrl}/v1/connections/${encodeURIComponent(connectionId)}/files`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': (res.headers.get('content-type') ?? '').split(';')[0]!,
      'X-File-Name': encodeURIComponent(name),
    },
    body: bytes,
  })
  if (!up.ok) throw new Error(`the gateway answered ${up.status}`)
  const fresh = `${baseUrl}${((await up.json()).data as { path: string }).path}`
  copies.set(url, fresh)
  return fresh
}

for (const info of await cms.collections(connectionId)) {
  const col = cms.collection<Json>(connectionId, info.name)
  for (const record of (await col.query().limit(500).list()).data) {
    const links = oldLinks(record)
    if (!links.length) continue
    console.log(`${apply ? 'MOVE' : 'WOULD MOVE'} ${links.length} file(s) in ${info.name}/${record.id}`)
    if (!apply) continue
    try {
      for (const link of links) link.url = await copy(link.url as string)
      await col.update(String(record.id), record)
    } catch (error) {
      console.log(`  FAILED: ${(error as Error).message} (the record keeps its old link)`)
    }
  }
}
```

The gateway's file storage needs a database type that can store files (doc 31). The in-memory adapter cannot.

## 4. Clean up the site's settings

- Remove `cdn.sanity.io` from `images.remotePatterns` and from the `img-src` and `connect-src` lines of your Content-Security-Policy, and add your gateway's address to `img-src` instead.
- With Next.js 16, `revalidateTag` needs a second argument: `revalidateTag('sethucms', 'max')`.
- Run `npm run typecheck && npm run build`. If `typecheck` complains about files in `.next/types` that you deleted, remove the `.next` folder and run it again.

## 5. Check

- Reload the site: every image should load from your gateway.
- `grep -rni sanity .` should find nothing outside `node_modules`.
- In Sanity's dashboard you can now delete the project. Do that last, after you have kept a backup of anything you still want.

## A note on empty collections

If the site reads a collection that does not exist yet (for example `hero` or `skills`), SethuCMS answers `NOT_FOUND` and the site should fall back to its built-in text. Create the collection in the admin when you want editors to change it.
