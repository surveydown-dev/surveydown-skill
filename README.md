# surveydown-skill

A skill for working with [surveydown](https://surveydown.org) surveys — authoring
and deploying them.

👉 **Start with [`skills/surveydown/SKILL.md`](skills/surveydown/SKILL.md)**, which
routes to the right task doc.

Implemented:
- **Deploy templates to Hugging Face Spaces** — see
  [`skills/surveydown/resources/hugging-face-deployment.md`](skills/surveydown/resources/hugging-face-deployment.md)
  (tooling in [`skills/surveydown/hugging-face/`](skills/surveydown/hugging-face/)).

Planned: creating a survey from scratch, and deploying to Posit Connect Cloud.

## Install (Claude Code)

```bash
npx skills add surveydown-dev/surveydown-skill -a claude-code -g -y
```

This installs the `surveydown` skill globally to `~/.claude/skills/`. Start a new
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

## Developing this skill

If you're working *on* the skill (not just using it), symlink your local clone so
edits and `git pull` take effect immediately:

```bash
git clone https://github.com/surveydown-dev/surveydown-skill.git
cd surveydown-skill
./install.sh      # symlinks skills/surveydown -> ~/.claude/skills/surveydown
./uninstall.sh    # removes the symlink
```
