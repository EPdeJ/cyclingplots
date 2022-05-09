# see https://github.com/EPdeJ/cyclingplots#readme for more information


# load packages
pacman::p_load(tidyverse,sf,zoo,Cairo)


# function elevation profile -------------------------------------------------------
elevationprofile <- function(filepath,
                             gpxrolling=10,
                             coleasy="#9198A7",
                             colorscalestr=c("#5E4FA2", "#66C2A5", "#E6F598", "#FEE08B", "#F46D43", "#9E0142"),
                             linecolor="#23b09d",
                             maxlinecol="red",
                             transparency=1,
                             elevationbreaksstr=c(-Inf, 0, 2.5, 5, 7.5, 10, Inf), 
                             plotsave=F,
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


print(slice_sample(gpx, n=10))                              #get a sample of the gpx data to check


plot <- ggplot(data=gpx)+
  
  #plot "downhill or flat" area under the curve
  geom_area(data=gpx %>% mutate(ele=case_when(gradientNbined!="downhill or flat" ~ 0,
                                              TRUE ~ ele)),
            aes(x=distance_totalN/1000, 
                y=ele),
            fill=coleasy,
            alpha=transparency
            )+
  
  #plot "mild slope" area under the curve
  geom_area(data=gpx %>% mutate(ele=case_when(gradientNbined!="mild slope" ~ 0,
                                              TRUE ~ ele)),
            aes(x=distance_totalN/1000, 
                y=ele),
            fill=colorscalestr[2],
            alpha=transparency
  )+
  
  #plot "moderate slope" area under the curve
  geom_area(data=gpx %>% mutate(ele=case_when(gradientNbined!="moderate slope" ~ 0,
                                              TRUE ~ ele)),
            aes(x=distance_totalN/1000, 
                y=ele),
            fill=colorscalestr[3],
            alpha=transparency
  )+
  
  #plot "steep" area under the curve
  geom_area(data=gpx %>% mutate(ele=case_when(gradientNbined!="steep" ~ 0,
                                              TRUE ~ ele)),
            aes(x=distance_totalN/1000, 
                y=ele),
            fill=colorscalestr[4],
            alpha=transparency
  )+
  
  #plot "very steep" area under the curve
  geom_area(data=gpx %>% mutate(ele=case_when(gradientNbined!="very steep" ~ 0,
                                              TRUE ~ ele)),
            aes(x=distance_totalN/1000, 
                y=ele),
            fill=colorscalestr[5],
            alpha=transparency
  )+
  
  #plot "good luck" area under the curve
  geom_area(data=gpx %>% mutate(ele=case_when(gradientNbined!="good luck" ~ 0,
                                              TRUE ~ ele)),
            aes(x=distance_totalN/1000, 
                y=ele),
            fill=colorscalestr[6],
            alpha=transparency
  )+
  
  #add height profile line
  geom_line(aes(x=distance_totalN/1000,y=ele), colour= linecolor, size=1)+
  
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
                    width = as.numeric(plotsavedimentiondpisstr[1]),
                    height = as.numeric(plotsavedimentiondpisstr[2]),
                    units =plotsavedimentiondpisstr[3],
                    dpi = as.numeric(plotsavedimentiondpisstr[4]),
                    type = "cairo-png",
                    bg = "transparent" ))}


}




# use function ------------------------------------------------------------
elevationprofile("gpx/crazy ride.gpx",plotname = "test", gpxrolling = 100, plotsave = T)
