##RADS practice
##Assigning populations to arbitrary radius around a point location
##Ronald Buie, December 2023

#### Background ####
#The following is an R script introducing users to a basic geospatial analysis using common APDE resources
#It is part of a larger set of training resources that can be found here: https://github.com/PHSKC-APDE/R_training/tree/main/r_practice
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
               flextable,
               ggplot2) # Load list of packages
library(rads) #if rads is not installed, pacman cannot auto install it for you. Loading it separately will make any error easier to see.
library(spatagg)

#### Vignette ####

#first, we need places and coordinates. These were manually pulled from google maps searches and typed here
PizzaPlaces <- data.table("restaurant" = c("Flying Squirrel Pizza Co.", "Mamma Melina Ristorante & Pizzeria", "ROCCO'S", "Serious Pie Downtown", "Jackson Street Pizza Lounge", "Blotto"),
           "long" = c(-122.319183, -122.301110, -122.345950, -122.340790, -122.294690, -122.316620),
           "lat" = c(47.551128, 47.666530, 47.614570, 47.613050, 47.598980, 47.618490),
           "pop" = 0) #placeholder for the population we will generate

#convert our long and lat into a spatial coordinate (as a shape).
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
  CW <- create_xwalk(BlockShapes, PizzaGeos[rowIndex,], "GEOID20", "restaurant",min_overlap = 0.00001) #calculate the percentage of overlap between our census blocks and a pizza shop radius
  CWPop <- merge(CW, KCPops, by.x = "source_id", by.y = "geo_id") #combine crosswalk spacial information with population information
  weightedPop <- sum(CWPop$s2t_fraction * CWPop$pop) #calculate the weighted number of people within the radius of the pizza shop
  PizzaPlaces[rowIndex]$pop <- weightedPop #add resulting total to our pizza places data table
}

#report table
PizzaPlaces

#visualize the location of each restaurant
PizzaPlacesGeos <- merge(PizzaGeos, PizzaPlaces, by.x = c("restaurant"), by.y = c("restaurant")) #merging together our shape data and original pizza places (now with populations) so that pop and shape are aligned in ggplot

ggplot() + geom_sf(data = BlockShapes, fill = NA) +
  geom_sf(data = PizzaPlacesGeos, color = 'purple', aes(fill = pop), alpha = 0.7)

#This is a bit large for our purpose. Let's try cropping our map. This is based on Markus Konrad's blog here: https://www.r-bloggers.com/2019/04/zooming-in-on-maps-with-sf-and-ggplot2/

#cropping the shapefile
BlockShapes4326 <- st_transform(BlockShapes, crs = 4326) #st_crop works with coordinate system 4326, so convert back
BlockShapesCropped <- st_crop(BlockShapes4326, xmin = -122.4, xmax = -122.2, ymin = 47.5, ymax = 47.7,)
ggplot() + geom_sf(data = BlockShapesCropped) +
  geom_sf(data = PizzaPlacesGeos, color = 'purple', aes(fill = pop), alpha = 0.7)

#creating a viewing window (but keeping underlying shape file)
DisplayWindow4326 <- st_sfc(st_point(c(-122.4, 47.5)), st_point(c(-122.2, 47.7)), crs = 4326) #define the bottom left and top right corners of the window.
DisplayWindow4326
DisplayWindow2926 <- st_transform(DisplayWindow4326, st_crs(crsString)) #change to a matching coordinate system
windowCoord <- st_coordinates(DisplayWindow2926) #pull coordinates out of shape object
windowCoord

ggplot() + geom_sf(data = BlockShapes, fill = NA) +
  geom_sf(data = PizzaPlacesGeos, color = 'purple', aes(fill = pop), alpha = 0.7) +
coord_sf(xlim = windowCoord[,'X'], ylim = windowCoord[,'Y'], expand = FALSE)

