# Walkthrough: template_question_types
#
# welcome (skip_to_page mc) -> question_types page (one of every type) ->
# question_formatting page -> end. sd_skip_if routes "end"/"question_formatting"
# choices; picking "question_types" just proceeds to the next page.
# Button-style questions use click_button/click_button_value (real CDP clicks);
# plain mc/mc_multiple/mc_image use input[name][value].

opt <- function(id, value) sprintf('input[name="%s"][value="%s"]', id, value)

cat("Welcome: route to the Question Types page...\n")
click(opt("skip_to_page", "question_types"))
click("#welcome_next")
pause(1)

cat("Question Types page: one of every supported type...\n")
set_text("silly_word", "flibberjam")
set_text("silly_paragraph", "Once upon a silly time, a banana wore a tiny hat.")
set_text("age", "42")

click(opt("artist", "taylor_swift")) # mc
click_button("fruit", "Apple") # mc_buttons

click(opt("swift", "fearless")) # mc_multiple
click(opt("swift", "red"))
click_button("michael_jackson", "Thriller (1982)") # mc_multiple_buttons
click_button("michael_jackson", "Billie Jean (1982)")

click(opt("apple_image", "fuji")) # mc_image
click(opt("apple_buy", "fuji")) # mc_multiple_image
click(opt("apple_buy", "honeycrisp"))

set_select("education", "college_grad") # select

set_slider("climate_care", 4) # slider -> "Believe"
set_slider_numeric("slider_single_val", 7) # numeric slider
set_slider_range("slider_range", 2, 8) # numeric range slider

set_date("dob", "1990-05-15")
set_daterange("hs_date", "2004-09-01", "2008-06-15")

click(opt("car_preference_buy_gasoline", "disagree")) # matrix row 1
click(opt("car_preference_buy_ev", "agree")) # matrix row 2

click(opt("vehicle_features_gasoline", "affordable")) # matrix_multiple
click(opt("vehicle_features_gasoline", "fast"))
click(opt("vehicle_features_ev", "eco_friendly"))

pause(1)
click("#question_types_next")
pause(1.5)

cat("Question Formatting page...\n")
click(opt("markdown_1", "bold")) # mc with markdown
click(opt("markdown_2", "italic")) # mc_multiple with markdown
click(opt("markdown_2", "bold"))
click_button("markdown_3", "Bold option") # mc_buttons with markdown
click_button("markdown_4", "Italic option") # mc_multiple_buttons with markdown
click_button("markdown_4", "Bold italic option")
click_button_value("html_buttons", "option_1") # mc_buttons with HTML/image label
set_text("change_width", "This text area is 40% wide.")

pause(1)
click("#question_formatting_next")
pause(2) # end page

cat("Done: all question types and formatting demonstrated.\n")
