# tpw_trout_fishing
Texas Parks and Wildlife stocks local fishing holes with Rainbow Trout in the winter. TPW provides a table of locations. As a transplant to Texas I didn't know offhand where some of the fisheries are located so I built something to query the data and provide me a list of the top n fisheries withing a certain distance from home.

Steps:
1. Download the TPW Rainbow Trout stocking info (manually although I could've written a web scrapper to do this), save as CSV
2. In R, using the HERE route.api I built a function to assess the distance and the time to drive from location A (my home) to B
3. Use the above function to query the distance and drive-time to the stocked fisheries and filter based on user criteria
4. Create a summary on the filtered data, such as:
  a. Which DOW will have the greatest number of stocked fish
5. Output summary and fisheries within defined distance/time from location A (my home)
