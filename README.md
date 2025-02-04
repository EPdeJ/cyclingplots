# Cycling plots

**This hobby project is still work in progress**

### Description

Here's how to make beautiful cycling height profiles. Like this one!
<img src="https://github.com/EPdeJ/cyclingplots/blob/main/N1-1_Wufenshan.png">

and this one:

<img src="https://github.com/EPdeJ/cyclingplots/blob/main/N1-2_Wufenshan Buyanting loop.png">

or make a nice map plotting the route in a leaflet map:

<img src="https://github.com/EPdeJ/cyclingplots/blob/main/N1-2_Wufenshan Buyanting loop_map.png">


### Usage in short:

* This repository contains two R code snippets containing functions to make:
    + An elevation profile based on any gpx file
    + A map displaying the route in a leaflet map (with JAWG-lagoon base layer)
* The sf package is used to uniformly import the gpx files.
* Rolling averages are calculated with the zoo package
* For now, elevation is needed as a variable in the gpx files, later support for gpx files without elevation will be added.
* Future plans involve a shiny app allowing you to upload a .gpx file and generate the two images.  
 
### Arguments elevation plot function
                                                   
- `filepath` need to be set to locate the gpx file, for example "C:/Users/user/Desktop/yilan-wulling.gpx"
- `seq` factor to reduce the number of datapoints in a GPX file (especially usefull for calculations of gradients over longer streches)(default=10)
- `roll` how many point shoulc be used in the calculation of rolling averages (default is 10)
- `rollparameter` use max or mean method for rolling averages (default is "max")
- `colorscalestr` will set the colors of the gradient levels. String length 6. First color is downhill or no gradient. (default"#9198A7","#C9E3B9", "#F9D49D", "#F7B175", "#F47D85", "#990000")
- `linecolor` set the color of the height profile
- `maxlinecol` sets the color of the maximum height line 
- `transparency` set the transparency of the area under the curve
- `elevationbreaksstr` sets the how the rolling gradient should be divided in different levels of difficulty
- `plotsave`, `plotsavedir` and `plotname` can be set to save the plot automatically with **plotsave** as logical. Plots will be saved in the working directory. If none is provided working dir and gpx file name will be used.
- `ggsave_width` set the width of the plot to save
- `ggsave_height` set the height of the plot to save
- `ggsave_dpi` set the dots per inch
- `ggsave_units` set the units uses for height and width (default to "cm")
- `ggsave_background` option to use "transparent"
                          
### Arguments map function 

* `gpxnr`
* `start` to set the label direction for start label, options like "left","right","top" , "bottom" (standard= "left")
* `finish` to set the label direction for finish label, options like "left","right","top" , "bottom" (standard= "left")
* `lijnkleur` sets the route line color (standard= "#640c82")
* `trans` sets the route line transparency (standard= 1, no transparancy)
* `labeldirection` sets the driection of the Km markings (top, bottom, left, right or auto)
* `jawgapi` set you personal api token, get one [at JAWG](https://www.jawg.io/lab/access-tokens) 

### Details
6 levels have been set as categories for the area under the curve colors, based on the following grade categories:
  + downhill or flat
  + gradient "<3%"
  + gradient "3-6%"
  + gradient "6-9%"
  + gradient "9-12%"
  + gradient ">12%"
  
Colors of these gradient levels can be adjusted with `colorscalestr` by providing a with sting 6 hex colors. (example: `c("#9198A7","#C9E3B9", "#F9D49D", "#F7B175", "#F47D85", "#990000")`)

For `gpxrolling`, smaller numbers will  make the plot more detailed (smaller facets), but note that the plotting will take longer. For example, if a gpx file only contains a climb of 2500 geometry points, and the rolling average will be set to 2500, then the gradient calculated will just be the gradient for the full climb, hence the plot will only contain one facet. 

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
<img src="https://github.com/EPdeJ/cyclingplots/blob/main/test.png" width="25%" height="auto">

#### Future planning
- add support for gpx files without elevation values
- option to hide max height line
- AUC shaded for gradients parameters such as roll and limiting the number of gpx datapoint make the graph now smoother. The innitial problem with the white spaces that sometimes occured and the non straight facets (not 90 degree angle on the x axis) have been patched but the solution is not ideal (setting the y coordinated to -1000000 for the kilometers not in the gradient group)
  
  *Especially noticable for smaller rides and runs, see for example this strava export of a 14 km run:*
  <img src="https://github.com/EPdeJ/cyclingplots/blob/main/strava run.png">
- include in same function or other:
  - data summary
  - map (static)
- make shiny app from function with:
  - interactive map support


