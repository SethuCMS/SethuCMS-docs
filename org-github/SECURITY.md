# Security policy

SethuCMS holds database credentials and edits live data, so we treat security reports seriously.

## Reporting a vulnerability

**Please do not open a public issue.** Use GitHub's private reporting instead:

1. Go to the affected repository's **Security** tab.
2. Choose **Report a vulnerability**.
3. Describe what you found, how to reproduce it, and what an attacker could do.

We aim to acknowledge a report within 3 working days and to tell you what we plan to do within 10. We will credit you when the fix is released unless you prefer not to be named.

## What is in scope

Anything that breaks the rules in [CONTRIBUTING.md](CONTRIBUTING.md): reaching a database without the gateway, bypassing permissions or read-only mode, reading or leaking a credential or token, injection, server-side request forgery through connection settings, tampering with the audit log without detection, and unsafe defaults.

## Supported versions

The project is pre-1.0. Only the latest release and the `main` branch receive security fixes.

## Known limits (not vulnerabilities)

These are documented in the design docs: one gateway process per data volume, three fixed roles, no single sign-on yet, and the audit log shows tampering but cannot prevent it by someone with write access to the data volume.
