##RADS practice
##Analyzing death data using age-standardized rates##
##Eli Kern, June 2023

#### Setup ####

##Install RADS
#remotes::install_github("PHSKC-APDE/rads", auth_token = NULL) #install RADS for the first time
remotes::update_packages("rads") #update RADS if it is out of date

##Load packages and set defaults
pacman::p_load(tidyverse, rads, rads.data, openxlsx2) # Load list of packages
options(max.print = 350) # Limit # of rows to show when printing/showing a data.frame
options(tibble.print_max = 50) # Limit # of rows to show when printing/showing a tibble (a tidyverse-flavored data.frame)
options(scipen = 999) # Avoid scientific notation
origin <- "1970-01-01" # Set the origin date, which is needed for many data/time functions
export_path <- "C:/Users/kerneli/OneDrive - King County/" #replace with your desired path, use forward slashes

##Set keyring for HHSAW connection (only need to run this when password or laptop changes)
#keyring::key_set('hhsaw', username = 'eli.kern@kingcounty.gov')

##Copy code from existing vignette at: https://github.com/PHSKC-APDE/rads/wiki/calculating_rates_with_rads