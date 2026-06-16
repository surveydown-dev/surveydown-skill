# Deploy via shinylive (serverless / in-browser) — ❌ NOT VIABLE for surveydown

**Status: not supported.** [shinylive](https://posit-dev.github.io/r-shinylive/)
compiles a Shiny app to WebAssembly so it runs **entirely in the browser** (via
[webR](https://docs.r-wasm.org/webr/latest/)) and can be hosted as **static files**
(GitHub Pages, Netlify, Cloudflare Pages) with **no server, no quota, no cost**.
That would be ideal for an unlimited free template gallery — so we tested it.

It does **not** work for surveydown. This folder documents *why*, so nobody has to
rediscover it. For real deployments use [`../deploy-hugging-face/`](../deploy-hugging-face/README.md)
or a server (Oracle Always Free / a small VPS / Google Cloud Run).

## The test (2026-06-16)

- R 4.5.2, `shinylive` 0.5.0, `surveydown` 1.3.0, Quarto 1.9.37.
- Clean copy of `template_default` (`app.R` + `survey.qmd` + `images/`, `mode: preview`).
- `shinylive::export("template_default", "out")` → **failed**:

  ```
  Error in `get_github_wasm_assets()`:
  ! Can't find GitHub release for github::surveydown-dev/surveydown@...
  ! GitHub API error (404): Not Found
  ℹ Alternatively, install a CRAN version of this package to use the default
    Wasm binary repository.
  ```

## Why it fails — three blockers, two of them architectural

1. **No webR/WASM build of surveydown exists.** shinylive resolves every
   `library()` to a **WebAssembly binary**. surveydown isn't in the default webR
   binary repo (it's a GitHub package, dev versions only; CRAN has 1.0.1 with no
   Wasm build either), and it publishes no GitHub-release Wasm assets — so the
   export aborts before producing a runnable app. Its dependency tree (DBI, pool,
   etc.) would each need Wasm builds too.

2. **surveydown renders `survey.qmd` with the Quarto CLI at runtime.** The survey
   UI is produced by running Quarto on `survey.qmd` when the app starts (this is
   why our Docker image ships the Quarto CLI and renders at startup). **Quarto is a
   native binary and cannot run inside the browser / webR.** Even a pre-rendered
   `_survey/` only partially helps — surveydown still drives behavior through the R
   runtime, and blocker 1 remains.

3. **Server-side features can't run client-side.** `mode: database` writes through
   `DBI`/`pool` to PostgreSQL, and cookies/session handling are server concepts.
   In the browser there is no server to hold a DB connection or secrets, so real
   data collection is impossible (only ephemeral, in-tab state would work).

Blockers 2 and 3 are inherent to how surveydown works, so this isn't a packaging
gap that a quick fix closes.

## What would have to change upstream (for reference)

shinylive could only become viable if surveydown were re-architected to:

- ship **webR/Wasm builds** of surveydown and all dependencies;
- **pre-render** the survey so no Quarto CLI is needed at runtime (fully static UI);
- collect data via a **browser-callable API** (e.g. a Supabase REST/Edge endpoint
  with row-level security) instead of a server-side `DBI` connection.

That's a large upstream effort and a different product shape. Until then, treat
shinylive as **out of scope**.

## Use instead

| Need | Use |
|------|-----|
| A few live surveys, easy, free | [`../deploy-hugging-face/`](../deploy-hugging-face/README.md) (CPU, ~3 concurrent on free) |
| Many surveys, free-forever, you manage a box | Oracle Cloud Always Free + Shiny Server / ShinyProxy |
| Many low-traffic surveys, managed, scale-to-zero | Google Cloud Run (max-instances=1, WebSocket tweak) |
