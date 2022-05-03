#' NOTES FOR LATER DEVELOPMENT
#' 
#'make into a function in which the rolling average can be adjusted 
#'as well as filepath and dimentions

# load packages
pacman::p_load(tidyverse,sf,units,zoo,RColorBrewer,Cairo)


# function elevation profile -------------------------------------------------------
elevationprofile <- function(filepath,
                             gpxrolling=10,
                             colorscalestr=c("#5E4FA2", "#66C2A5", "#E6F598", "#FEE08B", "#F46D43", "#9E0142"),
                             linecolor="#23b09d",
                             maxlinecol="red",
                             elevationbreaksstr=c(-Inf, 0, 2.5, 5, 7.5, 10, Inf), 
                             plotsave=T,
                             plotname="empty",
                             plotsavedimentiondpisstr=c(24,10,"cm",300)){
                      
                    
#_________________________import gpx_____________________________________________________________
gpx <- st_read(filepath,layer="track_points")              #import gpx into sf object

#_______________________gpx calculations start___________________________________________________
#gpx culculations
gpx<- gpx %>%
        mutate(
          elapsed_time = c(0,(lead(time) - time)[-1]),
          elevation_diff=c(0,(lead(ele)-ele)[-1]),
          distance = c(0,st_distance(
            geometry, 
            lead(geometry), 
            by_element = TRUE)[-1]
            )
        )                                                   #calculate time and elevation difference per point and distance between points


#gpx culculations
gpx<- gpx %>% mutate(
            distance_total = cumsum(distance),
            elevation_total = cumsum(ele),
            gradient=(elevation_diff/distance)*100
          )                                                 #calculate cumsum of distance and elevation and gradient per gpx point

#gpx culculations
gpx<- gpx %>% mutate(
  elapsed_timeN = rollmean(elapsed_time, gpxrolling, fill=NA),
  distance_totalN = rollmean(distance_total, gpxrolling, fill=NA),
  elevation_totalN = rollmean(elevation_total,gpxrolling, fill=NA),
  elevation_diffN= rollmean(elevation_diff,gpxrolling, fill=NA),
  distanceN=rollmean(distance,gpxrolling, fill=NA),
  )                                                         #calculate rolling averages based on gpxrolling set in function 

#gpx culculations
gpx<- gpx %>% mutate(
  gradientN=(elevation_diffN/distanceN)*100
)                                                           #calculate rolling gradient

#gpx culculations
gpx$gradientN <-  replace_na(gpx$gradientN, 0)              #set 0 instead of NA for first points

#gpx culculations
gpx<- gpx %>% mutate(
  gradientNbined=cut(gpx$gradientN,
                       breaks=elevationbreaksstr,
                       label=c("downhill or flat","mild slope","moderate slope", "steep", "very steep","good luck"),
                       include.lowest=T,
                       ordered_result=T)
)                                                           #turn rolling gradient into factors/steps/bins


head(gpx)

# plot --------------------------------------------------------------------
plot <- ggplot(data=gpx)+
  #"downhill or flat"
  geom_area(data=gpx %>% mutate(ele=case_when(gradientNbined!="downhill or flat" ~ 0,
                                              TRUE ~ ele)),
            aes(x=distance_totalN/1000, 
                y=ele,
                position="stacked"),
            fill=colorscalestr[1]
            )+
  
  #"mild slope"
  geom_area(data=gpx %>% mutate(ele=case_when(gradientNbined!="mild slope" ~ 0,
                                              TRUE ~ ele)),
            aes(x=distance_totalN/1000, 
                y=ele,
                position="stacked"),
            fill=colorscalestr[2]
  )+
  
  #"moderate slope"
  geom_area(data=gpx %>% mutate(ele=case_when(gradientNbined!="moderate slope" ~ 0,
                                              TRUE ~ ele)),
            aes(x=distance_totalN/1000, 
                y=ele,
                position="stacked"),
            fill=colorscalestr[3]
  )+
  
  #"steep"
  geom_area(data=gpx %>% mutate(ele=case_when(gradientNbined!="steep" ~ 0,
                                              TRUE ~ ele)),
            aes(x=distance_totalN/1000, 
                y=ele,
                position="stacked"),
            fill=colorscalestr[4]
  )+
  
  # "very steep"
  geom_area(data=gpx %>% mutate(ele=case_when(gradientNbined!="very steep" ~ 0,
                                              TRUE ~ ele)),
            aes(x=distance_totalN/1000, 
                y=ele,
                position="stacked"),
            fill=colorscalestr[5]
  )+
  
  #"good luck"
  geom_area(data=gpx %>% mutate(ele=case_when(gradientNbined!="good luck" ~ 0,
                                              TRUE ~ ele)),
            aes(x=distance_totalN/1000, 
                y=ele,
                position="stacked"),
            fill=colorscalestr[6]
  )+
  geom_line(aes(x=distance_totalN/1000,y=ele), colour= linecolor, size=1)+
  geom_hline(aes(yintercept=max(ele)),linetype = 'dashed', col = maxlinecol)+
  xlab("Distance (km)")+
  ylab("Elevation (m)")+
  scale_y_continuous(position = "right", limits = c(0,3500),expand = c(0,0))+
  theme(panel.grid.minor = element_blank(), 
        panel.grid.major = element_blank(),
        # axis.ticks= element_blank(),
        panel.background = element_rect(fill = "transparent",color = NA), 
        plot.background = element_rect(fill = "transparent", color = NA),
        axis.text.x = element_text(vjust = .5, margin = margin(-0.5,0,0.5,0, unit = 'cm')),
        axis.ticks.length=unit(-0.25, "cm"),
        axis.title.x = element_text(vjust = -2, margin = margin(-0.5,0,0.5,0, unit = 'cm'))
         
  )
print(plot)

if(plotsave){ggsave(plot= plot,
                    paste0(plotname,".png"),
                    width = plotsavedimentiondpisstr[1],
                    height = plotsavedimentiondpisstr[2],
                    units =plotsavedimentiondpisstr[3],
                    dpi = plotsavedimentiondpisstr[4],
                    type = "cairo-png",
                    bg = "transparent" )}


}




# use function ------------------------------------------------------------

setwd(gsub("\\\\","/",r"(C:\Users\user\Desktop)"))
dir.create("plots")
setwd("plots")
getwd()

filepath <- "yilan-wulling.gpx"

elevationprofile(filepath, plotsave = F)
