#'the idea behind this:
#'load a .gpx for your route, get an overview of the weather of the last 10y
#'or a forecast for the coming days
#'a map with the forecast might also be an idea


# load packages
pacman::p_load(sf,ggimage,tidyverse,openmeteo,tidygeocoder,grid, colorspace,ggpattern,magick,ggh4x,metR,ggthemes, showtext )

# get an overview of all weather variables in openmeteo
weather_variables()

# load gpx file
S.path <- "G:/.shortcut-targets-by-id/1kT69UY4d-Ny3cmezFuDPbeQRMwDT32dn/Fietsboek/2025/gpx/north"
S.gpxlist <- list.files(path = S.path, pattern = "\\.gpx$", full.names = T)
track <- st_read(S.gpxlist[5], layer = "tracks")

# obtain central point of gpx track
point <- st_centroid(track) %>% st_coordinates() %>% as.data.frame() 

#'somehow need to find the closest city to a coordinate
#'the code below works for coordinates close to a large city
city <- tidygeocoder::reverse_geo(long=point$X, lat = point$Y, method = "arcgis", full_results = T) %>% 
  select(City,CntryName) |> 
  mutate(city=paste0(str_extract(City,"\\b\\w+\\b"),", ", CntryName)) |> 
  select(city) |> 
  pull()

#' the code below works well for large cities, how can we get it working with smaller places
#' maybe openmeteo zoom level is not sufficient to do what we want
Taipei <- weather_history(
  location="taipei",
  start="2015-01-01",
  end="2025-01-01",
  daily = list("sunrise",
               "sunset",
               "temperature_2m_min",
               "temperature_2m_max",
               "apparent_temperature_max", 
               "precipitation_sum", 
               "windspeed_10m_max",
               "wind_direction_10m_dominant")
)


# for development purpose the code below is just to make weather graph based on large locations with hstorical data

# get weather history
weather1 <- weather_history(
  location="Taipei",
  start="2015-01-01",
  end="2025-01-01",
  #see weather_variables() to select variables
  daily = list("sunrise",
               "sunset",
               "apparent_temperature_min",
               "apparent_temperature_max", 
               "precipitation_sum", 
               "windspeed_10m_max",
               "wind_direction_10m_dominant")
  )
weather1$location <- "Taipei (North)"

weather2 <- weather_history(
  location="Tainan",
  start="2015-01-01",
  end="2025-01-01",
  #see weather_variables() to select variables
  daily = list("sunrise",
               "sunset",
               "apparent_temperature_min",
               "apparent_temperature_max", 
               "precipitation_sum", 
               "windspeed_10m_max",
               "wind_direction_10m_dominant")
)
weather2$location <- "Tainan (West)"
weather3 <- weather_history(
  location="Hualien",
  start="2015-01-01",
  end="2025-01-01",
  #see weather_variables() to select variables
  daily = list("sunrise",
               "sunset",
               "apparent_temperature_min",
               "apparent_temperature_max", 
               "precipitation_sum", 
               "windspeed_10m_max",
               "wind_direction_10m_dominant")
)
weather3$location <- "Hualien (East)"
weather4 <- weather_history(
  location="Kaohsiung",
  start="2015-01-01",
  end="2025-01-01",
  #see weather_variables() to select variables
  daily = list("sunrise",
               "sunset",
               "apparent_temperature_min",
               "apparent_temperature_max", 
               "precipitation_sum", 
               "windspeed_10m_max",
               "wind_direction_10m_dominant")
)
weather4$location <- "Kaohsiung (South)"
weather <- rbind(weather1,weather2,weather3,weather4)



#change formats for dates and make day month year factors
weather <- weather %>% 
  mutate(
  # Convert date to proper date format if it isn't already
  date = ymd(date), 
  # Create a factor for year
  year = year(date),
  #create a factor for month, e.g. January (label=True)
  month = month(date, label = TRUE, abbr=F),
  #create a factor for day, e.g. Monday (label=True)
  day = wday(date, label = TRUE, abbr=F),
  #change sunset and sunrise as date-time
  daily_sunrise = ymd_hm(daily_sunrise,tz = "Asia/Taipei"),
  daily_sunset = ymd_hm(daily_sunset, tz = "Asia/Taipei")
  )

weather %>%    group_by(location,month = month(date)) %>% select(date, daily_apparent_temperature_max) %>%mutate(min=min(daily_apparent_temperature_max))
#summarize weather for 10 years
names(weather)
weather.summary <- weather %>% 
  group_by(location,month = month(date)) %>% 
  summarise(
    Rain = sum(daily_precipitation_sum)/10,
    Temp.min = mean(daily_apparent_temperature_min , rm.na = TRUE),
    Temp.max = mean(daily_apparent_temperature_max , rm.na = TRUE),
    Temp.max.min = min(daily_apparent_temperature_max , rm.na = TRUE),
    Temp.max.max = max(daily_apparent_temperature_max , rm.na = TRUE),
    Wind = mean(daily_windspeed_10m_max , rm.na = TRUE),
    Wind.dir = mean(daily_wind_direction_10m_dominant, rm.na = TRUE))

