##RADS practice
##Analyzing birth data##
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
export_path <- "C:/Users/REPLACE WITH YOUR USER NAME/OneDrive - King County/" #replace with your desired path, use forward slashes

##Copy code from existing vignette at: https://github.com/PHSKC-APDE/rads/wiki/calc#example-vital-statistics-analyses

##Additional guidance on exploring columns available in the birth analytic dataset
x <- rads::list_dataset_columns("birth")

#Data dictionary for birth data can be viewed on APDE's GitHub DOHdata repo at:
#https://github.com/PHSKC-APDE/DOHdata/blob/main/ETL/birth/ref/ref_bir_user_dictionary_final.csv

#Loading the entire birth dataset into R can take a long time (as it is large) and thus it is good practice to load
  #just the columns you need