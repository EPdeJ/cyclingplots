# Source cycling maps function
  source("R/Cycling maps as function.R")
  
# Load filepath
  path <- paste0("G:/.shortcut-targets-by-id/1kT69UY4d-Ny3cmezFuDPbeQRMwDT32dn/Fietsboek/2025/gpx/","north/")

# Make list of all .gpx files in folder
  gpxlist <- list.files(path = path, pattern = "\\.gpx$", full.names = T)
  list_sorted <- gpxlist %>%
    as_tibble() %>%
    rename(path = value) %>%
    mutate(route = basename(path)) %>%
    mutate(sort_key = str_sort(route, numeric = TRUE)) %>%
    arrange(match(route, sort_key)) %>%
    select(-sort_key) # Remove the temporary column
  list_sorted$path
  gpxlist <- list_sorted$path


# Use sourced map function
  map <- makemap(c(1),
                 "top","top", 
                 lijnkleur = "#22678A", 
                 trans=.9, 
                 labeldirection="bottom", 
                 jawgapi = jawg, 
                 distmark=10,
                 minimap=TRUE
                 )
  map # display map

# set dimensions for saved file
  factor=8
  plus=200
  breed <- 136 *factor+plus
  lang <- 136.023 *factor+plus

# save plot as png
  mapshot(
    map,
    file = paste0("G:/.shortcut-targets-by-id/1kT69UY4d-Ny3cmezFuDPbeQRMwDT32dn/Fietsboek/2025/maps/","north","/",filename,"_map.png"),
    remove_controls = c("zoomControl", "layersControl", "homeButton",
                        "drawToolbar", "easyButton"),
    vwidth = breed, 
    vheight = lang,
  )
#see map
  browseURL(paste0("G:/.shortcut-targets-by-id/1kT69UY4d-Ny3cmezFuDPbeQRMwDT32dn/Fietsboek/2025/maps/","test","/",filename,"_map.png"))