weather.summary <- weather.summary %>% 
  mutate(
    date=ymd(paste0("2025-",month,"-1")))

#make a function for wind direction
categorize_wind_direction <- function(degrees) {
  if (is.null(degrees) || is.na(degrees)) {
    return(NA_character_)  # Handle missing values
  }
  
  degrees <- as.numeric(degrees) #Handle int/string/factor inputs
  
  directions <- c("N", "NE", "E", "SE", "S", "SW", "W", "NW", "N")
  boundaries <- c(22.5, 67.5, 112.5, 157.5, 202.5, 247.5, 292.5, 337.5, 360.0)
  
  for (i in seq_along(boundaries)) {
    if (degrees <= boundaries[i]) {
      return(directions[i])
    }
  }
  return(NA_character_) #Handles unexpected values
}

weather.summary <- weather.summary %>%
  mutate(
    Wind.dir.fact = sapply(Wind.dir,categorize_wind_direction)) %>% 
  ungroup

names(weather)

# reorder cities
weather.summary <- weather.summary %>% 
  mutate(
  location = fct_relevel(location, c("Taipei (North)", 
                                     "Tainan (West)", 
                                     "Hualien (East)", 
                                     "Kaohsiung (South)"))) 
weather.summary <- weather.summary %>%
  mutate(image_path = file.path("G:/.shortcut-targets-by-id/1kT69UY4d-Ny3cmezFuDPbeQRMwDT32dn/Fietsboek/2025/wind", paste0(Wind.dir.fact, ".png")))

#make plot
library(extrafont) 
loadfonts(device = "win")
ggplot(weather.summary, aes(x = date)) +
  geom_col(aes(y = Rain), fill = "#008080", alpha = .7)+
  geom_smooth(aes(y = Temp.min*10), color="#22678A", se = F, linewidth = 1, show.legend = T)+
  geom_smooth(aes(y = Temp.max*10), color="#822310", se = F,linewidth = 1, show.legend = T)+
  geom_text(
    aes(y = -40,  # Adjust vertical position as needed
        label = Wind.dir.fact),
    angle = 0,  # Adjust angle if needed
    hjust = 0.5,  # Center horizontally
    vjust = 0,    # Position above the plot area
    color = "#22678A",  # Choose color
    size = 4) +
  scale_x_date(date_breaks = "1 month", date_labels = "%b")+
  geom_image(aes(y = 30, image = image_path), size = 0.1) + # Adjust 'y' and 'size' as needed
  theme_clean()+
  theme(
    text = element_text(family = "Noto Sans Light"),
    axis.title.x = element_blank(),
    # Increase X and Y axis text (labels at the bottom and left)
    axis.text.x = element_text(size = 12, color = "#22678A"), # Adjust size as desired
    axis.text.y = element_text(size = 12, color = "#22678A"), # Adjust size as desired
    # Increase Y-axis title size
    axis.title.y = element_text(size = 12, color = "#22678A"), # Adjust size as desired
    strip.text.x = element_text(size = 12,face = "bold", color = "#22678A"),
    # Increase plot title, subtitle, and caption size
    plot.title = element_text(size = 14, face = "bold", hjust = .5),    # Adjust size and make bold
    plot.subtitle = element_text(size = 10, hjust = .5),               # Adjust size
    plot.caption = element_text(size = 10),                 # Adjust size
    panel.border = element_blank(),
    panel.background = element_blank(),
    plot.background = element_blank(),
    strip.background = element_blank()
  ) +
  scale_colour_economist()+
  scale_y_continuous(breaks = c(0,100,200,300,400,500),
    "Precipitation (mm)", 
    
    sec.axis = sec_axis(~ . * .1, name = "Temperature (°C) min-max", breaks = c(-10, 0, 10, 20, 30, 40,50)))+
  facet_wrap(~location, axes = "all_x", nrow=4, )+
  labs(
    title = "Taiwan Weather",
    subtitle="Rain [histogram], Temperature [min-max lines] and Wind Direction [arrows]",
    caption = str_wrap("2015-2025 Climate data from CRAN openmeteo data. Predominant Wind directions per month", 100)
  )

#safe the plot


ggsave(
  "Weather.png",
  plot = last_plot(),
  path = "G:/.shortcut-targets-by-id/1kT69UY4d-Ny3cmezFuDPbeQRMwDT32dn/Fietsboek/2025",
  width = 105 ,
  height = 175 ,
  units = "mm",
  dpi =  600,
  scale=2,
  grDevices::png)

