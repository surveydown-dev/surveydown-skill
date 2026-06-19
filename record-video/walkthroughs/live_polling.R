# Walkthrough: template_live_polling
#
# Live polling demo. mode: database (Supabase; credentials in the template's
# .env). The welcome page has one mc question `penguins` (adelie / chinstrap /
# gentoo); the results page shows your pick plus a LIVE histogram
# (penguin_plot) of all responses in the database, refreshed every 5s
# (app.R: sd_get_data(refresh_interval = 5)).
#
# To show the "live" part we run THREE sessions back to back. Each session casts
# one random penguin vote, advances to the results page, and holds past a full
# refresh cycle so the histogram redraws with the new vote included. Between
# sessions we reload the page, which (use-cookies: false) starts a brand-new
# Shiny session on the welcome page -- so the viewer watches the histogram grow
# vote by vote.

# This template reads a touch faster than the 0.8 default; pin its pace here so
# re-runs reproduce it without passing SD_TIME_FACTOR on the command line. (An
# explicit SD_TIME_FACTOR env var, if set, still takes precedence -- the
# orchestrator reads it at startup; this only sets the in-script default.)
if (!nzchar(Sys.getenv("SD_TIME_FACTOR"))) SD_TIME_FACTOR <- 0.7

REFRESH_INTERVAL <- 5 # seconds; mirrors app.R's sd_get_data(refresh_interval)

# Shuffle the three penguins so each session casts a different random vote and
# all three bars grow -- a clear "independent participants" demonstration.
picks <- sample(c("adelie", "chinstrap", "gentoo"))

vote_then_view <- function(choice, n) {
  cat(sprintf("--- Session %d: voting '%s' ---\n", n, choice))
  wait_for('input[name="penguins"]')
  pause(0.5) # start-of-session beat (halved from 1)
  click(sprintf('input[name="penguins"][value="%s"]', choice))
  pause(0.6)
  click("#welcome_next")
  pause(1) # let the results page render

  wait_for("#penguin_plot")
  scroll_into_view("#penguin_plot")
  wait_scroll_settled()
  # End-of-session hold, trimmed. The 5s DB refresh is a HARD FLOOR: the
  # histogram only redraws every 5s, so the TOTAL results-page dwell (the
  # scroll/settle above + this sleep + beat) must still clear one 5s cycle or
  # the new vote won't be on camera. ~4s here (down from 7), plus the ~1.5s of
  # scroll/settle, clears 5s with margin. (Functional wait, not scaled.)
  Sys.sleep(REFRESH_INTERVAL - 1) # ~4s (was REFRESH_INTERVAL + 2 = 7)
  pause(1)                        # brief demo beat (halved from 2)
}

for (i in seq_along(picks)) {
  if (i > 1) {
    cat("Refreshing to start a fresh session...\n")
    reload(wait = 4) # new Shiny session, back on the welcome page (halved from 7)
  }
  vote_then_view(picks[i], i)
}

cat("Done: three live-polling sessions recorded; histogram grew each round.\n")
