# see https://github.com/EPdeJ/cyclingplots#readme for more information

roll=7
colorscalestr=c("#9198A7","#C9E3B9", "#F9D49D", "#F7B175", "#F47D85", "#990000")

# add stamen key
register_stadiamaps("{your key}", write = TRUE)

# load packages and filepaths ---------------------------------------------
pacman::p_load(tidyverse,sf,ggmap,zoo,rosm,colorspace,ggspatial)

S.path <- "G:/.shortcut-targets-by-id/1kT69UY4d-Ny3cmezFuDPbeQRMwDT32dn/Fietsboek/2025/gpx/north"
S.gpxlist <- list.files(path = S.path, pattern = "\\.gpx$", full.names = T)

# get track layer from gpx
track <- st_read(S.gpxlist[10], layer = "tracks")

# get points from gpx
gps <- st_read(S.gpxlist[10], layer = "track_points") %>% 
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

# WORK IN PROGRESS (if seq is defined it will reduce the number of datapoints from the gpx)
if(seq){
  max_ele_index <- which.max(gps$ele)
  n_rows <- nrow(gps)
  intermediate_rows <- seq(from = 1 + seq, to = n_rows - 1, by = seq)
  rows_to_select <- unique(sort(c(1, max_ele_index, n_rows, intermediate_rows)))
  gps <- gps %>% slice(rows_to_select)
}

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


# Create bounding box (set limits for area)
bbox <- make_bbox(range(gps$lon), range(gps$lat))

# get the base-layer
map_layer <- get_stadiamap(bbox = bbox,
                            center = c(mean(range(gps$lon)),
                                       mean(gps(gps$lat))), 
                            zoom=11,
                            maptype = "outdoors"
                            )
# create distance markers/labels
distance_markers <- 
  gps %>% 
  mutate(dist_m_cumsum = cumsum(dist_to_lead_m)) %>%
  mutate(dist_m_cumsum_km_floor = floor(dist_m_cumsum / 10000)*10) %>%
  group_by(dist_m_cumsum_km_floor) %>%
  filter(row_number() == 1, dist_m_cumsum_km_floor > 0) 

# make plot (baselayer + points as track + distance layer)
plot <- 
  ggmap(map_layer)+
  geom_path(data = gps, aes(lon, lat, colour = ele),
            linewidth = 1,
            lineend = "round") +
  geom_label(data = distance_markers, aes(lon, lat, label = dist_m_cumsum_km_floor),
             size = 3) +
  scale_color_continuous_sequential(palette = "Viridis")+
  labs(x = "Longitude", 
       y = "Latitude", 
       color = "Elev. [m]",
       title = "Plot with elevation")
plot
