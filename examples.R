# Run these examples to see the functions in action!
# only works if you have access to Erik's computer hahaha



# Elevation plots -----------------------------------------------------------------------------------------------------------------------------------

source("R/Elevation plots as function.R")

# use function ------------------------------------------------------------
S.path <- "G:/.shortcut-targets-by-id/1kT69UY4d-Ny3cmezFuDPbeQRMwDT32dn/Fietsboek/2025/gpx/north"
S.gpxlist <- list.files(path = S.path, pattern = "\\.gpx$", full.names = T)

for (i in S.gpxlist) {
elevationprofile(i,
                 plotsavedir = "G:/.shortcut-targets-by-id/1kT69UY4d-Ny3cmezFuDPbeQRMwDT32dn/Fietsboek/2025/elevation plots/north",
                 roll = 7, 
                 seq=10,
                 plotsave = T,  
                 rollparameter="mean")
}


elevationprofile(S.gpxlist[10],
                 seq=15,
                 roll=5,
                 rollparameter="max",
                 colorscalestr=c("lightblue","lightgreen", "green", "pink", "orange", "darkred"),
                 linecolor="red",
                 maxlinecol="darkblue",
                 transparency=.7,
                 plotsave=T,
                 plotsavedir=NULL,
                 plotname="Steep steeper steepst",
                 ggsave_width=24,
                 ggsave_height=10,
                 ggsave_dpi=300,
                 ggsave_units="cm",
                 ggsave_background="transparent")




# Cycling plots -------------------------------------------------------------------------------------------------------------------------------------
source("R/Cycling maps as function.R")

S.path <- "G:/.shortcut-targets-by-id/1kT69UY4d-Ny3cmezFuDPbeQRMwDT32dn/Fietsboek/2025/gpx/north"
S.gpxlist <- list.files(path = S.path, pattern = "\\.gpx$", full.names = T)


test <- as.data.frame(S.gpxlist)

#use map function
makemap(2,"botom","bottom", lijnkleur = "#640c82", trans=.7, labeldirection="auto", jawgapi = jawg)

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


  
