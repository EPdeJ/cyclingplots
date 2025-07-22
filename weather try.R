Taipei
library(extrafont) 
loadfonts(device = "win")
ggplot(weather.summary, aes(x = date)) +
  geom_col(aes(y = Rain), fill = "#008080", alpha = .7)+
  # geom_ribbon_pattern(aes(ymin = predict(loess(Temp.min~month(date)))*10,
  #                         ymax = predict(loess(Temp.max~month(date)))*10),
  #                     colour          = NA,
  #                     orientation ="x",
  #                     size            = 1,
  #                     pattern         = "gradient",
  #                     fill            = NA,
  #                     pattern_fill    = "#4682B4",
  #                     pattern_fill2   = "#822310",
  #                     pattern_alpha   =.3,
  #                     show.legend=T) +
  geom_smooth(aes(y = Temp.min*10), color="#4682B4", se = F, linewidth = 1, show.legend = T)+
  geom_smooth(aes(y = Temp.max*10), color="#822310", se = F,linewidth = 1, show.legend = T)+
  geom_text(
    aes(y = -40,  # Adjust vertical position as needed
        label = Wind.dir.fact),
    angle = 0,  # Adjust angle if needed
    hjust = 0.5,  # Center horizontally
    vjust = 0,    # Position above the plot area
    color = "black",  # Choose color
    size = 2) +
  # geom_arrow(
  #   aes(y = -5),
  #   stat_arrow ="angle",
  #   angle = weather.summary$Wind.dir,
  #   arrow.length=.7
  #   ) +
  scale_x_date(date_breaks = "1 month", date_labels = "%b")+
  theme_clean()+
  theme(text = element_text(family = "Noto Sans Light"),
        axis.title.x=element_blank())+
  scale_colour_economist()+
  scale_y_continuous(breaks = c(0,100,200,300,400,500),
                     "Precipitation (mm)", 
                     
                     sec.axis = sec_axis(~ . * .1, name = "Temperature (°C) min-max", breaks = c(-10, 0, 10, 20, 30, 40,50)))+
  facet_wrap(~location, axes = "all_x")+
  labs(
    title = "Taiwan Weather",
    subtitle="Rain, Temperature and Wind Direction",
    caption = "Climate data optained with CRAN openmeteo data, averages over last 10 years\nWind directions are predominant directions per months"
  )
