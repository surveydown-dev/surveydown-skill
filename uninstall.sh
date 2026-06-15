#!/usr/bin/env bash
#
# uninstall.sh — remove the surveydown skill from Claude Code.
#
# Only removes the ~/.claude/skills/surveydown symlink. Your cloned repo is left
# untouched.

set -euo pipefail

SKILL_NAME="surveydown"
DEST="$HOME/.claude/skills/$SKILL_NAME"

if [ -L "$DEST" ]; then
  rm "$DEST"
  echo "Uninstalled surveydown skill (removed symlink $DEST)."
elif [ -e "$DEST" ]; then
  echo "Note: $DEST exists but is not a symlink created by install.sh." >&2
  echo "Leaving it in place — remove it manually if you want." >&2
  exit 1
else
  echo "surveydown skill is not installed (no symlink at $DEST)."
fi
