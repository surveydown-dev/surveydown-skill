# Deploy a surveydown survey to Hugging Face Spaces

Deploy **any** surveydown survey — one you made from a template or wrote from
scratch — to a **Hugging Face Space** (Docker SDK). The generator script
(`deploy.sh`) and shared assets live in this folder.

Your survey directory is the source of truth. The tooling only *generates* the
Hugging Face packaging (a Dockerfile, a README, a package list) and pushes it to a
Space — it never modifies your survey.

## Why Hugging Face

surveydown surveys are live R/Shiny apps, so they need a host that runs R — not a
static host. Hugging Face Spaces (Docker SDK) runs R Shiny, has no per-account app
limit on the free tier, and serves each app on a clean standalone URL with no HF
chrome: `https://<owner>-<space>.hf.space`.

Trade-offs to know:
- One Space = one container = one R process (no horizontal scaling). Fine for
  modest N; not for thousands of simultaneous users.
- Free Spaces sleep after inactivity and wake on next visit (cold start).
- Container disk is ephemeral → never rely on `preview_data.csv` for real data;
  use `mode: database` + external PostgreSQL.

## Prerequisites

- `git`, and `rsync` (the script falls back to `cp` if it's missing).
- A surveydown survey directory containing `app.R` and `survey.qmd`.
- The target Space already exists (Docker SDK). Create one at
  <https://huggingface.co/new-space>, or with the HF CLI:
  ```bash
  hf repo create <owner>/<space> --repo-type space --space-sdk docker
  ```
- Git must be able to push to `huggingface.co`. Run `hf auth login`, or you'll be
  prompted for your username and a **Write** token on the first push.

## Usage

Run from your survey directory (or pass `--dir`):

```bash
# from inside your survey folder:
/path/to/deploy-hugging-face/deploy.sh --space yourname/my-survey

# or point at the survey explicitly, from anywhere:
/path/to/deploy-hugging-face/deploy.sh --space yourname/my-survey --dir ~/surveys/my-survey

# build only — assemble the Space folder under /tmp and inspect it, no push:
/path/to/deploy-hugging-face/deploy.sh --space yourname/my-survey --no-push

# set the display title shown on the Space card (URL is unaffected):
/path/to/deploy-hugging-face/deploy.sh --space yourname/my-survey \
  --title "My Survey — Pilot Wave 1"
```

(When the skill is installed, the script is at
`~/.claude/skills/surveydown-skill/deploy-hugging-face/deploy.sh`.)

The Space name is yours to choose; the survey loads at
`https://<owner>-<space>.hf.space`.

### Display title vs. URL slug

A Space has two distinct names:

- **URL slug** — the `<owner>/<name>` you pass to `--space`. It defines the URL
  (`https://<owner>-<name>.hf.space`) and must be URL-safe (lowercase, dashes).
  Changing it later (Space → Settings → *Rename or transfer*) **changes the URL**.
- **Display title** — the heading on the Space card. By default it's the slug in
  Title Case (`questions-yml` → "Questions Yml"). Pass `--title "Any Text"` to set
  it to anything (spaces and punctuation allowed); the **URL is unaffected**.

Because the README (which carries the title) is *generated* on every deploy, set
the title with `--title` rather than hand-editing it on Hugging Face — otherwise
the next deploy overwrites your edit.

## How the generator works

For the survey directory, `deploy.sh`:

1. Copies the survey's runtime files (`app.R`, `survey.qmd`, and any `images/`,
   `data/`, `www/`, `*.yml`, etc.), excluding build artifacts and dev junk
   (`_survey/`, `preview_data.csv`, `rsconnect/`, `.git/`, `*.Rproj`, …).
2. Adds the shared `assets/Dockerfile`, a generated `README.md` (with Hugging Face
   frontmatter), and a generated `packages.txt`.
3. Pushes the result to your Space, which auto-rebuilds.

`_survey/` is **not** shipped — the container renders the survey at startup
(Quarto is in the image). This also keeps the Space repo free of binary files,
which Hugging Face rejects in plain git.

### One shared Dockerfile

`assets/Dockerfile` is the same for every survey. The R packages a given survey
needs are written to `packages.txt` (derived from its `library()`/`require()`
calls), so there is one Dockerfile to maintain. surveydown installs from GitHub
(dev v1.3.0; CRAN only has 1.0.1). The Quarto CLI is pinned to a direct download
URL (the GitHub API gets rate-limited / 403 on build servers). A survey needing an
unusual system library may need a one-line edit to the Dockerfile.

## Files (in this folder)

| File | Purpose |
|------|---------|
| `deploy.sh` | Build + push generator |
| `assets/Dockerfile` | Shared Dockerfile used by every Space |
| `assets/dockerignore` | Copied into each Space as `.dockerignore` |
| `assets/space-readme.template.md` | README template (HF frontmatter) for each Space |
