# load packages
pacman::p_load(trackeR,tidyverse,sf,elevatr,raster,units,zoo)


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


# plot --------------------------------------------------------------------
ggplot(data=gpx)+
  geom_line(aes(x=distance_total100/1000,y=ele),colour=south, size=1)+
  geom_area(data=gpx %>% mutate(ele=case_when(gradient100bined!="downhill or flat" ~ 0,
                                              TRUE ~ ele)),
            aes(x=distance_total100/1000, 
                y=ele,
                position="stacked"),
            fill="green"
            )+
  geom_hline(aes(yintercept=max(ele)),linetype = 'dashed', col = south)+
  xlab("Distance (km)")+
  ylab("Elevation (m)")+
  scale_y_continuous(position = "right", limits = c(0,3500))+
  theme(panel.grid.minor = element_blank(), 
        panel.grid.major = element_blank(),
        # axis.ticks= element_blank(),
        panel.background = element_rect(fill = "transparent",color = NA), 
        plot.background = element_rect(fill = "transparent", color = NA)
  )


ggplot(data=gpx)+
  geom_line(aes(x=distance_total100, y=gradient100, color="red"))
?rollmean
test <- 
