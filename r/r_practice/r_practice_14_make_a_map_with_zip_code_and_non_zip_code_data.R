#RADS practice
#using KCGIS and making a map with zip code and non zip code data
#Ronald Buie, 2026-06-08

#Load packages and set defaults
pacman::p_load(apde.data, colorspace, data.table, dplyr, kcparcelpop,geojsonsf, gh, gitcreds, ggplot2, ggrepel, ggthemes, httr, jsonlite, keyring, lubridate, openxlsx, purrr, rads, rads.data, RColorBrewer, rstudioapi, stringr, sf, spatagg,  tidyverse, usethis, viridisLite)

#create a map of zip codes with populations

#get populations
zip_pops <- apde.data::population(geo_type = "zip", kingco = F)
zip_pops[, `:=`(race_eth = NULL, gender = NULL, age = NULL, year = NULL, geo_type =NULL)]

#get a map of zip codes
url <- "https://services.arcgis.com/Ej0PsM5Aw677QF1W/arcgis/rest/services/ZIPCODE_AREA_113/FeatureServer/0/query?where=1%3D1&outFields=*&outSR=4326&f=geojson" #URL for API instructions to pull desired data from king county gis data catalog.
response <- httr::GET(url, httr::accept("application/geo+json")) #call api
gj_txt <- httr::content(response, as = "text", encoding = "UTF-8") #properly format return info
kcplus_zip_map <- geojsonsf::geojson_sf(gj_txt)  # extract and properly format data frame containing spacial information

#merge populations into the zip code DT
kcplus_zip_map <- merge(kcplus_zip_map, zip_pops, by.x = "ZIP", by.y = "geo_id", all.x = T)
test <- kcplus_zip_map[kcplus_zip_map$COUNTY == "033",]

#visual review
ggplot(kcplus_zip_map) +
  geom_sf(  size = 0.2, aes(fill = pop)) 
  coord_sf(datum = NA) +
  guides(fill = "none") 

#get maps of KC cities and unincorporated areas using API
url <- "https://services.arcgis.com/Ej0PsM5Aw677QF1W/arcgis/rest/services/CITYDST_AREA_337/FeatureServer/0/query?where=1%3D1&outFields=*&outSR=4326&f=geojson"
resp <- httr::GET(url, httr::accept("application/geo+json"))
gj_txt <- httr::content(resp, as = "text", encoding = "UTF-8")
kc_city_map <- geojsonsf::geojson_sf(gj_txt)  # directly gets an sf data frame

ggplot(kc_city_map) +
  geom_sf(  size = 0.2) +
  coord_sf(datum = NA) 

#use spatagg to calculate the overlap of our zip code data (population) into our city geographies
test <- create_xwalk(source = kcplus_zip_map, target = kc_city_map, source_id = "ZIPCODE", target_id = "NAME")
