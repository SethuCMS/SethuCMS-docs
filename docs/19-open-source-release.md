# 19. Open-source release checklist

The code is MIT licensed (`LICENSE` in every repository). This list is what to do before the repositories go public. Items marked **owner** need a person; they are not things a coding agent should do.

## Before making anything public

1. **Secrets scan, whole history.** Run a scanner over every repository's full git history (for example `gitleaks detect` or `trufflehog git file://.`). One leaked key in an old commit is public once the repository is. If anything is found, rotate the secret first, then clean the history. **owner**
2. **Read the code you are publishing.** Remove private notes, customer names, internal URLs and test data that is not synthetic.
3. **Licences of dependencies.** Run a licence report (`pnpm licenses list`) and check that nothing conflicts with MIT. Add the peer drivers (`mysql2`, `mongodb`, `@google-cloud/firestore`) to your list; they are not bundled.
4. **Name and trademark.** Search for "Sethu" and "SethuCMS" in the trade-mark registers of the countries you care about and in package registries and domain names. MIT gives no trademark rights; decide whether you want a trademark policy. **owner**
5. **Be honest in the README.** Keep the "tested against" table from doc 18. Say that MySQL, MongoDB and Firestore adapters have only been run against stand-ins, and that deploy workflows and the container image are unverified.
6. **Security contact.** Enable *private vulnerability reporting* in each repository (Settings, Code security). Check `SECURITY.md` names it. **owner**

## The organisation profile

The `org-github/` folder holds the community files (code of conduct, contributing guide, issue and pull request templates, security policy). Publish it as a repository named `.github` inside the `sethucms` organisation. GitHub then applies those files to every repository that has none of its own. Some tools cannot write `.github` paths, so copy the folder yourself. **owner**

## Day of release

1. Make repositories public in dependency order: `sethucms`, `sethucms-adapter-sdk`, `sethucms-adapters`, `sethucms-admin`, then the rest.
2. Turn on branch protection for `main`: pull request required, tests must pass, no force pushes.
3. Turn on Dependabot alerts and secret scanning (free for public repositories).
4. Publish packages to npm in the order given in `RELEASING.md` in the `sethucms` repository (core, adapter SDK, SQL kit, adapters, then the TypeScript SDK). The ten 0.1.0 packages were packed and installed together in a clean folder and all import; the shared conformance suite passes from the installed copies. After publishing, remove the `link:` overrides from `sethucms-adapter-sdk` and `sethucms-adapters` and check that a plain `npm install` works.
5. Tag a first release with notes that list what is verified and what is not.

## After release

- Watch issues and security reports for the first weeks; reply within a few days even if only to say you saw it.
- Label a few small issues `good first issue`.
- Re-read doc 18 whenever an adapter is tested against a real server, and update its row.
