#!/usr/bin/env bash
#
# install.sh — install the surveydown skill into Claude Code (dev/contributor path).
#
# Symlinks skills/surveydown/ into ~/.claude/skills/surveydown so Claude Code
# discovers SKILL.md. Because it's a symlink, `git pull` in this repo updates the
# skill instantly — no reinstall needed.
#
# End users should prefer:  npx skills add surveydown-dev/surveydown-skill -a claude-code -g -y

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_NAME="surveydown"
SKILL_SRC="$REPO_DIR/skills/$SKILL_NAME"
DEST="$HOME/.claude/skills/$SKILL_NAME"

mkdir -p "$HOME/.claude/skills"

if [ -L "$DEST" ]; then
  rm "$DEST"                      # replace an existing symlink (reinstall)
elif [ -e "$DEST" ]; then
  echo "Error: $DEST already exists and is not a symlink." >&2
  echo "Remove it manually, then re-run install.sh." >&2
  exit 1
fi

ln -s "$SKILL_SRC" "$DEST"
echo "Installed surveydown skill:"
echo "  $DEST -> $SKILL_SRC"
echo "Restart Claude Code (or start a new session) to pick it up."
