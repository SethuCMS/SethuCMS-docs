# 33. How the code is laid out

**Rule: no source file is longer than 700 lines.** When a file grows past that, it is split into parts (A, B, C) and the original file stays as the thin middle file that brings them together. Existing imports keep working, and a reader finds one idea per file.

## Gateway (`apps/api/src`)

| Original file | Stays as | Parts |
|---|---|---|
| `gateway.ts` | Wires the services together, runs the request pipeline | `boot/`: `access-log`, `admin`, `change-feed`, `gauges`, `http-helpers`, `types`, `workspaces` |
| `connections/registry.ts` | The registry class | `registry-types`, `registry-helpers` |
| `migration/manager.ts` | The job manager | `manager-types`, `manager-helpers`, `prepare`, `copy` |
| `content/drafts.ts` | The drafts service | `drafts-types`, `drafts-checks` |
| `store/firestore.ts` | Re-exports the parts | `firestore-client`, `-state`, `-shared`, `-audit`, `-changes` |
| `tenancy.ts`, `routes/workspaces.ts` | Workspaces (doc 30) | |
| `schema/code.ts`, `schema/define.ts`, `routes/schema.ts` | Schema as code (doc 29) | |
| `files/`, `routes/files.ts` | Images and files (doc 31) | |

Tests follow the same split: `tests/gateway.test.ts`, `gateway-drafts.test.ts`, `gateway-admin.test.ts`.

## Admin app (`sethucms-admin/src`)

| Original file | Stays as | Parts |
|---|---|---|
| `api/gateway.ts` | The endpoint list | `api/wire.ts` (types), `api/client.ts` (session, workspace, `request`) |
| `components/FieldInput.tsx` | Picks the control for a field | `components/fields/`: `FileUpload`, `JsonInput`, `ReferenceSelect`, `helpers` |
| `styles.css` | Only `@import` lines, in the order the styles apply | `styles/`: `tokens-base`, `ledger-lists`, `forms-chrome`, `content-editor`, `layout`, `cards-home`, `editor-only` |

## Writing new code

- Keep each file under 700 lines. Split by idea, not by size alone.
- Braces on every `if`, long calls broken across lines, descriptive names, a doc comment on each function.
- Run the tests for what you changed and say what you could not run.
