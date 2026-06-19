# Walkthrough: template_conditional_stopping
#
# Demonstrates sd_stop_if() (app.R): clicking "Next" with an INVALID answer is
# blocked and a message pops up; once corrected, navigation proceeds.
#   page1: nchar(zip) != 5     -> "Zip code must be 5 digits."
#          yob <= 1900         -> "Year of birth must be after 1900."
#   page2: nchar(phone) != 10  -> "Phone number must be 10 digits."

opt <- function(id, value) sprintf('input[name="%s"][value="%s"]', id, value)

cat("== Page 1: invalid zip + yob -> blocked ==\n")
set_text("zip", "123") # 3 digits -> invalid
set_text("yob", "1850") # <= 1900 -> invalid
click("#page1_next", wait = 0.5) # blocked; stop messages pop up together
pause(2.4) # show the stop message(s)
dismiss_alert()
pause(0.6)

cat("== Page 1: correct the values -> proceed ==\n")
set_text("zip", "12345") # 5 digits
set_text("yob", "1990") # > 1900
click(opt("pet_preference", "cat")) # the explicitly-required question
pause(0.6)
click("#page1_next")
pause(1.5)

cat("== Page 2: invalid phone -> blocked ==\n")
set_text("phone", "12345") # 5 digits -> invalid
click("#page2_next", wait = 0.5) # blocked; stop message pops up
pause(2.4) # show the stop message
dismiss_alert()
pause(0.6)

cat("== Page 2: correct the phone -> proceed ==\n")
set_text("phone", "1234567890") # 10 digits
pause(0.4)
click("#page2_next")
pause(2) # end page

cat("Done: conditional stopping demonstrated (blocked then corrected).\n")
