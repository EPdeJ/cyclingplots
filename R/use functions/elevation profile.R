# Source cycling maps function 
  source("R/Elevation plots as function.R") 


# Load filepath
  path <- paste0("G:/.shortcut-targets-by-id/1kT69UY4d-Ny3cmezFuDPbeQRMwDT32dn/Fietsboek/2025/gpx/","east/")

# Make list of all .gpx files in folder
  gpxlist <- list.files(path = path, pattern = "\\.gpx$", full.names = T)
  gpx.df <- gpxlist %>% 
    as.data.frame() %>% 
    rename(filepath=1) %>% 
    mutate(filename=basename(filepath),
           route_nr = str_extract(filename, "^[^_]+"),
           name = str_remove(filename, "\\.gpx$") %>%
             str_replace(paste0(route_nr, "_"), ""))

# use function ------------------------------------------------------------
  # north routes
    N.path <- "G:/.shortcut-targets-by-id/1kT69UY4d-Ny3cmezFuDPbeQRMwDT32dn/Fietsboek/2025/gpx/north"
    N.gpxlist <- list.files(path = N.path, pattern = "\\.gpx$", full.names = T)
  
    for (i in N.gpxlist) {
      elevationprofile(i,
                       plotsavedir = "G:/.shortcut-targets-by-id/1kT69UY4d-Ny3cmezFuDPbeQRMwDT32dn/Fietsboek/2025/elevation plots/north",
                       plotsave = T,  
      )
    }
  
  # south routes
    S.path <- "G:/.shortcut-targets-by-id/1kT69UY4d-Ny3cmezFuDPbeQRMwDT32dn/Fietsboek/2025/gpx/south"
    S.gpxlist <- list.files(path = S.path, pattern = "\\.gpx$", full.names = T)
    
    for (i in S.gpxlist) {
      elevationprofile(i,
                       plotsavedir = "G:/.shortcut-targets-by-id/1kT69UY4d-Ny3cmezFuDPbeQRMwDT32dn/Fietsboek/2025/elevation plots/south",
                       plotsave = T)
    }
    elevationprofile(S.gpxlist[3],
                     plotsavedir = "G:/.shortcut-targets-by-id/1kT69UY4d-Ny3cmezFuDPbeQRMwDT32dn/Fietsboek/2025/elevation plots/south",
                     plotsave = T,
                     fixed_breaks=25)
  
  
  
  # west routes
    W.path <- "G:/.shortcut-targets-by-id/1kT69UY4d-Ny3cmezFuDPbeQRMwDT32dn/Fietsboek/2025/gpx/west"
    W.gpxlist <- list.files(path = W.path, pattern = "\\.gpx$", full.names = T)
    
    for (i in W.gpxlist) {
      elevationprofile(i,
                       plotsavedir = "G:/.shortcut-targets-by-id/1kT69UY4d-Ny3cmezFuDPbeQRMwDT32dn/Fietsboek/2025/elevation plots/west",
                       plotsave = T)
    }
  
  # W6 sun moon lake strange
    elevationprofile(W.gpxlist[6],
                     plotsavedir = "G:/.shortcut-targets-by-id/1kT69UY4d-Ny3cmezFuDPbeQRMwDT32dn/Fietsboek/2025/elevation plots/west",
                     plotsave = T, 
                     fixed_breaks = 5)
    
    
  # east routes
    E.path <- "G:/.shortcut-targets-by-id/1kT69UY4d-Ny3cmezFuDPbeQRMwDT32dn/Fietsboek/2025/gpx/east"
    E.gpxlist <- list.files(path = E.path, pattern = "\\.gpx$", full.names = T)
    
    for (i in E.gpxlist) {
      elevationprofile(i,
                       plotsavedir = "G:/.shortcut-targets-by-id/1kT69UY4d-Ny3cmezFuDPbeQRMwDT32dn/Fietsboek/2025/elevation plots/east",
                       plotsave = T)
    }
    # correct tunnel in E9
      elevationprofile(E.gpxlist[10],
                       plotsavedir = "G:/.shortcut-targets-by-id/1kT69UY4d-Ny3cmezFuDPbeQRMwDT32dn/Fietsboek/2025/elevation plots/east",
                       plotsave = F)
      TUNNEL_START_KM <- 38017.39 # obtained after visual inspection of initial plot and data
      TUNNEL_END_KM   <- 40794.50 # obtained after visual inspection of initial plot and data
      
      # Create a new, corrected elevation column
        track_points_corrected <- mem_gpx %>%
          mutate(
            # 1. Create a copy of the elevation column to modify
              ele_corrected = ele,
            
            # 2. Set the elevation values *inside* the tunnel to NA.
            #    We keep the first and last points of the tunnel section (the entrance and exit)
            #    so the interpolation function has anchors.
              ele_corrected = if_else(
                distance_total > TUNNEL_START_KM & distance_total < TUNNEL_END_KM, 
                NA_real_, 
                ele_corrected
              ),
            
            # 3. Use linear interpolation to fill in the NA values
              ele_corrected = zoo::na.approx(ele_corrected)
          ) %>% 
          mutate(ele=ele_corrected) 
        elevationprofile(track_points_corrected,
                         plotsavedir = "G:/.shortcut-targets-by-id/1kT69UY4d-Ny3cmezFuDPbeQRMwDT32dn/Fietsboek/2025/elevation plots/east",
                         plotsave = T)
      
      
      
    
  # special routes
    X.path <- "G:/.shortcut-targets-by-id/1kT69UY4d-Ny3cmezFuDPbeQRMwDT32dn/Fietsboek/2025/gpx/special"
    X.gpxlist <- list.files(path = X.path, pattern = "\\.gpx$", full.names = T)
    
    for (i in X.gpxlist) {
      elevationprofile(i,
                       plotsavedir = "G:/.shortcut-targets-by-id/1kT69UY4d-Ny3cmezFuDPbeQRMwDT32dn/Fietsboek/2025/elevation plots/special",
                       plotsave = T,  
      )
    }
  
    elevationprofile(X.gpxlist[5],
                     plotsavedir = "G:/.shortcut-targets-by-id/1kT69UY4d-Ny3cmezFuDPbeQRMwDT32dn/Fietsboek/2025/elevation plots/special",
                     plotsave = T,
                     fixed_breaks = 100)
    
    

# Try other colours --------------------------------------------------------
  # standard
  elevationprofile(N.gpxlist[1])
  
  elevationprofile(N.gpxlist[1],
                   seg=2000,
                   fixed_breaks=7.5,
                   mingraddist=2.5,
                   colorscalestr=c("lightblue","lightgreen", "green", "pink", "orange", "darkred"),
                   linecolor="red",
                   maxlinecol="darkblue",
                   transparency=.7,
                   plotsave=T,
                   plotsavedir="~/cyclingplots/images",
                   plotname="Steep steeper steepst",
                   ggsave_width=24,
                   ggsave_height=10,
                   ggsave_dpi=300,
                   ggsave_units="cm",
                   ggsave_background="transparent")
  