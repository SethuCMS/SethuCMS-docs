# Contributing to SethuCMS

Thank you for helping. This guide applies to every repository in the organisation.

## Where does my change go?

| I want to... | Repository |
|---|---|
| Add support for a new database | [sethucms-adapters](https://github.com/sethucms/sethucms-adapters) (or start from a template: [Python](https://github.com/sethucms/sethucms-adapter-template-python), [Go](https://github.com/sethucms/sethucms-adapter-template-go)) |
| Change the adapter contract or its conformance tests | [sethucms-adapter-sdk](https://github.com/sethucms/sethucms-adapter-sdk) |
| Fix or extend the API, permissions, drafts, migration, logging | [sethucms](https://github.com/sethucms/sethucms) (`apps/api`, `packages/core`) |
| Change the admin screens | [sethucms-admin](https://github.com/sethucms/sethucms-admin) |
| Improve a client library | `sethucms-sdk-ts`, `-python` or `-dart` |
| Docker, Kubernetes, Terraform | [sethucms-infra](https://github.com/sethucms/sethucms-infra) |
| Fix or write documentation | [sethucms-docs](https://github.com/sethucms/sethucms-docs) |

Not sure? Open an issue and ask.

## Set up

The repositories link to each other **by folder**, so clone them **side by side in one folder**:

```sh
mkdir sethucms-workspace && cd sethucms-workspace
for r in sethucms sethucms-adapter-sdk sethucms-adapters sethucms-admin; do git clone https://github.com/sethucms/$r; done
cd sethucms
sh scripts/build-all.sh     # installs and builds everything in dependency order
sh scripts/run-local.sh     # http://127.0.0.1:8080 (prints an admin token once)
```

You need **Node 22** and **pnpm 9.15** (`corepack enable`). Please use pnpm; other package managers are not supported and can break the folder links. Python and Go are only needed for those templates.

## Run the tests

Run the tests of the package you changed before opening a pull request.

```sh
cd sethucms/apps/api && pnpm test          # gateway
pnpm --filter @sethucms/core test          # core rules
cd ../../../sethucms-admin && pnpm typecheck
```

Some suites run against a real PostgreSQL and are skipped unless you set the variables named at the top of the test file (`tests/postgres.live.test.ts`, `tests/migration-live.test.ts`). They create and remove their own temporary schemas. If your change touches SQL, run them.

## Rules that every change must respect

These are the security properties of the product. A change that weakens one will not be merged, even if the tests pass.

1. Clients never reach a database directly. Only the gateway holds credentials.
2. Reads and writes go through the permission engine and the guarded adapter. The only exception is the admin-only migration engine.
3. Connections are read-only by default, and collections are hidden until an admin exposes them.
4. Secrets are encrypted at rest and never logged, returned or put in error messages. Record values are not logged either.
5. Database error text never reaches the client.
6. Adapters build queries with parameters and quoted identifiers. No string-built SQL.
7. No new dependency without a reason. Prefer the Node standard library.

The full list is in each repository's `AGENTS.md`.

## Writing a good pull request

- **Keep it small and about one thing.** A bug fix does not need a refactor.
- **Add or update a test.** A fix needs a test that failed before it. A new adapter must pass the conformance suite.
- **Say what you ran** and what you could not run. "Tests pass" is not the same as "works in production", and we would rather hear the difference.
- **Update the docs** when behaviour or settings change (`sethucms-docs`, and `.env.example` for new settings).
- Write messages and screen text in plain language, sentence case, active voice.
- The licence is MIT. By contributing you agree your work is released under it. There is no contributor agreement to sign.

## Writing a new adapter

1. Start from the template for your language, or from `packages/postgres` in `sethucms-adapters`.
2. Implement the contract in `sethucms-adapter-sdk` and be honest in `capabilities()` about what the database cannot do.
3. Pass the shared conformance suite (it tests create/read/update/delete, pagination, filters and sorting, read-only enforcement, hostile input and forged cursors).
4. Document the connection settings, which of them are secret, and what the database user needs permission to do.
5. Open a pull request with the adapter, its tests and a short doc page.

## Reporting problems

- **Bugs and ideas:** open an issue and choose a template.
- **Security problems:** do **not** open a public issue. See [SECURITY.md](SECURITY.md).

## Behaviour

Everyone taking part follows the [Code of Conduct](CODE_OF_CONDUCT.md).
