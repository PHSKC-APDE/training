##RADS practice
##Analyzing CHARS data##
##Ronald Buie, Dec 2023


#### Background ####
# The following is an R script introducing users to a basic analysis of APDE CHARS data. It walks through how to access CHARS data and perform some of our routine analyses.
#
# It is part of a larger set of training resources that can be found here: https://github.com/PHSKC-APDE/R_training
#
# This vignette relies on our in-house analytics package "R Analytics "R Automatic Data System" or RADS. You can find RADS and installation instructions here: <link to RADS repository
#
# This vignette assumes you have access to the necessary data. If you do not, or are not sure, please reach out to your manager.
#
# A recorded presentation of this script, with audience Q/A can be found here:
#
# You can find this, and the rest of our training scripts at https://github.com/PHSKC-APDE/R_training/tree/main/r_practice
#
# Based on vignette found at https://github.com/PHSKC-APDE/rads/wiki/chars_functions


#### Setup ####

##Install RADS
#remotes::install_github("PHSKC-APDE/rads", auth_token = NULL) #install RADS for the first time
remotes::update_packages("rads") #update RADS if it is out of date

##Load packages and set defaults
pacman::p_load(data.table, rads, rads.data, openxlsx) # Load list of packages
options(max.print = 350) # Limit # of rows to show when printing/showing a data.frame
options(tibble.print_max = 50) # Limit # of rows to show when printing/showing a tibble (a tidyverse-flavored data.frame)
options(scipen = 999) # Avoid scientific notation
origin <- "1970-01-01" # Set the origin date, which is needed for many data/time functions


