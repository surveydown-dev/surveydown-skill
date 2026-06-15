#!/usr/bin/env bash
#
# install.sh — install the surveydown skill into Claude Code.
#
# Symlinks this repo into ~/.claude/skills/surveydown so Claude Code discovers
# SKILL.md. Because it's a symlink, `git pull` in this repo updates the skill
# instantly — no reinstall needed.

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_NAME="surveydown"
DEST="$HOME/.claude/skills/$SKILL_NAME"

mkdir -p "$HOME/.claude/skills"

if [ -L "$DEST" ]; then
  rm "$DEST"                      # replace an existing symlink (reinstall)
elif [ -e "$DEST" ]; then
  echo "Error: $DEST already exists and is not a symlink." >&2
  echo "Remove it manually, then re-run install.sh." >&2
  exit 1
fi

ln -s "$SKILL_DIR" "$DEST"
echo "Installed surveydown skill:"
echo "  $DEST -> $SKILL_DIR"
echo "Restart Claude Code (or start a new session) to pick it up."
