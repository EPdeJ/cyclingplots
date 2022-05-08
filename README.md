# cyclingplots
to make cycling plots
<img src="https://github.com/EPdeJ/cyclingplots/blob/main/Yilan-Wulling.png">


## NOTES FOR FUNCTION USE
 
- This function will plot an elevation profile based on garmin gpx files
- 6 levels have been set as categories for the area under the curve colors
- sf package is used to import the gpx, rolling averages are calculated by the zoo package
 
## ---------------parameters to set---------------------------
- `filepath` need to be set to locate the gpx file, for example "C:/Users/user/Desktop/yilan-wulling.gpx"

- `gpxrolling` will define the roling avarage based on the number of gps point and thereby the level/detail of the gradient #' brackets. Smaller numbers will  make it more detailed, the plotting will take longer. For example, if a gpx file contains 2500 points, and the rolling average will be set to 2500, then the gradient will just be the gradeint for the full climb.

- `coleasy` will set the color of the downhill part
- `colorscalestr` will set the colors of the gradient levels. String lenght 6.
- `linecolor` set the color of the height profile
- `maxlinecol` sets the color of the maximum height line 
- `transparency` set the transparency of the area under the curve
- `elevationbreaksstr` sets the how the rolling gradient should be divided in different levels of difficulty
- `plotsave` and `plotname` can be set to save the plot automatically with **plotsave** as logical. Plots will be saved in the working directory.
- `plotsavedimentiondpisstr` sets dimentions and dpi for the plot to save. Needs a string of 4 with width, height, unit and dpi
