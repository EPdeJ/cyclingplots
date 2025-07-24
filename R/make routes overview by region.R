# load packages -----------------------------------------------------------
  pacman::p_load(sf,
                 tmap, 
                 rcartocolor,
                 maptiles, 
                 tmaptools,
                 OpenStreetMap,
                 cartography,
                 viridis,
                 osmdata,
                 RColorBrewer,
                 cols4all,
                 showtext,
                 tmaptools, 
                 tidyverse)
  # c4a_gui() to check all colors from cols4all

# load colours 
  source("setup/Book colours by region.R")

# select north Taiwan -----------------------------------------------------
  tw.north <- tw.grouped %>% 
    # filter(GROUP=="East Taiwan") %>%
    st_buffer(dist = 0.0001) %>% 
    st_union(by_feature = F,is_coverage = F) %>%
    st_boundary()

# make bounding box -------------------------------------------------------
box <- st_bbox(tw.north)
tw.north.city <- opq(bbox=box) %>% 
  add_osm_feature (key = "place", value = "city") %>% 
  osmdata_sf ()
tw.north.suburb <- opq(bbox=box) %>% 
  add_osm_feature (key = "place", value = "suburb") %>% 
  osmdata_sf ()



getwd()
get_overpass_url()

available_tags("name")

# north folder with gpx-es
gpx_folder_north <- "G:/.shortcut-targets-by-id/1kT69UY4d-Ny3cmezFuDPbeQRMwDT32dn/Fietsboek/2025/gpx/Special" # Replace with your folder path

# make a file list
gpx_files <- list.files(gpx_folder_north, pattern = "\\.gpx$", full.names = TRUE)

# Initialize an empty list to store sf objects
all_tracks_list <- list() 

#loop import gpx
for (file_path in gpx_files) {
  tryCatch({
    #import gpx as sf
    gpx_sf <- st_read(file_path, layer = "tracks", quiet = TRUE)
    
    #alter file name (remove .gpx and change _ in " ")
    file_name <- basename(file_path)
    file_name <- str_remove(file_name, "\\.gpx$") # Remove ".gpx"
    file_name <- gsub("_", " ", file_name)
    
    #create route number
    routenr <- sub(" .*", "", file_name)
    
    #add file_name and routenr to sf object
    gpx_sf$file_name <- file_name
    gpx_sf$route_nr <- routenr
    
    #add sf to list with other tracks
    all_tracks_list[[length(all_tracks_list) + 1]] <- gpx_sf
  }, error = function(e) {
    #error message indicating file
    message(paste("Error reading", file_path, ":", e$message))
  })
}

# if all_tracks excists remove
if(exists("all_tracks")){rm(all_tracks)}

# change list to one sf object and change name field
all_tracks <- bind_rows(all_tracks_list) %>% 
  st_as_sf() %>% 
  select(-name) %>% 
  rename(name=file_name) %>% 
  select(name,geometry, route_nr) 

#get the middle poit of each track for labeling purposes 
all_tracks <- all_tracks %>% 
  mutate(
    middle_point = st_line_interpolate(st_cast(geometry,"LINESTRING"),.8,normalized = T),
    lng = st_coordinates(middle_point)[, "X"],
    lat = st_coordinates(middle_point)[, "Y"]
  ) %>%
  
  mutate(name=as.factor(name))

#create a color palette for each track
nlevels(all_tracks$name)
factpal <- colorFactor(palette = viridis(n = 14,option = "H"), domain=all_tracks$name)
factpal(all_tracks$name)
# tw.north.labels <- get_tiles(tw.north , provider = "CartoDB.PositronOnlyLabels", zoom = 10, crop = TRUE)
test <- openmap(upperLeft = c(box[4],box[1]),
                lowerRight= c(box[2],box[3]),
                zoom = 9,type = "osm")
# osm <- read_osm(box, type = "esri-topo", zoom=9)

all_tracks$name
#make north map
selectednorth <- all_tracks %>% 
  mutate(name=as.character(name)) %>% 
  arrange(name) %>% 
  slice(1:9)
# 
# selectednorth$name[1] <- "N1 Wufenshan"
# selectednorth$name[7] <- "N5 Maokong"
# selectednorth$name[9] <- "N7 Lalashan"
# selectednorth$name[4] <- "N2 Fengguizui"

selectednorth <- selectednorth %>% 
  mutate(N_num = as.numeric(str_extract(name, "(?<=X)\\d+"))) %>%
  arrange(N_num) %>% 
  mutate(route_nr=paste0("X", N_num),
         name=fct_inorder(name,ordered = T))

routeindex <- selectednorth %>% 
  st_drop_geometry() %>% 
  mutate(geometry=middle_point) %>% 
  select(-middle_point) %>% 
  st_as_sf()
str(routeindex)

font_add_google(name = "Noto Sans", family = "Noto Sans")  # Downloads and registers it
showtext_auto()

library(rcartocolor)

route_names <- unique(selectednorth$name)
route_palette <- setNames(carto_pal(name = "Bold", n = length(route_names)), route_names)

map <- 
  tm_shape(tw.north, bb = bb(box, width = 2, height = 1, ext = 2)) +
  tm_tiles("CartoDB.Positron", zoom = 10) +
  tm_borders(col = palette_special[1], lwd = 3, col_alpha = 0.5) +
  
  tm_shape(selectednorth) +
  tm_lines(
    col = "name", 
    col.scale = tm_scale_categorical(values = route_palette),
    col.legend = tm_legend(
      position = c("right", "bottom"),
      title = "",
      legend.title.fontface = "Noto Sans",
      legend.text.fontface = "Noto Sans"
    )
  ) +
  
  tm_shape(routeindex) +
  tm_bubbles(
    fill = "name",
    fill.scale = tm_scale_categorical(values = route_palette),
    size = 0.6,
    col_alpha = 0  # transparent outline
  ) +
  tm_text(
    "route_nr", 
    col = "white",
    fontfamily = "Noto Sans",
    size = 1.7
  ) +
  
  tm_options(
    component.autoscale = TRUE,
    frame = FALSE,
    asp = 1
  ) +
  
  tm_layout(
    inner.margins = c(0, 0, 0, 0),
    outer.margins = c(0, 0, 0, 0),
    legend.show = FALSE,
    legend.only = FALSE,
    scale = 1.5
  )

map
tmap_save(tm = map,
          filename ="G:/.shortcut-targets-by-id/1kT69UY4d-Ny3cmezFuDPbeQRMwDT32dn/Fietsboek/2025/maps/divider/Special overview.png", 
          scale=1.5, width = 140, units="mm", dpi=600)

# ggsave(plot= tmap_grob(map),
#        path = plotsavedir,
#        filename = paste0(ifelse(plotname!="", paste(plotname), sub("\\.gpx$", "", basename(filepath))),"test.png"),
#        dpi = as.numeric(600),
#        type = "cairo-png",
#        bg = "transparent" )


# namelist
df_cleaned <- routeindex %>% 
  st_drop_geometry() %>% 
  select(name, route_nr) %>% 
  mutate(
    clean_name = str_remove(name, "^N\\d+-?\\d*\\s+"),  # remove N1, N1-1, N10 etc. and following space
    clean_name = str_trim(clean_name),                 # clean up any stray spaces
    clean_name = paste0(route_nr, " ", clean_name)     # prepend route_nr
  )
54.506 -50.337 

