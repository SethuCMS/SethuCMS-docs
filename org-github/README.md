# SethuCMS organisation defaults

These files are the **shared defaults for every repository in the `sethucms` GitHub organisation**: contributing guide, security policy, code of conduct, issue and pull request templates, and the organisation profile.

## Publish them once

GitHub only reads them from a repository named exactly `.github` in the organisation:

1. Create the repository `sethucms/.github` (public).
2. Copy the **contents of this folder** into its root (`CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md`, `PULL_REQUEST_TEMPLATE.md`, `ISSUE_TEMPLATE/`, `profile/`; leave this README out or keep it).
3. Delete this `org-github/` folder from `sethucms-docs`, so the files live in one place.
4. On each repository, turn on **Settings → Security → Private vulnerability reporting**. `SECURITY.md` tells people to use it.

A repository can still add its own `CONTRIBUTING.md` or templates, and its version wins. Do not copy these files into the other repositories: one copy means one place to fix.

(The templates are kept here, not in a hidden `.github` folder, because some tools cannot write there.)
