# see https://github.com/EPdeJ/cyclingplots#readme for more information
# currently Jawg.Lagoon as base layer for maps in leaflet

# load packages and filepaths ---------------------------------------------
  if(!require("pacman")){install.packages("pacman")}
  pacman::p_load(tidyverse,sf,zoo,Cairo, scales,showtext)

# load noto sans font for consitancy 
  font_add_google(name = "Noto Sans", family = "Noto Sans")  # Downloads and registers it
  showtext_auto()

# function elevation profile -------------------------------------------------------
  elevationprofile <- function(filepath, # file path to single .gpx file
                               seg=1000, # set distance for gradient calculation (1000 = 1 km)
                               fixed_breaks=NULL, # set distance for x-axis label override
                               colorscalestr=c("#9198A7","#C9E3B9", "#F9D49D", "#F7B175", "#F47D85", "#990000"),
                               linecolor="#22678A", # colour of profile line
                               maxlinecol="red", # colour of max height line
                               transparency=1, # transparency of the AUC gradient colours
                               plotsave=F, # safe the plot 
                               plotsavedir=NULL, # directory to save the plot
                               plotname="", # name for saved plot
                               ggsave_width=24, # saved plot dimensions (width)
                               ggsave_height=10,  # saved plot dimensions (height)
                               ggsave_dpi=300,  # saved plot dimensions (dpi)
                               ggsave_units="cm",  # saved plot dimensions (unit)
                               ggsave_background="transparent", # saved plot background colour
                               mingraddist=5, # set gps jitter correction in meters 
                               textsize=60 # set text size of plot
                               ){
                        
                      
  # import gpx into sf object to add geometry
    gpx <- st_read(filepath,layer="track_points") # turn into sf object
    gpx <- gpx %>% select(track_seg_point_id, ele,geometry) # select the useful rows
  
  # calculate the difference in distance and elevation between data points
    gpx<- gpx %>%
      mutate(
        elevation_diff=c(0,lag((lead(ele)-ele))[-1]),
        distance_diff = c(0,lag(st_distance(geometry,lead(geometry),by_element = TRUE))[-1])
            )                                     
  
  # calculate the cumsum of the distance and elevation per point
    gpx<- gpx %>% 
      mutate(
        distance_total = cumsum(distance_diff),
        elevation_total = cumsum(ifelse(elevation_diff > 0, elevation_diff, 0)),
        gradient = ifelse(distance_diff < mingraddist, 
                          NA, 
                          (elevation_diff / distance_diff) * 100) # remove gpx jitter gradient 
        ) 
      
  #' Calculate floor 100m
  #' Create a segment ID for every "seg" meters, floor(distance_total / seg) 
  #' will give integer bins (e.g. 0-999.9 m = 0, 1000-1999.9m = 1, etc.)
      gpx<- gpx %>% 
        mutate(
          segment = floor(distance_total / seg) * seg) %>%
        group_by(segment) %>%
        mutate(
          gradientsegement= mean(gradient, # also removes introduced NA's from gradient calc
                                 na.rm = TRUE)) %>% 
          
        ungroup() 
  
  # turn rolling gradients into factors/steps/bins based on Garmin percentages
    gpx<- gpx %>% 
      mutate(
        avggradient=cut(gradientsegement,
                                      breaks=c(-Inf,0.05, 3, 6, 9, 12, Inf),
                                      label=c("downhill or flat","<3%","3-6%", "6-9%", "9-12%",">12%"),
                                      include.lowest=T,
                                      ordered_result=T),
        ) 
    gpx <- gpx %>% st_drop_geometry() # sf geometry not longer needed 
    mem_gpx <<- gpx # safe a copy of the gpx calcs in the environment
  
  # find maximum elevation (highest point) & max distance
    maxele <- max(gpx$ele)
    maxeledist <- gpx %>% filter(ele==maxele) %>% select(distance_total) %>% pull/1000
    maxdist <- max(gpx$distance_total)
    minele <- min(gpx$ele)
    
  # introduce logic parameters to set x-axis breaks based on total distance in meters
    if (!is.null(fixed_breaks)) {
      breaks <- fixed_breaks # Override with the provided value
    } else {
      if (maxdist > 30000 & maxdist <= 100000 ) {
        breaks <- 10
      } else if (maxdist > 100000 & maxdist <= 150000 ) {
        breaks <- 25
      } else if (maxdist > 150000 & maxdist <= 250000 ) {
        breaks <- 50
      } else if (maxdist <= 30000) {
        breaks <- 5
      } else {
        breaks <- 100
      }
    }
  
  # calculate the position for three lines in between the max line and the x axis (y=0)
    rib0ele <- min(gpx$ele)
    rib0dist <- gpx %>%  mutate(difference = abs(ele - rib0ele)) %>%  
      slice_min(difference) %>% select(distance_total) %>% pull/1000
    rib1ele <- rib0ele+((maxele-rib0ele)/4)
    rib1dist <- gpx %>%  filter(abs(ele - rib1ele) < 1) %>%  slice(1) %>%  pull(distance_total) / 1000
    rib2ele <- rib0ele+(((maxele-rib0ele)/4)*2)
    rib2dist <- gpx %>%  filter(abs(ele - rib2ele) < 1) %>%  slice(1) %>%  pull(distance_total) / 1000
    rib3ele <- rib0ele+(((maxele-rib0ele)/4)*3)
    rib3dist <- gpx %>%  filter(abs(ele - rib3ele) < 1) %>%  slice(1) %>%  pull(distance_total) / 1000
  
  
  # make the plot
    plot <- ggplot(data=gpx)+
      
      # add max height line
        annotate("segment",
                 x=maxeledist,
                 xend=maxdist/1000,
                 y=maxele,
                 yend=maxele,
                 colour=maxlinecol,
                 linetype = 'dashed',
                 linewidth= .5)+
      
      # add 3 even lines inbetween max line and lowest elevation
        annotate("segment",
                 x=rib1dist,
                 xend=maxdist/1000,
                 y=rib1ele,
                 yend=rib1ele,
                 colour="lightgrey",
                 linewidth= .5)+
        annotate("segment",
                 x=rib2dist,
                 xend=maxdist/1000,
                 y=rib2ele,
                 yend=rib2ele,
                 colour="lightgrey",
                 linewidth= .5)+
        annotate("segment",
                 x=rib3dist,
                 xend=maxdist/1000,
                 y=rib3ele,
                 yend=rib3ele,
                 colour="lightgrey",
                 linewidth= .5)+ 
      
      
      # plot "downhill or flat" area under the curve, which serves as the background
        geom_ribbon(aes(x=distance_total/1000,ymax=ele,ymin=minele),
                    fill=colorscalestr[1],
                    alpha=transparency)+
      
      # plot <3% area under the curve
        geom_ribbon(aes(x=distance_total/1000, 
                        ymax={ifelse(avggradient == "<3%", ele, -1000000)},
                        ymin=minele),
                    fill=colorscalestr[2],
                    alpha=transparency)+
    
      # plot 3-6% area under the curve
        geom_ribbon(aes(x=distance_total/1000, 
                        ymax={ifelse(avggradient == "3-6%", ele, -1000000)},
                        ymin=minele),
                    fill=colorscalestr[3],
                    alpha=transparency)+
      
      # plot 6-9% area under the curve
        geom_ribbon(aes(x=distance_total/1000, 
                        ymax={ifelse(avggradient == "6-9%", ele, -1000000)},
                        ymin=minele),
                    fill=colorscalestr[4],
                    alpha=transparency)+
      
      # plot 9-12% area under the curve
        geom_ribbon(aes(x=distance_total/1000, 
                        ymax={ifelse(avggradient == "9-12%", ele, -1000000)},
                        ymin=minele),
                    fill=colorscalestr[5],
                    alpha=transparency)+
    
      # plot "good luck" >12% area under the curve
        geom_ribbon(aes(x=distance_total/1000, 
                        ymax={ifelse(avggradient == ">12%", ele, -1000000)},
                        ymin=minele),
                    fill=colorscalestr[6],
                    alpha=transparency)+
      
      
      #' set y-axis limits for plot as they become wildly negative automatically due to 
      #' the set -1000000 for the shades for the gradients. This was needed because a 
      #' point with an elevation connecting to 0 would create a sloped line instead of a 
      #' vertical line. This still needs to be solved but the -1000000 patch is visually working
      
      # set scale parameters
        scale_y_continuous(limits = c(minele,maxele+100),  position = "right",
                           breaks = c(rib1ele,rib2ele,rib3ele,maxele),
                           labels = c( 
                                      paste0(round(rib1ele,0), " m"), 
                                      paste0(round(rib2ele,0), " m"),
                                      paste0(round(rib3ele,0), " m"),
                                      paste0(round(maxele,0), " m")),
                           expand = c(0,1)
                           )+ 
        scale_x_continuous(
          breaks = c(seq(breaks, maxdist/1000, by = breaks)), 
          labels = paste0(c(seq(breaks, maxdist/1000, by = breaks)), " km"), 
          minor_breaks = NULL,
          expand = c(0,1.5)
        ) +
      
      # add height profile line on top
        geom_line(aes(x=distance_total/1000,y=ele), colour= linecolor, linewidth=1, lineend="round")+
      
      #add start and end point on top
        geom_point(data=. %>% slice(c(1, n())),
                   aes(
                     x=distance_total/1000,
                     y=ele),
                   size = 4, # Adjust size as needed
                   shape = 21, # Shape 21 is a circle with a fill and stroke
                   fill = "transparent", # Fill color
                   color = linecolor, # Stroke color
                   stroke = 1, # Stroke thickness
                   alpha = 1)+ # Transparency
      
      # change labels x and y axis
        xlab("Distance (km)")+
        ylab("Elevation (m)")+
      
      # further changes to layout
        theme(panel.grid.minor = element_blank(), 
              panel.grid.major = element_blank(),
              panel.background = element_rect(fill = "transparent",color = NA), 
              plot.background = element_rect(fill = "transparent", color = NA),
              axis.text.x = element_text(size=textsize, vjust = .5, margin = margin(t = 3)),
              axis.text.y = element_text(size = textsize),
              axis.ticks.length.x = unit(-0.15, "cm"),
              axis.ticks.x = element_line(color = linecolor, linewidth=3,lineend = "round"),
              axis.ticks.y = element_blank(),
              axis.title = element_blank(),
              text = element_text(family = "Noto Sans")
              )
           
  # save plot is specified in function
    if(plotsave){ ggsave(plot= plot,
                         path = plotsavedir,
                         filename = paste0(ifelse(plotname!="", 
                                                  paste(plotname),
                                                  sub("\\.gpx$", 
                                                      "", 
                                                      basename(filepath))),
                                           ".png"),
                         width = as.numeric(ggsave_width),
                         height = as.numeric(ggsave_height),
                         units =ggsave_units,
                         dpi = as.numeric(ggsave_dpi),
                         type = "cairo-png",
                         bg = ggsave_background )
    }
  
  # display plot 
    plot
    
  # >>>>>>>>>FUNCTION END<<<<<<<<<<<<
  }



