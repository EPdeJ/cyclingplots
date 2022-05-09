# Cycling plots

### Description
Here's how to make beautiful cycling plots. Like this one!
<img src="https://github.com/EPdeJ/cyclingplots/blob/main/Yilan-Wulling.png">

### Usage
 
- This function will plot an elevation profile based on garmin edge 530 gpx files
- Works with exported strava gpx files as well
- sf package is used to uniformly import the gpx files rolling averages are calculated by the zoo package
- for now, elevation is needed as a variable in the gpx files, later support for gpx files without elevation will be added. 
 
### Arguments
- `filepath` need to be set to locate the gpx file, for example "C:/Users/user/Desktop/yilan-wulling.gpx"
- `gpxrolling` will define the rolling average based on the number of gps point and thereby the level/detail of the gradient facets. 
- `coleasy` will set the color of the downhill part
- `colorscalestr` will set the colors of the gradient levels. String length 6.
- `linecolor` set the color of the height profile
- `maxlinecol` sets the color of the maximum height line 
- `transparency` set the transparency of the area under the curve
- `elevationbreaksstr` sets the how the rolling gradient should be divided in different levels of difficulty
- `plotsave` and `plotname` can be set to save the plot automatically with **plotsave** as logical. Plots will be saved in the working directory.
- `plotsavedimentiondpisstr` sets dimensions and dpi for the plot to save. Needs a string of 4 with width, height, unit and dpi

### DEtails
- 6 levels have been set as categories for the area under the curve colors, based on the following grade categories:
  - -Inf to 0 %
  - 0 to 2.5 %
  - 2.5 tot 5 %
  - 5 to 7.5 %
  - 7.5 to 10 %
  - 10 to Inf %
  The levels be adjusted with `colorscalestr` with sting length 6. (example: c(-Inf, 0, 2.5, 5, 7.5, 10, Inf))
- For `gpxrolling`, smaller numbers will  make the plot more detailed (smaller facets), but note that the plotting will take longer. For example, if a gpx file only contains a climb of 2500 geometry points, and the rolling average will be set to 2500, then the gradient calculated will just be the gradient for the full climb, hence the plot will only contain one facet. 
### Note
