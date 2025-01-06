# see https://github.com/EPdeJ/cyclingplots#readme for more information

# we're going to use Jawg.Lagoon as base layer for maps in leaflet
#' idea for smoothing less data points but without loosing the highest elevation point
#' idea for one peak (not sure if its a problem if we lose the max of smaller peaks):
#' devide the gpx file in 5 parts, in the following order
#' --> 1 row of the start elevation
#' --> rows with elevations leading up to the peak, number of datapoints can be made smaller
#' --> 1 peak row
#' --> rows with elevations leading up to the finnish, number of datapoints can be made smaller
#' --> finnish elevation
#' rowbind after
#' 
#' or use rollmax instead
#' 
#' question: smoothning can not be done by distance as it's irregularly distributed by km
#' 
#' write a function for rolling avg



# load packages and filepaths ---------------------------------------------
pacman::p_load(tidyverse,sf,zoo,Cairo)
S.path <- "G:/.shortcut-targets-by-id/1kT69UY4d-Ny3cmezFuDPbeQRMwDT32dn/Fietsboek/2025/gpx"
S.gpxlist <- list.files(path = S.path, pattern = "\\.gpx$", full.names = T)
gpx <- st_read(S.gpxlist[1],layer="track_points") 

#!!!!!!!!!!!!temp vars for development (remove in final version)!!!!!!!!!!!!!!!!!
seq=10
roll=10

transparency=1
colorscalestr=c("#9198A7","#C9E3B9", "#F9D49D", "#F7B175", "#F47D85", "#990000")
rollparameter="max"
linecolor="#23b09d"
maxlinecol="red"

#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

# function elevation profile -------------------------------------------------------
# set start parameters for function
elevationprofile <- function(filepath,
                             roll=10,
                             rollparameter="max",
                            
                             colorscalestr=c("#9198A7","#C9E3B9", "#F9D49D", "#F7B175", "#F47D85", "#990000"),
                             linecolor="#23b09d",
                             maxlinecol="red",
                             transparency=1,
                              
                             plotsave=F,
                             plotname="empty",
                             ggsavepar=c(24,10,"cm",300),
                             seq=F){
                      
                    
# import gpx into sf object to add geometry
gpx <- st_read(filepath,layer="track_points") #turn into sf object
gpx <- gpx %>% select(track_seg_point_id, ele,geometry) #select the usefull rows

# WORK IN PROGRESS (if seq is defined it will reduce the number of datapoints from the gpx)
if(seq){gpx <- gpx %>% slice(c(1, seq(seq, nrow(gpx)-1, seq), nrow(gpx)))}


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
    gradient=(elevation_diff/distance_diff)*100
        ) # elevation can be negative so only cum sum when positive 

# calculate rolling averages
gpx<- gpx %>% 
  mutate(
    distance_roll_mean = rollmean(distance_total, roll, fill=0),
    distance_roll_max = rollmax(distance_total, roll, fill=0),
    distance_diff_roll_mean=rollmean(distance_diff,roll, fill=0),
    distance_diff_roll_max=rollmax(distance_diff,roll, fill=0),
    elevation_roll_mean = rollmean(elevation_total,roll, fill=0),
    elevation_roll_max= rollmax(elevation_total,roll, fill=0),
    elevation_diff_roll_mean= rollmean(elevation_diff,roll, fill=0),
    elevation_diff_roll_max= rollmax(elevation_diff,roll, fill=0)
    ) #calculate rolling averages based on window named roll as set in function 

# calculate rolling gradient
gpx<- gpx %>% 
  mutate(
    gradient_roll_mean=(elevation_diff_roll_mean/distance_diff_roll_mean)*100,
    gradient_roll_max=(elevation_diff_roll_max/distance_diff_roll_max)*100
    ) %>% 
  mutate(
    gradient_roll_mean=replace_na(gradient_roll_mean, 0),
    gradient_roll_max=replace_na(gradient_roll_max, 0)
    )

