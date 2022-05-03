#' NOTES FOR LATER DEVELOPMENT
#' 
#'make into a function in which the rolling average can be adjusted 
#'as well as filepath and dimentions

# load packages
pacman::p_load(tidyverse,sf,units,zoo,RColorBrewer,Cairo)


# convert gpx to sf -------------------------------------------------------
file_name <- "G:/.shortcut-targets-by-id/1kT69UY4d-Ny3cmezFuDPbeQRMwDT32dn/Fietsboek/pitch/Wutai (South)/COURSE_Wutai.gpx"  #file path
st_layers(file_name)                                        #add layers
gpx <- st_read(file_name,layer="track_points")              #import sf

#distance and time calculations
gpx<- gpx %>%
        mutate(
          elapsed_time = c(0,(lead(time) - time)[-1]),
          distance = c(0,st_distance(
            geometry, 
            lead(geometry), 
            by_element = TRUE)[-1]),
          elevation_diff=c(0,(lead(ele)-ele)[-1])
        )                                                   #calculate difference between succeding timestamps and distance 


gpx<- gpx %>% mutate(
            distance_total = cumsum(distance),
            elevation_total = cumsum(ele),
            gradient=(elevation_diff/distance)*100
          )                                                 #calculate cumsum of distance without the first row (as that should be 0)

gpx<- gpx %>% mutate(
  elapsed_time100 = rollmean(elapsed_time, 100, fill=NA),
  distance_total100 = rollmean(distance_total, 100, fill=NA),
  elevation_total100 = rollmean(elevation_total,100, fill=NA),
  elevation_diff100= rollmean(elevation_diff,100, fill=NA),
  distance100=rollmean(distance,100, fill=NA),
  )

gpx<- gpx %>% mutate(
  gradient100=(elevation_diff100/distance100)*100
) 

gpx$gradient100 <-  replace_na(gpx$gradient100, 0)

gpx<- gpx %>% mutate(
  gradient100bined=cut(gpx$gradient100,
                       breaks=c(-Inf,
                                0,
                                2.5,
                                5,
                                7.5,
                                10,
                                Inf),
                       label=c("downhill or flat","mild slope","moderate slope", "steep", "very steep","good luck"),
                       include.lowest=T,
                       ordered_result=T)
) 

#UNIT CONVERSION
north <- "#4752a3"
west <- "#ff9c6b"
east <- "#01a6ed"
south <-  "#ba364e"
greenlight <- "#95cfc7"
greemdark <- "#23b09d"
scale <- brewer.pal(n=11,"Spectral")
scale <- rev(scale[c(1,3,5,7,9,11)])



# plot --------------------------------------------------------------------
ggplot(data=gpx)+
  #"downhill or flat"
  geom_area(data=gpx %>% mutate(ele=case_when(gradient100bined!="downhill or flat" ~ 0,
                                              TRUE ~ ele)),
            aes(x=distance_total100/1000, 
                y=ele,
                position="stacked"),
            fill="lightgrey"
            )+
  
  #"mild slope"
  geom_area(data=gpx %>% mutate(ele=case_when(gradient100bined!="mild slope" ~ 0,
                                              TRUE ~ ele)),
            aes(x=distance_total100/1000, 
                y=ele,
                position="stacked"),
            fill=scale[2]
  )+
  
  #"moderate slope"
  geom_area(data=gpx %>% mutate(ele=case_when(gradient100bined!="moderate slope" ~ 0,
                                              TRUE ~ ele)),
            aes(x=distance_total100/1000, 
                y=ele,
                position="stacked"),
            fill=scale[3]
  )+
  
  #"steep"
  geom_area(data=gpx %>% mutate(ele=case_when(gradient100bined!="steep" ~ 0,
                                              TRUE ~ ele)),
            aes(x=distance_total100/1000, 
                y=ele,
                position="stacked"),
            fill=scale[4]
  )+
  
  # "very steep"
  geom_area(data=gpx %>% mutate(ele=case_when(gradient100bined!="very steep" ~ 0,
                                              TRUE ~ ele)),
            aes(x=distance_total100/1000, 
                y=ele,
                position="stacked"),
            fill=scale[5]
  )+
  
  #"good luck"
  geom_area(data=gpx %>% mutate(ele=case_when(gradient100bined!="good luck" ~ 0,
                                              TRUE ~ ele)),
            aes(x=distance_total100/1000, 
                y=ele,
                position="stacked"),
            fill=scale[6]
  )+
  geom_line(aes(x=distance_total100/1000,y=ele), colour= "#23b09d", size=1)+
  geom_hline(aes(yintercept=max(ele)),linetype = 'dashed', col = south)+
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
ggsave("wutai.png", width = 24, height = 10,units ="cm", dpi = 600,type = "cairo-png", bg = "transparent" )


