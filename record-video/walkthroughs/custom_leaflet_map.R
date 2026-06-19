# Walkthrough: template_custom_leaflet_map
#
# One page (map_of_usa) with a custom leaflet map question (state_selection):
# clicking a US state selects it (turns orange) and "You live in: <state>"
# updates below. Then end. The click must be a REAL mouse click on the canvas
# map, so we use cdp_click at the map's center (a central US state at zoom 4).

cat("Waiting for the leaflet map to load...\n")
wait_for("#usa_map")
Sys.sleep(4) # let map tiles + state polygons finish rendering before clicking

cat("Clicking a state on the map...\n")
cdp_click("#usa_map", wait = 2) # center of the US map -> a central state
pause(2.5) # the state turns orange and "You live in: <state>" appears

click("#map_of_usa_next")
pause(2) # end page

cat("Done.\n")