# turn rolling gradients into factors/steps/bins based on Garmin percentages
gpx<- gpx %>% 
  mutate(
    gradient_roll_mean_binned=cut(gpx$gradient_roll_mean,
                                  breaks=c(-Inf,0.05, 3, 6, 9, 12, Inf),
                                  label=c("downhill or flat","<3%","3-6%", "6-9%", "9-12%",">12%"),
                                  include.lowest=T,
                                  ordered_result=T),
    gradient_roll_max_binned=cut(gpx$gradient_roll_max,
                                  breaks=c(-Inf,0.05, 3, 6, 9, 12, Inf),
                                  label=c("downhill or flat","<3%","3-6%", "6-9%", "9-12%",">12%"),
                                  include.lowest=T,
                                  ordered_result=T)
    ) %>% 
  mutate(gradient_max_fill = as.factor(case_when(gradient_roll_max_binned == "downhill or flat" ~ colorscalestr[1],
                                       gradient_roll_max_binned == "<3%" ~ colorscalestr[2],
                                       gradient_roll_max_binned == "3-6%" ~ colorscalestr[3],
                                       gradient_roll_max_binned == "6-9%" ~ colorscalestr[4],
                                       gradient_roll_max_binned == "9-12%" ~ colorscalestr[5],
                                       gradient_roll_max_binned == ">12%" ~ colorscalestr[6],
                                       TRUE ~ "red"))) 
gpx <- gpx %>% 
  mutate(ele_three=case_when(gradient_roll_max_binned == "<3%" ~ ele,
                             TRUE ~ -2000),
         dist_three=case_when(gradient_roll_max_binned == "<3%" ~ distance_total,
                             TRUE ~ distance_total))
  
gpx <- gpx %>% st_drop_geometry()
mem <- gpx

# find maximum elevation (highest point) and max distance
maxele <- max(gpx$ele)
maxdist <- max(gpx$distance_total)


