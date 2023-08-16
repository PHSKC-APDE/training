##RADS practice
##Make a map (extra credit)##
##Eli Kern, June 2023

#### Setup ####

##Install RADS
#remotes::install_github("PHSKC-APDE/rads", auth_token = NULL) #install RADS for the first time
remotes::update_packages("rads") #update RADS if it is out of date

##Load packages and set defaults
pacman::p_load(tidyverse, rads, rads.data, openxlsx2, sf, data.table, ggrepel, ggthemes) # Load list of packages
options(max.print = 350) # Limit # of rows to show when printing/showing a data.frame
options(tibble.print_max = 50) # Limit # of rows to show when printing/showing a tibble (a tidyverse-flavored data.frame)
options(scipen = 999) # Avoid scientific notation
origin <- "1970-01-01" # Set the origin date, which is needed for many data/time functions
export_path <- "C:/Users/REPLACE WITH YOUR USER NAME/OneDrive - King County/" #replace with your desired path, use forward slashes


##Goal: Make an HRA-based map of smoking during pregnancy for the most recent 10-year period

##Load birth data for 2012-2021
birth <- get_data_birth(cols = c("chi_year", "smoking_dur", "chi_geo_hra2020_id", "chi_geo_hra2020_name"), 
                        year = c(2012:2021), 
                        kingco = T)

##Use calc to generate proportion of births where mother smoked during pregnancy, by HRA
results <- calc(ph.data = birth, 
     what = c("smoking_dur"), 
     metrics = c("mean", "rse", "numerator", "denominator"),
     by = c("chi_geo_hra2020_id", "chi_geo_hra2020_name"),
     time_var = "chi_year")

##Convert proportions to percentages, and suppress small numbers per APDE guidelines (i.e., 1-9)
results <- results %>%
  mutate(
    
    #Suppress mean for any rows where numerator between 1 and 9
    mean = case_when(
      between(numerator, 1, 9) ~ NA_real_,
      TRUE ~ mean),
    
    #Make percentage variables (note you can also do this within chart creation script)
    mean_percent = rads::round2(mean*100,1),
    mean_lower_percent = rads::round2(mean_lower*100,1),
    mean_upper_percent = rads::round2(mean_upper*100,1))

##Remove result(s) row for null HRAs (births that could not be geocoded)
results <- filter(results, !is.na(chi_geo_hra2020_id))

##Load HRA shapefile
hra2020 <- st_read("\\\\dphcifs/apde-cdip/shapefiles/hra/hra_2020_nowater.shp")
city <- st_read("\\\\gisdw/kclib/Plibrary2/census/shapes/polygon/place10.shp")

##Merge birth results dataset with HRA shapefile
map <- merge(results, hra2020, by.x = "chi_geo_hra2020_id", by.y = "id", all.x = T, all.y = F)

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

##Set up map for plotting
#The order of data layers is important because they are stacked on top of each other
my.map1 <- ggplot() + 
  geom_sf(data = hra2020, fill = 'White', color = NA) + #White color for water and other blank areas, no outline
  geom_sf(data = map, aes(fill=mean_percent)) + #Color HRAs according to mean_percent
  geom_sf(data = hra2020, fill = NA, size = 1, color = 'black') + #Black outlines for HRAs
  geom_label(data = centroids, aes(x=X, y=Y, label = as.character(NAME10)), size = 5, color = 'Black',
             label.padding = unit(0.1, "lines")) + #Labels for cities of interest
  geom_label_repel()+ #Ask labels to avoid overlapping
  
  labs(title = "Percentage of births where mother smoked during pregnancy, by King County HRA, 2012-2021 average") +
  
  theme(plot.title = element_text(color = "black", size = 16, face = "bold"), #Format title
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
    name = "Percentage") #Title of legend
  
  #Another example of a color palette from built-in Tableau options
  #scale_fill_gradient2_tableau(palette = "Classic Orange-Blue",  na.value = 'White', guide = 'colourbar', trans='reverse',
  #                           name = "Percentage") #Color scale, specifying white for suppressed areas

dev.new(width = 11, height = 8.5, unit = "in", noRStudioGD = TRUE)
plot(my.map1)


##Export map
ggsave(paste0("smoking_during_pregnancy_hra_2012-2021_", gsub("-", "_", Sys.Date()), ".png"),
       plot = last_plot(), dpi=600, width = 11, height = 8.5, units = "in",
       path = export_path)