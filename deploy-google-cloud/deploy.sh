#!/usr/bin/env bash
#
# deploy.sh — deploy a surveydown survey to Google Cloud Run.
#
# Works on ANY surveydown survey (a directory with app.R + survey.qmd). Your
# survey directory is the source of truth; this generates the Cloud Run packaging
# and deploys it. Each survey becomes its own Cloud Run service (no per-account
# app cap), scales to zero when idle (≈ $0), and serves at
#   https://<service>-<projectnumber>.<region>.run.app
#
# Usage:
#   ./deploy.sh --service <name> [--dir <survey-dir>] [--region <region>] [--project <id>]
#   ./deploy.sh --service <name> --no-secrets     # skip database-secret sync
#
#   --service     Cloud Run service name = the URL's leading label   (required)
#                 (lowercase letters/digits/hyphens, start with a letter, <=63)
#   --dir         path to the survey directory                       (default: .)
#   --region      Cloud Run region                                   (default: us-central1)
#   --project     GCP project id                  (default: active gcloud project)
#   --memory      container memory (raise for heavy templates)       (default: 1Gi)
#   --max-instances  max concurrent containers                       (default: 1)
#   --no-secrets  skip the automatic database-secret sync (see below)
#
# What it does:
#   copy the survey's runtime files -> add the shared Dockerfile + start.sh +
#   packages.txt -> `gcloud run deploy --source` (Cloud Build builds the image,
#   Cloud Run serves it). If the survey is in `mode: database` and a real .env
#   sits next to it, the SD_* credentials are stored in Secret Manager and wired
#   into the service (via set-secrets.sh), unless --no-secrets. Scale-to-zero and
#   public (unauthenticated) access are set; sessions allow up to 60 min.
#
# Prerequisites:
#   - The gcloud CLI, logged in (`gcloud auth login`) with a billing-enabled
#     project. Install: https://cloud.google.com/sdk/docs/install (or `brew
#     install --cask google-cloud-sdk`). Cloud Run requires a billing account on
#     file, but usage stays within the always-free tier for low-traffic surveys.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS="$SCRIPT_DIR/assets"
EXCLUDE_PKGS="base stats utils graphics grDevices methods datasets tools parallel compiler splines stats4 grid tcltk surveydown shiny"

SERVICE=""
DIR="."
REGION="us-central1"
PROJECT=""
MEMORY="1Gi"
MAX_INSTANCES="1"
SECRETS=true
while [ $# -gt 0 ]; do
  case "$1" in
    --service)       SERVICE="${2:-}"; shift 2 ;;
    --dir)           DIR="${2:-}"; shift 2 ;;
    --region)        REGION="${2:-}"; shift 2 ;;
    --project)       PROJECT="${2:-}"; shift 2 ;;
    --memory)        MEMORY="${2:-}"; shift 2 ;;
    --max-instances) MAX_INSTANCES="${2:-}"; shift 2 ;;
    --no-secrets)    SECRETS=false; shift ;;
    -h|--help)       sed -n '2,36p' "$0"; exit 0 ;;
    *)               echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

command -v gcloud >/dev/null 2>&1 || { echo "Error: gcloud CLI not found. Install it (brew install --cask google-cloud-sdk)." >&2; exit 1; }
[ -n "$SERVICE" ] || { echo "Error: --service <name> is required (see --help)." >&2; exit 1; }
echo "$SERVICE" | grep -qE '^[a-z][a-z0-9-]{0,62}$' || { echo "Error: --service must be lowercase letters/digits/hyphens, start with a letter, <=63 chars." >&2; exit 1; }
DIR="$(cd "$DIR" 2>/dev/null && pwd)" || { echo "Error: survey directory not found." >&2; exit 1; }
[ -f "$DIR/app.R" ]      || { echo "Error: no app.R in $DIR — not a surveydown survey?" >&2; exit 1; }
[ -f "$DIR/survey.qmd" ] || { echo "Error: no survey.qmd in $DIR." >&2; exit 1; }

# Auth + project
account="$(gcloud auth list --filter=status:ACTIVE --format='value(account)' 2>/dev/null | head -1)"
[ -n "$account" ] || { echo "Error: not logged in. Run: gcloud auth login" >&2; exit 1; }
[ -n "$PROJECT" ] || PROJECT="$(gcloud config get-value project 2>/dev/null)"
[ -n "$PROJECT" ] && [ "$PROJECT" != "(unset)" ] || { echo "Error: no project set. Pass --project <id> or run: gcloud config set project <id>" >&2; exit 1; }

echo ">>> $DIR  ->  $PROJECT / $SERVICE ($REGION)   as $account"

