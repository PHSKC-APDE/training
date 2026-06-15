#RADS practice
#using KCGIS and making a map with zip code and non zip code data
#Ronald Buie, 2026-06-08

#Load packages and set defaults
pacman::p_load(apde.data, colorspace, data.table, dplyr, kcparcelpop,geojsonsf, gh, gitcreds, ggplot2, ggrepel, ggthemes, httr, jsonlite, keyring, lubridate, openxlsx, purrr, rads, rads.data, RColorBrewer, rstudioapi, scales, stringr, sf, spatagg,  tidyverse, usethis)

#create a map of zip codes with populations

#NOTE: normally it is advised to use census block as the geography for population counts. Here we use zip code areas solely for demonstration purposes.

#get populations
zip_pops <- apde.data::population(geo_type = "zip", kingco = F)
zip_pops[, `:=`(race_eth = NULL, gender = NULL, age = NULL, year = NULL, geo_type =NULL)]

#get a map of zip codes
url <- "https://services.arcgis.com/Ej0PsM5Aw677QF1W/arcgis/rest/services/ZIPCODE_AREA_113/FeatureServer/0/query?where=1%3D1&outFields=*&outSR=4326&f=geojson" #URL for API instructions to pull desired data from king county gis data catalog.
response <- httr::GET(url, httr::accept("application/geo+json")) #call api
gj_txt <- httr::content(response, as = "text", encoding = "UTF-8") #properly format return info
kcplus_zip_map <- geojsonsf::geojson_sf(gj_txt)  # extract and properly format data frame containing spacial information
#NOTE: if neecessary, you can also find a similar map in dphcifs: \\dphcifs\APDE-CDIP\Shapefiles\ZIP



#merge populations into the zip code DT
kcplus_zip_map <- merge(kcplus_zip_map, zip_pops, by.x = "ZIP", by.y = "geo_id", all.x = T)
kcplus_zip_map[is.na(kcplus_zip_map$pop),]$pop <- 0 # converting NA populations zips to 0's for future computation

#visual review
ggplot(kcplus_zip_map) +
  geom_sf(  size = 0.2, aes(fill = pop)) +
  coord_sf(datum = NA) +
  guides(fill = "none")

#get maps of KC cities and unincorporated areas using API
url <- "https://services.arcgis.com/Ej0PsM5Aw677QF1W/arcgis/rest/services/CITYDST_AREA_337/FeatureServer/0/query?where=1%3D1&outFields=*&outSR=4326&f=geojson"
resp <- httr::GET(url, httr::accept("application/geo+json"))
gj_txt <- httr::content(resp, as = "text", encoding = "UTF-8")
kc_city_map <- geojsonsf::geojson_sf(gj_txt)  # directly gets an sf data frame
#NOTE: if neecessary, you can also find a similar map in dphcifs: \\dphcifs\APDE-CDIP\Shapefiles\KC_Cities_And_Places & dphcifs: \\dphcifs\APDE-CDIP\Shapefiles\Incorp_Unincorp. You will need to merge these similar to the example here: https://github.com/PHSKC-APDE/data_request/blob/main/2023/04_2023/Poon_04_2023_unincorporated_ACS_estimates.R


ggplot(kc_city_map) +
  geom_sf(  size = 0.2) +
  coord_sf(datum = NA)

kcplus_zip_map = kcplus_zip_map |>
  st_transform(2926) |> # Convert to a western washington projection with units in survey feet (rather than decimal degrees)
  spatagg::reduce_overlaps() # tries to clean up the polygons, and if that fails makes a series of very minor negative buffers to elimate polygons from overlapping each other
kcplus_zip_map <- kcplus_zip_map |> group_by(ZIPCODE, pop) |> summarize() |> ungroup()


kc_city_map = kc_city_map |>
  st_transform(2926) |> # Convert to a western washington projection with units in survey feet (rather than decimal degrees)
  spatagg::reduce_overlaps() # tries to clean up the polygons, and if that fails makes a series of very minor negative buffers to elimate polygons from overlapping each other

#use spatagg to calculate the overlap of our zip code data (population) into our city geographies
zip_to_city_xwalk <- create_xwalk(source = kcplus_zip_map, target = kc_city_map, source_id = "ZIPCODE", target_id = "NAME",min_overlap = .03)

pop_by_city <- crosswalk(kcplus_zip_map, source_id = "ZIPCODE", est = "pop", proportion = FALSE, xwalk_df = zip_to_city_xwalk)

kc_city_map_with_pop <- merge(kc_city_map, pop_by_city, by.x = "NAME", by.y = "target_id")

kc_city_map_with_pop$est <- as.integer(kc_city_map_with_pop$est)

#visual review
ggplot(kc_city_map_with_pop) +
  geom_sf(size = 0.2 ,aes(fill = est)) +
  scale_fill_continuous(labels = label_number(accuracy = 1)) + #an adjustment using the scales package to show whole numbers instead of scientific notation
  labs(fill = "Population") +
  ggtitle("Populations of the Cities and unincorporated King County")
