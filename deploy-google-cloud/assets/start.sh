#!/usr/bin/env bash
# Cloud Run mounts the image filesystem read-only, but surveydown renders the
# survey into _survey/ next to the app at startup (every mode), and Quarto needs
# a writable HOME/cache. /tmp is the one writable (in-memory) location, so copy
# the app there and run from it. Shiny binds Cloud Run's injected $PORT (def 8080).
set -e
export HOME=/tmp/home
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export TMPDIR=/tmp
mkdir -p /tmp/app "$HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME"
cp -a /home/user/app/. /tmp/app/
cd /tmp/app
exec R -q -e "port <- as.integer(Sys.getenv('PORT','8080')); options(shiny.port = port, shiny.host = '0.0.0.0'); shiny::runApp('/tmp/app', launch.browser = FALSE)"