# Enable the APIs the deploy needs (idempotent).
gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com \
  --project "$PROJECT" >/dev/null 2>&1 || true

# 1. Assemble the build context (survey runtime files + shared build assets).
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
ctx="$tmp/ctx"; mkdir "$ctx"
EXCLUDES=(.git .gitignore .gitattributes .env .Renviron _survey survey_files survey.html preview_data.csv local_data.csv rsconnect manifest.json .posit .Rproj.user .Ruserdata .DS_Store)
if command -v rsync >/dev/null 2>&1; then
  rsync_args=(); for e in "${EXCLUDES[@]}"; do rsync_args+=(--exclude="$e"); done; rsync_args+=(--exclude='*.Rproj')
  rsync -a "${rsync_args[@]}" "$DIR"/ "$ctx"/
else
  cp -R "$DIR"/. "$ctx"/; ( cd "$ctx" && rm -rf "${EXCLUDES[@]}" ./*.Rproj 2>/dev/null || true )
fi
cp "$ASSETS/Dockerfile"   "$ctx/Dockerfile"
cp "$ASSETS/start.sh"     "$ctx/start.sh"
cp "$ASSETS/dockerignore" "$ctx/.dockerignore"

# packages.txt — extra R packages from the survey's library()/require() calls
: > "$ctx/packages.txt"
grep -rhoE '(library|require)\(([^),]+)\)' "$DIR/app.R" "$DIR/survey.qmd" 2>/dev/null \
  | sed -E "s/.*\(['\"]?([A-Za-z0-9._]+)['\"]?\)/\1/" | sort -u \
  | while IFS= read -r p; do
      [ -z "$p" ] && continue
      case " $EXCLUDE_PKGS " in *" $p "*) continue ;; esac
      echo "$p" >> "$ctx/packages.txt"
    done
echo "    packages.txt: $(paste -sd' ' "$ctx/packages.txt" 2>/dev/null || true)"

# 2. Database mode: store SD_* in Secret Manager and wire them into the service.
mode_val="$(grep -E '^[[:space:]]*mode:[[:space:]]*' "$DIR/survey.qmd" 2>/dev/null | head -1 | sed -E 's/.*mode:[[:space:]]*//; s/[[:space:]]*#.*//; s/["'"'"']//g; s/[[:space:]]*$//')"
mode_val="${mode_val:-database}"
SECRET_FLAGS=()
if [ "$SECRETS" = true ] && [ "$mode_val" = database ]; then
  if [ -f "$DIR/.env" ]; then
    echo "    database mode — storing DB secrets in Secret Manager from $DIR/.env ..."
    if bash "$SCRIPT_DIR/set-secrets.sh" --project "$PROJECT" --env "$DIR/.env"; then
      SECRET_FLAGS=(--set-secrets=SD_HOST=SD_HOST:latest,SD_PORT=SD_PORT:latest,SD_DBNAME=SD_DBNAME:latest,SD_USER=SD_USER:latest,SD_TABLE=SD_TABLE:latest,SD_PASSWORD=SD_PASSWORD:latest)
    else
      echo "    ! secrets not stored (see above). Deploying without DB credentials;" >&2
      echo "      the survey will show 'DATABASE NOT CONNECTED' until they are set." >&2
    fi
  else
    echo "    database mode but no .env in $DIR — deploying without DB credentials." >&2
  fi
fi

# 3. Deploy (gcloud builds the image via Cloud Build, then rolls out the service).
gcloud run deploy "$SERVICE" \
  --source "$ctx" \
  --project "$PROJECT" \
  --region "$REGION" \
  --allow-unauthenticated \
  --port 8080 \
  --memory "$MEMORY" --cpu 1 --cpu-boost \
  --timeout 3600 \
  --session-affinity \
  --min-instances 0 --max-instances "$MAX_INSTANCES" \
  ${SECRET_FLAGS[@]+"${SECRET_FLAGS[@]}"} \
  --quiet

# Report the canonical project-number URL (matches the Cloud Run console), not
# the legacy hash form returned by status.url. Then the console dashboard link.
project_number="$(gcloud projects describe "$PROJECT" --format='value(projectNumber)' 2>/dev/null)"
if [ -n "$project_number" ]; then
  url="https://${SERVICE}-${project_number}.${REGION}.run.app"
else
  url="$(gcloud run services describe "$SERVICE" --project "$PROJECT" --region "$REGION" --format='value(status.url)' 2>/dev/null)"
fi
dashboard="https://console.cloud.google.com/run/detail/${REGION}/${SERVICE}/metrics?project=${PROJECT}"
echo "    deployed  -> ${url:-（check: gcloud run services list）}"
echo "    dashboard -> ${dashboard}"
