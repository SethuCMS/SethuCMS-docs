# AGENTS.md — sethucms-docs

Design documents, schemas and the LaTeX/PDF.

This repository is one part of SethuCMS. **Read `../sethucms/AGENTS.md` first** for the whole picture, the security rules that must not be broken, and the working agreements.

## Build and test

```sh
cd latex && pdflatex main.tex (twice)
```

## Notes

Keep docs/*.md and latex/main.tex in sync. Diagrams are Mermaid in Markdown and TikZ in LaTeX. Say plainly what is built and what is not.

## Always

- Run the tests for what you changed and say what you ran and what you could not run.
- Do not `git commit` or `git push` unless the owner asks.
- Never print or store a secret, token or password.
