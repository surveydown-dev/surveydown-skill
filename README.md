# surveydown-skill

A skill for working with [surveydown](https://surveydown.org) surveys — authoring
and deploying them.

👉 **Start with [`SKILL.md`](SKILL.md)**, which
routes to the right task doc.

## What it covers

| Task | Status |
|------|--------|
| Create a new survey | 🚧 under construction |
| Connect a database to store responses | 🚧 under construction |
| Deploy to Hugging Face Spaces | ✅ available |
| Deploy to Google Cloud Run | ✅ available |
| Deploy to Posit Connect Cloud | 🚧 under construction |

Each section lives in its own folder with a `README.md` guide and its tooling.
The Hugging Face and Google Cloud Run deployments are fully implemented — see
[`deploy-hugging-face/`](deploy-hugging-face/README.md) and
[`deploy-google-cloud/`](deploy-google-cloud/README.md). The other section folders
([`create-survey/`](create-survey/README.md),
[`connect-database/`](connect-database/README.md),
[`deploy-posit-cloud/`](deploy-posit-cloud/README.md)) are stubbed and being
filled in.

## Install (Claude Code)

```bash
npx skills add surveydown-dev/surveydown-skill -a claude-code -g -y
```

This installs the `surveydown-skill` skill globally to `~/.claude/skills/`. Start a new
Claude Code session and it's available. ([`npx skills`](https://github.com/vercel-labs/skills)
is the open agent-skills installer.)

## Update

```bash
npx skills add surveydown-dev/surveydown-skill -a claude-code -g -y
```

Re-running `add` pulls the latest version.

## Uninstall (Claude Code)

```bash
npx skills remove surveydown-dev/surveydown-skill -g
```
