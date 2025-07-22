# Source cycling maps function
  source("R/Cycling maps as function.R")

# Load filepath
  path <- paste0("G:/.shortcut-targets-by-id/1kT69UY4d-Ny3cmezFuDPbeQRMwDT32dn/Fietsboek/2025/gpx/","north/")

# Make list of all .gpx files in folder
  gpxlist <- list.files(path = path, pattern = "\\.gpx$", full.names = T)

# Use sourced map function
  map <- makemap(region="special",
                 c(9),
                 "top","bottom", 
                 lijnkleur = "#22678A", 
                 trans=.9, 
                 labeldirection="bottom", 
                 jawgapi = jawg, 
                 distmark=10,
                 minimap=TRUE)
  map # display map

# set dimensions for saved file
  factor=8
  plus=200
  breed <- 136 *factor+plus
  lang <- 136.023 *factor+plus

# save plot as png
  mapshot(
    map,
    file = paste0("G:/.shortcut-targets-by-id/1kT69UY4d-Ny3cmezFuDPbeQRMwDT32dn/Fietsboek/2025/maps/","test","/",filename,"_map.png"),
    remove_controls = c("zoomControl", "layersControl", "homeButton",
                        "drawToolbar", "easyButton"),
    vwidth = breed, 
    vheight = lang,
  )

  browseURL(paste0("G:/.shortcut-targets-by-id/1kT69UY4d-Ny3cmezFuDPbeQRMwDT32dn/Fietsboek/2025/maps/","test","/",filename,"_map.png"))












for (i in 1:14){
  map <- makemap(i,"top","bottom", lijnkleur = "#640c82", trans=.9, labeldirection="top", jawgapi = jawg)
  
  # set save dimentions
  factor=8
  plus=2
  breed <- 136 *factor+plus
  lang <- 136.023 *factor+plus
  
  # save plot as png
  mapshot(
    map,
    file = paste0("G:/.shortcut-targets-by-id/1kT69UY4d-Ny3cmezFuDPbeQRMwDT32dn/Fietsboek/2025/maps/south/",filename,"_map.png"),
    remove_controls = c("zoomControl", "layersControl", "homeButton",
                        "drawToolbar", "easyButton"),
    vwidth = breed, 
    vheight = lang)
  
}



browseURL(paste0(filename,"_map.png"))
getwd()
#make gpx list
routes <- data.frame("route"=tools::file_path_sans_ext(basename(S.gpxlist))) %>% arrange(route)
