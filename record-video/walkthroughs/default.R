# Walkthrough: template_default
#
# The minimal surveydown survey: welcome (mc penguins) -> page2 (text) -> end.

opt <- function(id, value) sprintf('input[name="%s"][value="%s"]', id, value)

cat("Welcome page (mc)...\n")
click(opt("penguins", "gentoo"))
click("#welcome_next") # labelled "Go to Page 2" via sd_nav(), id is still welcome_next
pause(1)

cat("Page 2 (text)...\n")
set_text("silly_word", "flibberflabber")
click("#page2_next")
pause(2) # end page (Finish button)

cat("Done.\n")
