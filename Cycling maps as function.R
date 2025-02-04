# see https://github.com/EPdeJ/cyclingplots#readme for more information
# currently Jawg.Lagoon as base layer for maps in leaflet


roll=7
colorscalestr=c("#9198A7","#C9E3B9", "#F9D49D", "#F7B175", "#F47D85", "#990000")
gpxnr <- 2
remotes::install_github("r-spatial/mapview")



# load packages and filepaths ---------------------------------------------
pacman::p_load(tidyverse,sf,ggmap,zoo,rosm,colorspace,ggspatial,tmap,maptiles,leaflet,leaflet.extras2,utils,htmltools,mapview,webshot2)

S.path <- "G:/.shortcut-targets-by-id/1kT69UY4d-Ny3cmezFuDPbeQRMwDT32dn/Fietsboek/2025/gpx/north"
S.gpxlist <- list.files(path = S.path, pattern = "\\.gpx$", full.names = T)

# temp
gpxnr=2
lijnkleur="red"
jawgapi="ScYlimn0DmddEELnlYRgDZ9jWsWLj0VXUQcXKDxQ1d9Cjc1sKDb8FG4h2DZ6FJk2"
trans=.9
labeldirection="auto"
finish="right"
start="left"

makemap <- function(gpxnr, start="left", finish="right", lijnkleur="#640c82", trans=1,labeldirection,jawgapi=""){
# get track layer from gpx
track <- st_read(S.gpxlist[gpxnr], layer = "tracks")

# get points from gpx
gps <- st_read(S.gpxlist[gpxnr], layer = "track_points") %>% 
  mutate(dist_to_lead_m=c(0,lag(st_distance(geometry,lead(geometry),by_element = TRUE))[-1])) %>% 
  select(track_seg_point_id, ele,geometry,dist_to_lead_m) #select the usefull rows

# calculate the difference in distance and elevation between data points
gps<- gps %>%
  mutate(
    elevation_diff=c(0,lag((lead(ele)-ele))[-1]),
    distance_diff = c(0,lag(st_distance(geometry,lead(geometry),by_element = TRUE))[-1])
  ) 

#create lon and lat variables
gps <- gps %>% st_coordinates() %>% as.data.frame() %>% 
  rename(lon=X,lat=Y) %>% bind_cols(gps) %>% st_as_sf()

# Create distance and gradient vars
gps<- gps %>% 
  mutate(
    distance_total = cumsum(distance_diff),
    elevation_total = cumsum(ifelse(elevation_diff > 0, elevation_diff, 0)),
    gradient=(elevation_diff/distance_diff)*100
  ) # elevation can be negative so only cum sum when positive 


# calculate rolling averages
gps<- gps %>% 
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
gps<- gps %>% 
  mutate(
    gradient_roll_mean=(elevation_diff_roll_mean/distance_diff_roll_mean)*100,
    gradient_roll_max=(elevation_diff_roll_max/distance_diff_roll_max)*100
  ) %>% 
  mutate(
    gradient_roll_mean=replace_na(gradient_roll_mean, 0),
    gradient_roll_max=replace_na(gradient_roll_max, 0)
  )

# turn rolling gradients into factors/steps/bins based on Garmin percentages
gps<- gps %>% 
  mutate(
    gradient_roll_mean_binned=cut(gps$gradient_roll_mean,
                                  breaks=c(-Inf,0.05, 3, 6, 9, 12, Inf),
                                  label=c("downhill or flat","<3%","3-6%", "6-9%", "9-12%",">12%"),
                                  include.lowest=T,
                                  ordered_result=T),
    gradient_roll_max_binned=cut(gps$gradient_roll_max,
                                 breaks=c(-Inf,0.05, 3, 6, 9, 12, Inf),
                                 label=c("downhill or flat","<3%","3-6%", "6-9%", "9-12%",">12%"),
                                 include.lowest=T,
                                 ordered_result=T)
  ) %>% 
  mutate(gradient_colour = case_when(gradient_roll_mean_binned == "downhill or flat" ~ colorscalestr[1],
                                     gradient_roll_mean_binned == "3%" ~ colorscalestr[2],
                                     gradient_roll_mean_binned == "3-6%" ~ colorscalestr[3],
                                     gradient_roll_mean_binned == "6-9" ~ colorscalestr[4],
                                     gradient_roll_mean_binned == "9-12" ~ colorscalestr[5],
                                     gradient_roll_mean_binned == ">12%" ~ colorscalestr[6],
                                     TRUE ~ NA))



# calculate distance markers
distance_markers <- 
  gps %>% st_drop_geometry() %>% 
  mutate(km_label = 10*floor(distance_total / 10000)) %>%
  group_by(km_label) %>%
  filter(row_number() == 1, km_label > 0) %>% 
  select(distance_total, lon,lat,km_label )
distance_markers$km_label <- paste(distance_markers$km_label, " Km")

# make leaflet map
map <- leaflet(track) %>% 
  addTiles(urlTemplate = paste0("https://tile.jawg.io/jawg-lagoon/{z}/{x}/{y}{r}.png?access-token=",jawgapi),
           attribution = "<a href=\"https://www.jawg.io?utm_medium=map&utm_source=attribution\" target=\"_blank\">&copy; Jawg</a> - <a href=\"https://www.openstreetmap.org?utm_medium=map-attribution&utm_source=jawg\" target=\"_blank\">&copy; OpenStreetMap</a>&nbsp;contributors") %>% 
  addMiniMap(tiles =paste0("https://tile.jawg.io/jawg-lagoon/{z}/{x}/{y}{r}.png?access-token=",jawgapi),
             aimingRectOptions = list(color = "#23b09d", weight = 1, clickable = FALSE)) %>% 
  addPolylines(color = lijnkleur,weight = 3,opacity = trans) %>% 
  
  addLabelOnlyMarkers(lng = distance_markers$lon, lat = distance_markers$lat,
             label = distance_markers$km_label,
             labelOptions = labelOptions(noHide = TRUE, 
                                         direction = labeldirection,
                                         opacity = .8,
                                         style = list(
                                           "color" = "#23b09d",
                                           "font-family" = "noto sans",
                                           "font-style" = "regular",
                                           "box-shadow" = "3px 3px rgba(0,0,0,0.25)",
                                           "font-size" = "12px",
                                           "border-color" = "rgba(0,0,0,0.5)"
                                         )) 
             
                      ) %>% 
  addLabelOnlyMarkers(lng = gps$lon[1],lat = gps$lat[1],
                    label = "Start",
                    labelOptions = labelOptions(noHide = TRUE, 
                                                direction = start,
                                                opacity = .8,
                                                style = list(
                                                  "color" = "White",
                                                  "font-family" = "noto sans",
                                                  "font-style" = "regular",
                                                  "box-shadow" = "3px 3px rgba(0,0,0,0.25)",
                                                  "font-size" = "12px",
                                                  "border-color" = "#23b09d",
                                                  "background"="#23b09d"
                                                )) 
                      ) %>% 
  addLabelOnlyMarkers( lng = gps$lon[max(nrow(gps))],lat = gps$lat[max(nrow(gps))],
                      label = "Finnish",
                      labelOptions = labelOptions(noHide = TRUE, 
                                                  direction = finish,
                                                  opacity = .8,
                                                  style = list(
                                                    "color" = "White",
                                                    "font-family" = "noto sans",
                                                    "font-style" = "regular",
                                                    "box-shadow" = "3px 3px rgba(0,0,0,0.25)",
                                                    "font-size" = "12px",
                                                    "border-color" = "darkred",
                                                    "background"="darkred"
                                                  ))
                        ) %>% 
  addScaleBar()
filename <<- tools::file_path_sans_ext(basename(S.gpxlist[gpxnr]))
map<<-map
map
}

test <- as.data.frame(S.gpxlist)

#use map function
makemap(2,"botom","bottom", lijnkleur = "#640c82", trans=.7, labeldirection="auto", jawgapi = "ScYlimn0DmddEELnlYRgDZ9jWsWLj0VXUQcXKDxQ1d9Cjc1sKDb8FG4h2DZ6FJk2")

# set save dimentions
factor=4
plus=0
breed <- 297.638*factor+plus
lang <- 365.231*factor+plus

# save plot as png
mapshot(
  map,
  file = paste0(filename,"_map.png"),
  remove_controls = c("zoomControl", "layersControl", "homeButton",
                      "drawToolbar", "easyButton"),
  vwidth = breed, 
  vheight = lang)
browseURL(paste0(filename,"_map.png"))
getwd()
#make gpx list
routes <- data.frame(
                     "route"=tools::file_path_sans_ext(basename(S.gpxlist))) %>% arrange(route)


  
