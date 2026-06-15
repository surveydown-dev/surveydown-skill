#!/usr/bin/env bash
#
# deploy.sh — deploy a surveydown survey to a Hugging Face Space (Docker SDK).
#
# Works on ANY surveydown survey (a directory with app.R + survey.qmd) — a survey
# you made from a template or from scratch. Your survey directory is the source of
# truth; this only generates the Hugging Face packaging and pushes it to a Space.
#
# Usage:
#   ./deploy.sh --space <owner>/<name> [--dir <survey-dir>]
#   ./deploy.sh --space <owner>/<name> --no-push     # build only, don't push
#
#   --space    target Hugging Face Space, e.g. yourname/my-survey   (required)
#   --dir      path to the survey directory                          (default: .)
#   --no-push  assemble the Space folder and print its path; skip the push
#
# What it does:
#   copy the survey's runtime files -> add the shared Dockerfile + a generated
#   README (HF frontmatter) + packages.txt (from the survey's library() calls)
#   -> push to the Space, which auto-rebuilds.
#
# Prerequisites:
#   - git, and rsync (or it falls back to cp).
#   - The target Space already exists (Docker SDK). Create it at
#     huggingface.co/new-space, or: hf repo create <owner>/<name> --repo-type space --space-sdk docker
#   - Git can push to huggingface.co (run `hf auth login`, or you'll be prompted
#     for your username + a Write token on first push).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS="$SCRIPT_DIR/assets"

# R packages never written to packages.txt (base/recommended + installed separately)
EXCLUDE_PKGS="base stats utils graphics grDevices methods datasets tools parallel compiler splines stats4 grid tcltk surveydown shiny"

SPACE=""
DIR="."
PUSH=true
while [ $# -gt 0 ]; do
  case "$1" in
    --space)   SPACE="${2:-}"; shift 2 ;;
    --dir)     DIR="${2:-}"; shift 2 ;;
    --no-push) PUSH=false; shift ;;
    -h|--help) sed -n '2,33p' "$0"; exit 0 ;;
    *)         echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

[ -n "$SPACE" ] || { echo "Error: --space <owner>/<name> is required (see --help)." >&2; exit 1; }
case "$SPACE" in */*) ;; *) echo "Error: --space must be <owner>/<name>." >&2; exit 1 ;; esac
DIR="$(cd "$DIR" 2>/dev/null && pwd)" || { echo "Error: survey directory not found." >&2; exit 1; }
[ -f "$DIR/app.R" ]      || { echo "Error: no app.R in $DIR — not a surveydown survey?" >&2; exit 1; }
[ -f "$DIR/survey.qmd" ] || { echo "Error: no survey.qmd in $DIR." >&2; exit 1; }

owner="${SPACE%%/*}"; name="${SPACE##*/}"
title="$(echo "$name" | sed 's/[-_]/ /g' | awk '{for(i=1;i<=NF;i++)$i=toupper(substr($i,1,1)) substr($i,2)}1')"

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
mkdir "$tmp/space"

echo ">>> $DIR  ->  $owner/$name"

# 1. Copy the survey's files, excluding build artifacts and dev/meta junk
EXCLUDES=(.git .gitignore .gitattributes _survey survey_files survey.html preview_data.csv rsconnect manifest.json .posit .Rproj.user .DS_Store)
if command -v rsync >/dev/null 2>&1; then
  rsync_args=()
  for e in "${EXCLUDES[@]}"; do rsync_args+=(--exclude="$e"); done
  rsync_args+=(--exclude='*.Rproj')
  rsync -a "${rsync_args[@]}" "$DIR"/ "$tmp/space"/
else
  cp -R "$DIR"/. "$tmp/space"/
  ( cd "$tmp/space" && rm -rf "${EXCLUDES[@]}" ./*.Rproj 2>/dev/null || true )
fi

# 2. Shared build files
cp "$ASSETS/Dockerfile"   "$tmp/space/Dockerfile"
cp "$ASSETS/dockerignore" "$tmp/space/.dockerignore"

# 3. packages.txt — extra R packages from the survey's library()/require() calls
: > "$tmp/space/packages.txt"
grep -rhoE '(library|require)\(([^),]+)\)' "$DIR/app.R" "$DIR/survey.qmd" 2>/dev/null \
  | sed -E "s/.*\(['\"]?([A-Za-z0-9._]+)['\"]?\)/\1/" \
  | sort -u \
  | while IFS= read -r p; do
      [ -z "$p" ] && continue
      case " $EXCLUDE_PKGS " in *" $p "*) continue ;; esac
      echo "$p" >> "$tmp/space/packages.txt"
    done
echo "    packages.txt: $(paste -sd' ' "$tmp/space/packages.txt" 2>/dev/null || true)"

# 4. README with Hugging Face frontmatter
sed -e "s/{{TITLE}}/${title}/g" "$ASSETS/space-readme.template.md" > "$tmp/space/README.md"

# 5. Build-only mode
if [ "$PUSH" != true ]; then
  out="/tmp/hf_build_${name}"
  rm -rf "$out"; cp -R "$tmp/space" "$out"
  echo "    built (no push): $out"
  exit 0
fi

# 6. Push to the Space (replace contents, keep its git history)
if ! git clone --quiet "https://huggingface.co/spaces/${owner}/${name}" "$tmp/hf"; then
  echo "    ! could not clone the Space. Create it first:" >&2
  echo "      hf repo create ${owner}/${name} --repo-type space --space-sdk docker" >&2
  exit 1
fi
( cd "$tmp/hf" && git ls-files -z | xargs -0 git rm -q --ignore-unmatch >/dev/null 2>&1 || true )
cp -R "$tmp/space/." "$tmp/hf/"
(
  cd "$tmp/hf"
  git add -A
  if git diff --cached --quiet; then
    echo "    no changes — Space already up to date"
  else
    git commit -q -m "Deploy surveydown survey"
    git push -q
    echo "    pushed -> https://${owner}-${name}.hf.space  (building...)"
  fi
)
