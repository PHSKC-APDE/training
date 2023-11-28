##RADS practice
##Assigning populations to arbitrary radi around location##
##Ronald Buie, Nov 2023

#### Background ####
#The following is an R script introducing users to a basic geospatial analysis using common APDE resources
#It is part of a larger set of training resources that can be found here: <link to training github>
#
#This vignette relies on our in-house analytics package "R Analytics "R Automatic Data System" or RADS. You can find RADS and installation instructions here: https://github.com/PHSKC-APDE/rads
#
#This vignette also relies on Daniel's SpatAgg package to assist geospatial aggregation of populations. You can find spatagg and installation instruction here: https://github.com/PHSKC-APDE/spatagg
#
#A recorded presentation of this script, with audience Q/A can be found here:
#

#### Setup ####

##Load packages and set defaults
pacman::p_load(data.table,
               sf,
               flextable) # Load list of packages
library(rads) #if rads is not installed, pacman cannot auto install it for you. Loading it separately will make any error easier to see.
library(spatagg)
library(kcparcelpop)
library(ggplot2)

# ##Set environment options
# options(max.print = 350) # Limit # of rows to show when printing/showing a data.frame
# options(tibble.print_max = 50) # Limit # of rows to show when printing/showing a tibble (a tidyverse-flavored data.frame)
# options(scipen = 999) # Avoid scientific notation
# origin <- "1970-01-01" # Set the origin date, which is needed for many data/time functions
# export_path <- "C:/Users/REPLACE WITH YOUR USER NAME/OneDrive - King County/" #replace with your desired path, use forward slashes



#### Vignette ####

#first, we need places and coordinates. These were manually pulled from google maps searches and typed here
PizzaPlaces <- data.table("restaurant" = c("Flying Squirrel Pizza Co.", "Mamma Melina Ristorante & Pizzeria", "ROCCO'S", "Serious Pie Downtown", "Jackson Street Pizza Lounge", "Blotto"),
           "long" = c(-122.319183, -122.301110, -122.345950, -122.340790, -122.294690, -122.316620),
           "lat" = c(47.551128, 47.666530, 47.614570, 47.613050, 47.598980, 47.618490),
           "pop" = 0) #placeholder for the population we will generate

#convert our long and lat into a geospation coordinate (as a shape).
crsString <- "EPSG:2926" #preferred coordinate reference system for WA
PizzaGeos <- st_as_sf(x = PizzaPlaces[,c("restaurant", "long", "lat")],coords = c("long","lat"), crs = "EPSG:4326") #convert to a geometry. Note that google maps is probably using coordinate system EPSG:4326, so we specify that here
PizzaGeos <- st_transform(PizzaGeos, st_crs(crsString))

#expand the coordinate into a circle of a .5 mile radius
PizzaGeos <- st_buffer(PizzaGeos, units::set_units(0.5, mile)) # units::set_units is intelligent about types of units so you can specify "mile". st_buffer will create a perimeter of the provided units.

#pull a shapefule of king county from APDE's store
BlockShapes <- st_read("//dphcifs/APDE-CDIP/Shapefiles/Census_2020/block/kc_block.shp") #notice, these are shapefiles for census blocks to use in our maps
BlockShapes <- st_transform(BlockShapes, st_crs(crsString)) #conform to same crs

#get KC population estimates. Note, if a radius desired extends outside the county, then need to expand. Will greatly slow down calculations
#if not saved, pull and save. Otherwise, load from save
KCPops <- get_population(geo_type = "blk", kingco = T, year = 2022)

#loop through restaurants, generate crosswalk of overlapping populations, and assign population to restaurant table
for(rowIndex in 1:nrow(PizzaGeos)) {
  CW <- create_xwalk(BlockShapes, PizzaGeos[rowIndex,], "GEOID20", "restaurant",min_overlap = 0.00001)
  CWPop <- merge(CW, KCPops, by.x = "source_id", by.y = "geo_id")
  weightedPop <- sum(CWPop$s2t_fraction * CWPop$pop)

  PizzaPlaces[rowIndex]$pop <- weightedPop
}

#report table
PizzaPlaces

#visualize the location of each restaurant
PizzaPlacesGeos <- merge(PizzaGeos, PizzaPlaces, by.x = c("restaurant"), by.y = c("restaurant")) #merging together our shape data and original pizza places (now with populations) so that pop and shape are aligned in ggplot
ggplot() + geom_sf(data = BlockShapes, fill = NA) +
  geom_sf(data = PizzaPlacesGeos, color = 'purple', aes(fill = pop))
