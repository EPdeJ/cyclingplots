# see https://github.com/EPdeJ/cyclingplots#readme for more information
# currently Jawg.Lagoon as base layer for maps in leaflet


# load packages ---------------------------------------------
  if(!require("pacman")){install.packages("pacman")}
  pacman::p_load(tidyverse,
                 sf,
                 ggmap,
                 zoo,
                 rosm,
                 colorspace,
                 ggspatial,
                 tmap,
                 maptiles,
                 leaflet,
                 leaflet.extras2,
                 utils,
                 htmltools,
                 webshot2,
                 remotes,
                 geosphere,
                 mapview)



# build function 
  makemap <- function(gpxpaths, # string containing one or multiple .gpx filepath(s)
                      start="left", # direction of the start label 
                      finish="right", # direction of the finish label
                      minimap=TRUE, # include minimap when True
                      zoom="auto", # set zoom, only adjust when auto is not working
                      lijnkleur="#22678A", # set color of the track
                      trans=1, # set transparency of the track
                      labeldirection, # direction of the km labels
                      jawgapi="", # provide an apikey for JAWG maps 
                      distmark=10 # distance between km markers
                      ){
  
    # Build track layer (track is for polygon line, gps is point data for distance calculation)
      track <- NULL # make empty variable for track 
      gps <- NULL # make empty variable for track
      
      # Start loop (in case multiple files are provided)
        for (i in gpxpaths){
          # track data
            temptrack <- st_read(gpxlist[i], layer = "tracks")
            temptrack$rid <- i
            track <- track %>% bind_rows(temptrack) %>% st_as_sf()
          
          
          # point data
            gpstemp <- st_read(gpxlist[i], layer = "track_points") %>% 
            mutate(dist_to_lead_m=c(0,lag(st_distance(geometry,lead(geometry),by_element = TRUE))[-1])) %>% 
            select(track_seg_point_id, ele,geometry,dist_to_lead_m) #select the usefull rows
          
            # calculate the difference in distance and elevation between data points
              gpstemp<- gpstemp %>%
                mutate(
                  elevation_diff=c(0,lag((lead(ele)-ele))[-1]),
                  distance_diff = c(0,lag(st_distance(geometry,lead(geometry),by_element = TRUE))[-1])
                ) 
          
            #create lon and lat variables
              gpstemp <- gpstemp %>% st_coordinates() %>% as.data.frame() %>% 
                rename(lon=X,lat=Y) %>% bind_cols(gpstemp) %>% st_as_sf()
          
            # Create distance and gradient vars
              gpstemp<- gpstemp %>% 
                mutate(
                  distance_total = cumsum(distance_diff),
                  elevation_total = cumsum(ifelse(elevation_diff > 0, elevation_diff, 0)),
                  gradient=(elevation_diff/distance_diff)*100
                ) # elevation can be negative so only cum sum when positive 
          
            gpstemp$gpsid <- i
            gps <- gps %>% bind_rows(gpstemp)%>% st_as_sf()
        }
    
    # calculate distance markers
      distance_markers <- gps %>% 
        st_drop_geometry() %>% group_by(gpsid) %>% 
        mutate(km_label = distmark*floor(distance_total / (distmark*1000))) %>%
        group_by(gpsid,km_label) %>%
        filter(row_number() == 1, km_label > 0) %>% 
        select(gpsid,distance_total, lon,lat,km_label )
      distance_markers$km_label <- paste(distance_markers$km_label, " Km") # add character label
    
    # make leaflet map
      map <- leaflet(track) %>% 
        addTiles(urlTemplate = paste0("https://tile.jawg.io/jawg-lagoon/{z}/{x}/{y}{r}.png?access-token=",jawgapi), 
                 options = leafletOptions(minZoom = zoom,
                                          maxZoom = zoom,
                                          attributionControl = TRUE),
                 attribution = "<a href=\"https://www.jawg.io?utm_medium=map&utm_source=attribution\" target=\"_blank\">&copy; Jawg</a>
                 - 
                 <a href=\"https://www.openstreetmap.org?utm_medium=map-attribution&utm_source=jawg\" target=\"_blank\">&copy; OpenStreetMap </a>
                 contributors
                 <a href=\"https://www.openstreetmap.org/copyright\" target=\"_blank\">  openstreetmap.org/copyright</a>") %>% 
        {
          if(minimap){addMiniMap(.,tiles =paste0("https://tile.jawg.io/jawg-lagoon/{z}/{x}/{y}{r}.png?access-token=",jawgapi),
                                 position = "bottomleft",
                                 aimingRectOptions = list(color = "#22678A", weight = 1))
          } else {
              .
            }
        } %>% 
        
        addPolylines(color = lijnkleur,weight = 4,opacity = trans) %>%
        addLabelOnlyMarkers(lng = distance_markers$lon, lat = distance_markers$lat,
                   label = distance_markers$km_label,
                   labelOptions = labelOptions(noHide = TRUE, 
                                               direction = labeldirection,
                                               opacity = 1,
                                               style = list(
                                                 "color" = "#22678A",
                                                 "font-family" = "noto sans",
                                                 "font-weight" = "bold",
                                                 "box-shadow" = "3px 3px rgba(0,0,0,0.25)",
                                                 "font-size" = "14px",
                                                 "border-color" = "rgba(0,0,0,0.5)"
                                               )) 
                   
                            ) %>% 
        addLabelOnlyMarkers(lng = gps %>% st_drop_geometry() %>%  group_by(gpsid) %>% select(lon) %>% slice_head(n=1) %>% pull(),
                            lat = gps %>% st_drop_geometry() %>%  group_by(gpsid) %>% select(lat)%>% slice_head(n=1) %>% pull(),
                          label = "Start",
                          labelOptions = labelOptions(noHide = TRUE, 
                                                      direction = start,
                                                      opacity = 1,
                                                      style = list(
                                                        "color" = "White",
                                                        "font-family" = "noto sans",
                                                        "font-weight" = "regular",
                                                        "box-shadow" = "3px 3px rgba(0,0,0,0.25)",
                                                        "font-size" = "14px",
                                                        "border-color" = "#22678A",
                                                        "background"="#22678A"
                                                      )) 
                            ) %>% 
        addLabelOnlyMarkers( lng = gps %>% st_drop_geometry() %>%  group_by(gpsid) %>% select(lon) %>% slice_tail(n=1) %>% pull(),
                            lat = gps %>% st_drop_geometry() %>%  group_by(gpsid) %>% select(lat) %>% slice_tail(n=1) %>% pull(),
                            label = "Finish",
                            labelOptions = labelOptions(noHide = TRUE, 
                                                        direction = finish,
                                                        opacity = 1,
                                                        style = list(
                                                          "color" = "White",
                                                          "font-family" = "noto sans",
                                                          "font-weight" = "regular",
                                                          "box-shadow" = "3px 3px rgba(0,0,0,0.25)",
                                                          "font-size" = "14px",
                                                          "border-color" = "darkred",
                                                          "background"="darkred"
                                                        ))
                              ) %>% 
        addScaleBar(position = "bottomleft") %>% 
        htmlwidgets::onRender("
          function(el, x) {
            var map = this;
      
            // Move attribution to bottomleft
            map.attributionControl.setPosition('bottomleft');
      
            // Wait a moment to ensure all controls are rendered
            setTimeout(function() {
              var container = document.querySelector('.leaflet-bottom.leaflet-left');
              var attribution = container.querySelector('.leaflet-control-attribution');
              if (attribution) {
                container.appendChild(attribution); // move it to bottom
                attribution.style.marginLeft = '30px';
                 attribution.style.marginBottom = '0px';
              }
            // Shift scalebar
            var scale = container.querySelector('.leaflet-control-scale');
            if (scale) {
              scale.style.marginLeft = '80px'; // adjust offset
               scale.style.marginBottom = '0px';
            }
      
            // Shift minimap
            var mini = container.querySelector('.leaflet-control-minimap');
            if (mini) {
              mini.style.marginLeft = '80px'; // adjust offset
               mini.style.marginBottom = '30px';
            }
            }, 100);
          }
        ")
      filename <<- tools::file_path_sans_ext(basename(gpxlist[i]))
      region <<- region
      map
  }


  
