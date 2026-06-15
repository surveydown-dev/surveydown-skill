---
title: "{{TITLE}}"
emoji: 📋
colorFrom: blue
colorTo: indigo
sdk: docker
app_port: 7860
pinned: false
---

# {{TITLE}}

A [surveydown](https://surveydown.org) survey, hosted on Hugging Face Spaces with
the Docker SDK. The container installs R, the Quarto CLI, and surveydown, then
renders and serves the survey on port 7860.

Runs in `mode: preview`, so responses go to a local `preview_data.csv` — and
Hugging Face Space disks are **ephemeral**, so that file is lost on restart. For
real data collection, switch to `mode: database` with an external PostgreSQL
database (see <https://surveydown.org/docs/storing-data>).
