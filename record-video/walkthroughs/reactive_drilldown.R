# Walkthrough: template_reactive_drilldown
#
# One survey page (id = "vehicle") with three select questions, then an end page:
#   - year  : static select (model years 2025..2010)
#   - make  : select rendered server-side (mpg manufacturers)
#   - model : select rendered REACTIVELY from the chosen make
#             (app.R observe()s sd_value("make") and re-renders the options)
#
# The whole point is the drilldown: the model list changes with the make. So we
# do THREE rounds in one survey -- pick a random year once, then cycle through
# three different makes, each time waiting for the model dropdown to re-render
# for that make before picking a model from the (new) list.

# Curated valid (make, model) pairs -- exact mpg-derived str_to_title labels, so
# each model is guaranteed to exist in that make's reactively-rendered list.
pairs <- list(
  c("Toyota", "Corolla"),
  c("Honda", "Civic"),
  c("Audi", "A4"),
  c("Ford", "Mustang"),
  c("Volkswagen", "Jetta"),
  c("Nissan", "Altima"),
  c("Subaru", "Forester Awd"),
  c("Chevrolet", "Malibu"),
  c("Dodge", "Durango 4Wd"),
  c("Hyundai", "Sonata")
)
chosen <- sample(pairs, 3) # three distinct make/model rounds
year <- as.character(sample(2010:2025, 1)) # random model year

# Wait until the reactively re-rendered `model` selectize actually contains the
# target option (the make change triggers a server round-trip + re-render).
# Functional wait, not time-factor scaled.
wait_model_option <- function(value, timeout = 8) {
  t0 <- Sys.time()
  repeat {
    ok <- js(sprintf(
      "(function(){var e=$('#model')[0]; var s=e&&e.selectize;
         return !!(s && s.options && s.options[%s]);})()",
      js_str(value)
    ))
    if (isTRUE(ok)) return(invisible(TRUE))
    if (as.numeric(difftime(Sys.time(), t0, units = "secs")) > timeout) break
    Sys.sleep(0.2)
  }
  invisible(FALSE)
}

cat("Selecting model year:", year, "\n")
set_select("year", year)
pause(1.2)

for (i in seq_along(chosen)) {
  mk <- chosen[[i]][1]
  md <- chosen[[i]][2]
  cat(sprintf("Round %d: make = %s -> model = %s\n", i, mk, md))

  set_select("make", mk)
  pause(0.8) # the model question starts re-rendering for this make
  wait_model_option(md) # ensure the new model options are in before picking
  set_select("model", md) # opens the (make-specific) model list and picks one
  pause(1.8) # hold so the chosen model is clearly on camera
}

# Advance to the end page. surveydown names the next button "<page_id>_next".
click("#vehicle_next", wait = 3)
pause(2)

cat("Reached end of survey.\n")
