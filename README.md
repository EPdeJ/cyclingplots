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
- `ggsavepar` sets dimensions and dpi for the plot to save. Needs a string of 4 with width, height, unit and dpi

### Details
- 6 levels have been set as categories for the area under the curve colors, based on the following grade categories:
  - -Inf to 0 %
  - 0 to 2.5 %
  - 2.5 tot 5 %
  - 5 to 7.5 %
  - 7.5 to 10 %
  - 10 to Inf %
  
  The levels can be adjusted with `colorscalestr` with sting length 6. (example: c(-Inf, 0, 2.5, 5, 7.5, 10, Inf))
- For `gpxrolling`, smaller numbers will  make the plot more detailed (smaller facets), but note that the plotting will take longer. For example, if a gpx file only contains a climb of 2500 geometry points, and the rolling average will be set to 2500, then the gradient calculated will just be the gradient for the full climb, hence the plot will only contain one facet. 

### Note

#### Examples

```{r elevation-plot, dev='png',message=FALSE}
elevationprofile("gpx/crazy ride.gpx") # simple use, using standard presets 

elevationprofile("test.gpx,                         #set filepath including .gpx
                 gpxrolling=50,                     #set roling parameter, standard value is 10
                 linecolor="red",                   #color of elevation profile line
                 maxlinecol="green",                #color of the max line
                 transparency=.7,                   #set transparency
                 plotsave=T,                        #save plot in wd
                 plotname="Test",                   #Name of plot to save
                 ggsavepar=c(10,10,"cm",150)        #dimensions of plot to save, unit and dpi's
                 )
                  
```
<img src="https://github.com/EPdeJ/cyclingplots/blob/main/test.png" width="25%">

#### Future planning
- add support for gpx files without elevation values
- option to hide max height line
- make the facets of `gpxrolling` more smooth:
  - get rid of the white spaces that sometimes occur
  - make the facets straight (an 90 degree angle on the x axis)
  
  *Especially noticable for smaller rides and runs, see for example this strava export of a 14 km run:*
  <img src="https://github.com/EPdeJ/cyclingplots/blob/main/strava run.png">
- include in same function or other:
  - data summary
  - map (static)
- make shiny app from function with:
  - interactive map support


