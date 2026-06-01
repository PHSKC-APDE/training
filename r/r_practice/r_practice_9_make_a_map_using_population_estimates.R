#RADS practice
#Make a map (extra credit)
#Ronald Buie, 2026-06-01

pacman::p_load(apde.data, data.table, dplyr, gh, gitcreds, ggplot2, ggrepel, ggthemes, keyring, lubridate, openxlsx, rads, rads.data, rstudioapi, sf, tidyverse, usethis)

##Goal: Make a Health Reporting Area (HRA)-based map of population in the year 2020

##Load population data estimates using get_population function from RADS package
hra_pop <- apde.data::population(
  kingco = TRUE,
  years = 2020,
  geo_type = 'hra'
)

##Load HRA shapefile
hra2020 <- st_read("\\\\dphcifs/apde-cdip/shapefiles/hra/hra_2020_nowater.shp")
city <- st_read("\\\\gisdw/kclib/Plibrary2/census/shapes/polygon/place10.shp")

##Compare the class (i.e., type of object) of the field that will be used to join the HRA shapefile and the HRA-based data
class(hra_pop$geo_id_code) #This is a character or text class object
class(hra2020$id) #This is a numeric class object
class(hra_pop$geo_id_code) == class(hra2020$id) #This comparison returns FALSE as the classes are different

##Normalize (i.e., make the same) the object class by changing the HRA ID variable in the HRA-based data table to numeric
hra_pop <- hra_pop %>%
  mutate(geo_id_code = as.numeric(geo_id_code))

class(hra_pop$geo_id_code) == class(hra2020$id) #This comparison returns TRUE as the classes are now the same

##Merge birth results dataset with HRA shapefile
map <- merge(hra_pop, hra2020, by.x = "geo_id_code", by.y = "id", all.x = T, all.y = F)

##Convert map object to shapefile to prepare for mapping
map <- st_as_sf(map)

##Crop city shapefile to extent of HRA2020 shapefile
#Note the function to apply the coordinate system used by the HRA shapefile to the city shapefile
city <- st_crop(st_transform(city, st_crs(hra2020)), hra2020)

##Select cities of interest for showing labels on map
setDT(city)
cities.of.interest <- c("Snoqualmie", "SeaTac", "Kent", "Auburn", "Seattle", "Kirkland", "Bellevue", "White Center",
                        "Enumclaw", "Burien", "Shoreline")
city <- city[NAME10 %in% cities.of.interest, ]
city <- st_as_sf(city)
city <- city %>% group_by(NAME10) %>% summarize() # collapse down to 1 row per location

##Get centroids for city text labels
centroids <- st_centroid(city)
centroids <- cbind(centroids, st_coordinates(st_centroid(centroids$geometry)))
setDT(centroids)

##Set up map for plotting
my.map1 <- ggplot() +
  geom_sf(data = hra2020, fill = 'White', color = NA) + #White color for water and other blank areas, no outline
  geom_sf(data = map, aes(fill=pop), size = 0.3) + #Color HRAs according to mean_percent
  geom_sf(data = hra2020, fill = NA, size = 1, color = 'black') + #Black outlines for HRAs
  geom_label(data = centroids, aes(x=X, y=Y, label = as.character(NAME10)), size = 5, color = 'Black',
             label.padding = unit(0.1, "lines")) + #Labels for cities of interest
  geom_label_repel()+ #Ask labels to avoid overlapping

  labs(title = "2020 population by King County Health Reporting Area") +

  theme(plot.title = element_text(color = "black", size = 20, face = "bold"), #Format title
        axis.line = element_blank(), axis.text = element_blank(), #Suppress axis line
        axis.ticks = element_blank(), axis.title = element_blank(), #Suppress axis ticks and labels
        panel.grid.major = element_line(color = "white"), #Format background outline
        panel.background = element_rect(fill = "white")) + #Format backgound fill

  #Specify a manual color palette (this is APDE standard for CHI sequential color scale in maps)
  scale_fill_gradientn(
    colors = c("#f7fcfd", "#e0ecf4", "#bfd3e6", "#9ebcda", "#8c96c6", "#8c6bb1","#88419d", "#810f7c", "#4d004b"), #List colors
    space = "Lab", #Color space in which to calculate gradient, must be Lab
    na.value = "grey50", #Color NA values
    guide = 'colourbar', #Type of legend
    name = "Population") #Title of legend

  #Another example of a color palette from built-in Tableau options
  #scale_fill_gradient2_tableau(palette = "Classic Orange-Blue",  na.value = 'White', guide = 'colourbar', trans='reverse',
  #                           name = "Percentage") #Color scale, specifying white for suppressed areas

dev.new(width = 11, height = 8.5, unit = "in", noRStudioGD = TRUE)
plot(my.map1)


##Export map
ggsave(paste0("king_county_population_hra_2020_", gsub("-", "_", Sys.Date()), ".png"),
       plot = last_plot(), dpi=600, width = 11, height = 8.5, units = "in",
       path = localPath)
