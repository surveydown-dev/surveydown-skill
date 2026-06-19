# Walkthrough: template_conditional_skipping
#
# Demonstrates sd_skip_if() (app.R): certain answers SKIP the respondent to the
# screenout page; others let them finish at the normal end page.
#   simple:  vehicle_simple == "no"                          -> screenout
#   complex: vehicle_complex == "no" AND buy_vehicle == "no" -> screenout
#
# We run THREE passes (reload between) to show every branch:
#   A. complete normally (no skip):  Yes ; Yes, Yes  -> end
#   B. simple skip:                  No              -> screenout
#   C. complex skip:                 Yes ; No, No    -> screenout

opt <- function(id, value) sprintf('input[name="%s"][value="%s"]', id, value)

pass_A_normal <- function() {
  cat("== Pass A: complete normally (no skip) ==\n")
  click("#welcome_next")
  pause(1)
  click(opt("vehicle_simple", "yes")) # not the skip answer
  pause(0.5)
  click("#basic_skipping_next")
  pause(1.2)
  click(opt("vehicle_complex", "yes"))
  click(opt("buy_vehicle", "yes")) # not "no, no" -> no skip
  pause(0.5)
  click("#complex_skipping_next")
  pause(2.2) # lands on the normal END page
}

pass_B_simple <- function() {
  cat("== Pass B: simple skip (No -> screenout) ==\n")
  click("#welcome_next")
  pause(1)
  click(opt("vehicle_simple", "no")) # triggers the simple skip
  pause(0.8)
  click("#basic_skipping_next")
  pause(2.2) # jumps straight to the SCREENOUT page
}

pass_C_complex <- function() {
  cat("== Pass C: complex skip (No, No -> screenout) ==\n")
  click("#welcome_next")
  pause(1)
  click(opt("vehicle_simple", "yes")) # simple condition does NOT skip
  pause(0.5)
  click("#basic_skipping_next")
  pause(1.2)
  click(opt("vehicle_complex", "no"))
  click(opt("buy_vehicle", "no")) # both "no" -> complex skip
  pause(0.8)
  click("#complex_skipping_next")
  pause(2.2) # jumps to the SCREENOUT page
}

pass_A_normal()
reload(wait = 6)
pass_B_simple()
reload(wait = 6)
pass_C_complex()

cat("Done: conditional skipping demonstrated (normal end + both screenout paths).\n")
