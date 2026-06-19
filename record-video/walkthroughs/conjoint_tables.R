# Walkthrough: template_conjoint_tables
#
# Choice-based-conjoint survey (table version) -- same flow and question ids as
# the button version; here each CBC question shows an attribute TABLE above
# simple "Option 1/2/3" buttons. Full flow:
#   welcome -> consent -> favorite_fruit -> screening -> educational ->
#   cbc_practice -> cbc_intro -> cbc_q1..q6 -> apple_knowledge ->
#   demographics -> end_normal.
# app.R: sd_skip_if screens out (screenout=="blue" / consent "no"); sd_show_if
# reveals fav_fruit when like_fruit is yes/kind_of. We answer to reach the
# normal end. CBC options are keyed option_1/2/3 -> click by value.

opt <- function(id, value) sprintf('input[name="%s"][value="%s"]', id, value)

cat("welcome\n")
click("#welcome_next"); pause(1)

cat("consent (yes/yes to proceed)\n")
click(opt("consent_age", "yes"))
click(opt("consent_understand", "yes"))
click("#consent_next"); pause(1)

cat("favorite_fruit (like_fruit=yes reveals fav_fruit via show_if)\n")
click(opt("like_fruit", "yes"))
set_text("fav_fruit", "Mango")
click("#favorite_fruit_next"); pause(1)

cat("screening (choose Red so we are NOT screened out)\n")
click(opt("screenout", "red"))
click("#screening_next"); pause(1)

cat("educational\n")
click("#educational_next"); pause(1)

cat("cbc practice\n")
click_button_value("cbc_practice", "option_1")
click("#cbc_practice_page_next"); pause(1)

cat("cbc intro\n")
click("#cbc_intro_next"); pause(1)

# Six conjoint choice tasks (vary the chosen option to look natural).
for (i in 1:6) {
  cat("cbc_q", i, "\n", sep = "")
  qid <- paste0("cbc_q", i)
  val <- paste0("option_", ((i - 1) %% 3) + 1)
  click_button_value(qid, val)
  click(sprintf("#cbc_q%d_page_next", i))
  pause(0.8)
}

cat("apple_knowledge (selects)\n")
set_select("apple_knowledge_1", "fuji")
set_select("apple_knowledge_2", "gala")
click("#apple_knowledge_next"); pause(1)

cat("demographics\n")
set_select("year_of_birth", "1990")
set_select("gender", "female")
set_select("education", "bachelor_degree")
set_text("feedback", "Great survey, thanks!")
click("#demographics_next"); pause(1.5)

cat("end_normal (completion code shown)\n")
pause(2)

cat("Done.\n")
