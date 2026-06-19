# Walkthrough: template_conditional_showing
#
# Demonstrates sd_show_if() (app.R): a question APPEARS when its condition holds
# and DISAPPEARS when it stops holding. For each of the 6 cases we comply (the
# conditional question appears) then un-comply (it disappears) before moving on.
#
# Conditions (app.R):
#  1 basic_showif:    penguins_simple == "other"                       -> penguins_simple_other
#  2 custom_showif:   penguins_complex == "other" & show_other=="show" -> penguins_complex_other
#  3 numeric_show_if: car_number > 1                                   -> ev_ownership
#  4 multi_show_if:   fav_fruits has apple/banana                      -> apple_or_banana
#                     length(fav_fruits) > 3                           -> fruit_number
#  5 custom_function: pet_number > 1 (custom fn)                       -> pet_type
#  6 conditional_page: pet_preference == 'cat' -> cat_page; 'dog' -> dog_page

opt <- function(id, value) sprintf('input[name="%s"][value="%s"]', id, value)

# Scroll a now-visible conditional question to center and hold it on camera.
reveal <- function(cond_id, hold = 1.4) {
  scroll_into_view(paste0("#container-", cond_id))
  wait_scroll_settled()
  pause(hold)
}

cat("== Welcome ==\n")
click("#welcome_next")
pause(1)

# 1. Simple: pick "Other" -> text appears; pick "Adélie" -> text disappears.
cat("== 1. Simple conditional showing ==\n")
click(opt("penguins_simple", "other"))
reveal("penguins_simple_other") # appears
click(opt("penguins_simple", "adelie"))
pause(1.2) # disappears
click("#basic_showif_next")
pause(1)

# 2. Complex: "Other" + "Show" -> text appears; switch to "Hide" -> disappears.
cat("== 2. Complex conditional showing ==\n")
click(opt("penguins_complex", "other"))
click(opt("show_other", "show"))
reveal("penguins_complex_other") # appears (both conditions met)
click(opt("show_other", "hide"))
pause(1.2) # disappears
click("#custom_showif_next")
pause(1)

# 3. Numeric: car_number > 1 -> ev_ownership appears; == 1 -> disappears.
cat("== 3. Numeric conditional showing ==\n")
set_text("car_number", "2")
reveal("ev_ownership") # appears
set_text("car_number", "1")
pause(1.2) # disappears
click("#numeric_show_if_next")
pause(1)

# 4. Multiple inputs: apple -> apple_or_banana; 4 fruits -> fruit_number;
#    deselect apple (back to 3, no apple/banana) -> BOTH disappear at once.
cat("== 4. Multiple-input conditional showing ==\n")
# fav_fruits is a checkboxGroupButtons (button group): click LABELS, not inputs.
click_button("fav_fruits", "Apple")
reveal("apple_or_banana") # apple/banana condition
click_button("fav_fruits", "Peach")
click_button("fav_fruits", "Orange")
click_button("fav_fruits", "Grape") # now 4 selected -> length > 3
reveal("fruit_number") # >3 condition
click_button("fav_fruits", "Apple") # deselect apple -> 3 left, no apple/banana
pause(1.4) # BOTH disappear
click("#multi_show_if_next")
pause(1)

# 5. Custom function: pet_number > 1 -> pet_type appears; == 1 -> disappears.
cat("== 5. Custom-function conditional showing ==\n")
set_text("pet_number", "2")
reveal("pet_type") # appears
set_text("pet_number", "1")
pause(1.2) # disappears
click("#custom_function_next")
pause(1)

# 6. Conditional page: Cat -> cat page; go Previous, switch to Dog -> dog page.
#    (The Previous button is enabled, so we can show BOTH branches in one run.)
cat("== 6. Conditional page showing (both branches via Previous) ==\n")
click(opt("pet_preference", "cat"))
pause(0.8)
click("#conditional_page_next")
pause(2.2) # Cat page (cat image) -- routed here because we chose Cat
click("#cat_page_prev") # Previous: back to the Cat/Dog selection
pause(1.5)
click(opt("pet_preference", "dog")) # switch the answer
pause(0.8)
click("#conditional_page_next")
pause(2.2) # Dog page (dog image) -- now routed here instead
click("#dog_page_next")
pause(2) # end page

cat("Done: conditional showing demonstrated (appear + disappear) for all cases.\n")