# make the plot
ggplot(data=gpx)+
  #plot "downhill or flat" area under the curve, which serves as the background
  geom_ribbon(aes(x=distance_total/1000,ymax=ele,ymin=0),
              fill=colorscalestr[1],
              alpha=transparency
            )+
  
  #plot <3% area under the curve
  geom_ribbon(aes(x=distance_total/1000, 
                  ymax={ 
                    if (rollparameter == "max") { # Use gradient_roll_max_binned to evaluate gradient group
                      ifelse(gradient_roll_max_binned == "<3%", ele, -1000000)
                    } else if (rollparameter == "mean") { # Use gradient_roll_mean_binned to evaluate gradient group
                      ifelse(gradient_roll_mean_binned == "<3%", ele, -1000000)
                    } else { NA_real_ 
                      warning("Invalid rollparameter specified. Select either \"max\" or \"mean\"") #Give a warning to the user
                    }
                  },
                  ymin=0),
              fill=colorscalestr[2],
              alpha=transparency
              )+

  #plot 3-6% area under the curve
  geom_ribbon(aes(x=distance_total/1000, 
                  ymax={ 
                    if (rollparameter == "max") { # Use gradient_roll_max_binned to evaluate gradient group
                      ifelse(gradient_roll_max_binned == "3-6%", ele, -1000000)
                    } else if (rollparameter == "mean") { # Use gradient_roll_mean_binned to evaluate gradient group
                      ifelse(gradient_roll_mean_binned == "3-6%", ele, -1000000)
                    } 
                  },
                  ymin=0),
              fill=colorscalestr[3],
              alpha=transparency
              )+
  
  #plot 6-9% area under the curve
  geom_ribbon(aes(x=distance_total/1000, 
                  ymax={ 
                    if (rollparameter == "max") { # Use gradient_roll_max_binned to evaluate gradient group
                      ifelse(gradient_roll_max_binned == "6-9%", ele, -1000000)
                    } else if (rollparameter == "mean") { # Use gradient_roll_mean_binned to evaluate gradient group
                      ifelse(gradient_roll_mean_binned == "6-9%", ele, -1000000)
                    } 
                  },
                  ymin=0),
              fill=colorscalestr[4],
              alpha=transparency
              )+
  
  #plot 9-12% area under the curve
  geom_ribbon(aes(x=distance_total/1000, 
                  ymax={ 
                    if (rollparameter == "max") { # Use gradient_roll_max_binned to evaluate gradient group
                      ifelse(gradient_roll_max_binned == "9-12%", ele, -1000000)
                    } else if (rollparameter == "mean") { # Use gradient_roll_mean_binned to evaluate gradient group
                      ifelse(gradient_roll_mean_binned == "9-12%", ele, -1000000)
                    } 
                  },
                  ymin=0),
              fill=colorscalestr[5],
              alpha=transparency
              )+

  #plot "good luck" >12% area under the curve
  geom_ribbon(aes(x=distance_total/1000, 
                  ymax={ 
                    if (rollparameter == "max") { # Use gradient_roll_max_binned to evaluate gradient group
                      ifelse(gradient_roll_max_binned == ">12%", ele, -1000000)
                    } else if (rollparameter == "mean") { # Use gradient_roll_mean_binned to evaluate gradient group
                      ifelse(gradient_roll_mean_binned == ">12%", ele, -1000000)
                    } 
                  },
                  ymin=0),
              fill=colorscalestr[6],
              alpha=transparency
              )+
  
  #' set y-axis limits for plot as they become wildly negative automatically due to 
  #' the set -1000000 for the shades for the gradients. This was needed because a 
  #' point with an elevation connecting to 0 would create a sloped line instead of a 
  #' vertical line. This still needs to be solved but the -1000000 patch is visually working
  scale_y_continuous(limits = c(0,maxele))+

  #add height profile line
  geom_line(aes(x=distance_total/1000,y=ele), colour= linecolor, size=1, lineend="round")
  
  #add start and end point
  geom_point(data=. %>% slice(c(1, n())),
             aes(
               x=distance_total/1000,
               y=ele),
             size = 4, # Adjust size as needed
             shape = 21, # Shape 21 is a circle with a fill and stroke
             fill = "red", # Fill color
             color = linecolor, # Stroke color
             stroke = 1, # Stroke thickness
             alpha = 0.5) # Transparency

  
  #add max height line
  geom_hline(aes(yintercept=max(ele)),linetype = 'dashed', col = maxlinecol)+
  
  #change labels x and y axis
  xlab("Distance (km)")+
  ylab("Elevation (m)")+
  
  #modify the ticks and place of y axis
  scale_y_continuous(position = "right", limits = c(0,3500), expand = c(0,0))+
  
  #further add changes to layout
  theme(panel.grid.minor = element_blank(), 
        panel.grid.major = element_blank(),
        # axis.ticks= element_blank(),
        panel.background = element_rect(fill = "transparent",color = NA), 
        plot.background = element_rect(fill = "transparent", color = NA),
        axis.text.x = element_text(vjust = .5, margin = margin(-0.5,0,0.5,0, unit = 'cm')),
        axis.ticks.length=unit(-0.25, "cm"),
        axis.title.x = element_text(vjust = -2, margin = margin(-0.5,0,0.5,0, unit = 'cm'))
         
  )

suppressWarnings(print(plot))

if(plotsave){suppressMessages(ggsave(plot= plot,
                    paste0(plotname,".png"),
                    width = as.numeric(ggsavepar[1]),
                    height = as.numeric(ggsavepar[2]),
                    units =ggsavepar[3],
                    dpi = as.numeric(ggsavepar[4]),
                    type = "cairo-png",
                    bg = "transparent" ))}

plot
}



# use function ------------------------------------------------------------
elevationprofile(S.gpxlist[1],plotname = "Wufenshan test", gpxrolling = 200, plotsave = F , seq=F)

 elevationprofile("gpx/crazy ride.gpx",                            #set filepath including .gpx
                 gpxrolling=50,                                   #set roling parameter, standard value is 10
                 linecolor="red",                                 #color of elevation profile line
                 maxlinecol="green",                              #color of the max line
                 transparency=.7,                                 #set transparency
                 plotsave=T,                                      #save plot in wd
                 plotname="Test",                                 #Name of plot to save
                 ggsavepar=c(10,10,"cm",150)       #dementions of plot to save, unit and dpi's
)
