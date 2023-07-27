##RADS practice
##Exploring the get_population function##
##Eli Kern, March 2023

#### Setup ####

## Script organization tip - Any comment followed by #### or ---- will appear in the navigation menu
## And you can collapse these sections with Alt-o or expand with Shift-Alt-o

##Install RADS
#remotes::install_github("PHSKC-APDE/rads", auth_token = NULL) # Install RADS for the first time
remotes::update_packages("rads") # Update RADS if it is out of date

##Load packages and set defaults
pacman::p_load(tidyverse, rads, rads.data, openxlsx2) # Load list of packages
options(max.print = 350) # Limit # of rows to show when printing/showing a data.frame
options(tibble.print_max = 50) # Limit # of rows to show when printing/showing a tibble (a tidyverse-flavored data.frame)
options(scipen = 999) # Avoid scientific notation
origin <- "1970-01-01" # Set the origin date, which is needed for many data/time functions
export_path <- "C:/Users/REPLACE WITH YOUR USER NAME/OneDrive - King County/" # Replace with your desired path, use forward slashes

##Set keyring for HHSAW connection (only need to run this when password or laptop changes)
#keyring::key_set('hhsaw', username = 'REPLACE THIS TEXT WITH YOUR EMAIL ADDRESS')
keyring::key_list() #Command to show list of keys saved on your computer/account


#### Question 1-1: Comparing populations ####
## In 2019-2020, among people age 18-64, how did the percentage of population that was Asian compare between King County and WA State?

##WA population, age 18-64, 2019-20
wa_pop <- get_population(
  years = 2019:2020,
  ages = 18:64,
  geo_type = 'wa'
)

##WA population, age 18-64, by race_eth, 2019-20
wa_pop_raceeth <- get_population(
  years = 2019:2020,
  ages = 18:64,
  geo_type = 'wa',
  race_type = c("race_eth"),
  group_by = "race_eth"
)

##KC population, age 18-64, 2019-20
kc_pop <- get_population(
  kingco = TRUE,
  years = 2019:2020,
  ages = 18:64,
  geo_type = 'kc'
)

##KC population, age 18-64, 2019-20
kc_pop_raceeth <- get_population(
  kingco = TRUE,
  years = 2019:2020,
  ages = 18:64,
  geo_type = 'kc',
  race_type = c("race_eth"),
  group_by = "race_eth"
)

##Percentage of KC population 2019-20 age 18-64 that was Asian
#Note we are using the round2 function from RADS so that numbers are rounded like we learned in school (e.g., 0.5 -> 1)
rads::round2(kc_pop_raceeth$pop[kc_pop_raceeth$race_eth == "Asian"] / kc_pop$pop[kc_pop$geo_type == "kc"] * 100, 1)

##Percentage of WA population 2019-20 age 18-64 that was Asian
rads::round2(wa_pop_raceeth$pop[wa_pop_raceeth$race_eth == "Asian"] / wa_pop$pop[wa_pop$geo_type == "wa"] * 100, 1)

##Stack KC and WA results as one data frame
kc_pop_final <- bind_rows(kc_pop, kc_pop_raceeth)
wa_pop_final <- bind_rows(wa_pop, wa_pop_raceeth)

##Export results to Excel, one dataframe per tab
data <- list(kc_pop_final, wa_pop_final) #This list specifies what data.frames to write to Excel tabs
sheet <- list("kc_pop_final", "wa_pop_final") #This list specifies the names of the Excel tabs
filename <- paste0(export_path, "get_population_results.xlsx") #This command specifies the path and name of the file
write_xlsx(data, file = filename, sheetName = sheet) #This command exports the data to Excel using above parameters


#### Question 1-2: Population changes over time ####
## From 2010-2020, how did population change by broad age group (0-17, 18-64, 65+) for ZIP code 98109 (South Lake Union)?

##Query data
zip_pop <- get_population(
  kingco = TRUE,
  years = 2010:2020,
  geo_type = 'zip',
  group_by = c("years", "ages") 
)

##Sum population counts by custom age groups
zip_pop_age <- zip_pop %>%
  
  #Create custom age groups
  mutate(age_grp = case_when(
    between(age, 0, 17) ~ "0-17",
    between(age, 18, 39) ~ "18-39",
    between(age, 40, 64) ~ "40-64",
    age >= 65 ~ "65 and older",
    TRUE ~ NA_character_)
  ) %>%
  
  #Group by year, geography and age group
  group_by(geo_id, year, age_grp) %>%
  
  #Create new variable to hold pop totals
  mutate(pop_sum = sum(pop, na.rm = T)) %>%
  ungroup() %>%
  
  #Collapse data frame to distinct rows at age group level
  distinct(pop_sum, geo_type, geo_id, year, age_grp)

##Graph ZIP code 98109 on line graph using ggplot, using a different line color for each age group
my.chart1 <- ggplot(
  data = filter(zip_pop_age, geo_id == "98109"), #Identify the data and filter to the desired ZIP code
  aes(x=year, y=pop_sum, group=age_grp)) + #Map columns to graphing concepts - axes and groups
  geom_line(aes(color=age_grp)) + #Add lines and color by age group
  geom_point(aes(color=age_grp)) #Add points and color by age group

plot(my.chart1) #Chart will appear in plot window. Hint - click Zoom to pop out chart for full-screen view.

#Alternatively, you can set up a new window for plotting the graph to show what it will look like when exported
dev.new(width = 11, height = 8.5, unit = "in", noRStudioGD = TRUE)
plot(my.chart1)

##Export graph to folder
ggsave(
  paste0("pop_changes_by_age_zip98109_", gsub("-", "_", Sys.Date()), ".png"),
  plot = last_plot(),
  dpi=600, width = 11, height = 8.5, units = "in",
  path = export_path)