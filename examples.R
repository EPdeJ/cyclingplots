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
