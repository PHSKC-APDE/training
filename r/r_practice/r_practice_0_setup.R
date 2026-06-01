#RADS practice
#Setup and introduction for R/RADS practice
#Ronald Buie, 2026-06-01

#### Background ####
# The r scripts and markdown/querto files in this directory introduce users to a basic analysis of APDE data.
#
# These vignettes relies on our in-house analytics packages, including RADS and apde.data. Please find them in the respectively named apde git repositories: https://github.com/PHSKC-APDE/rads and https://github.com/PHSKC-APDE/apde.data
#
# Several of these vignettes assume you have access to the necessary data. If you do not, or are not sure, please reach out to your manager.

#### Setup ####

##Check to make sure your packages are being saved to your C drive
.libPaths() #1st entry should be a folder on your C drive (e.g., C:/Rpackages)
#If the 1st entry is not on your C drive, then follow instructions in R orientation slide deck to correct:
#https://tinyurl.com/zemwyucb

##Install RADS
remotes::install_github("PHSKC-APDE/rads", auth_token = NULL) #install RADS for the first time
remotes::update_packages("rads") #update RADS if it is out of date
remotes::install_github("PHSKC-APDE/apde.data")

##Install pacman packages for easier installation/loading of packages
install.packages("pacman")

##Load (or install) packages used for exercises
#Note that we will be using both tidyverse and data.table in these practice exercises
pacman::p_load(apde.data, data.table, dplyr, gh, gitcreds, ggplot2, ggrepel, ggthemes, keyring, lubridate, openxlsx, rads, rads.data, rstudioapi, sf, tidyverse, usethis)

##Set defaults
#options(max.print = 350, tibble.print_max = 50, scipen = 999) #these are popular with some people, for some reason...
origin <- "1970-01-01" # Date origin

localPath <- dirname(rstudioapi::getActiveDocumentContext()$path) #getActiveDocumentContext pulls the full path of the script it is ran from. dirname extracts the directtory from a given path, removing the file name at the end. We save this to get the directory for this user/instance.

##Set keyring for HHSAW connection (only need to run this once initially or whenever password or laptop changes)
keyring::key_set('hhsaw', username = 'REPLACE THIS TEXT WITH YOUR EMAIL ADDRESS')
keyring::key_set('sharepoint', username = 'REPLACE THIS TEXT WITH YOUR EMAIL ADDRESS')

##Create a test file for export
test_df <- data.frame("col1" = 1, "col2" = 2, "col3" = 3)

##Export results to Excel, one dataframe per tab
data <- list(test_df)
sheet <- list("test_data")
filename <- paste0(export_path, "test_data.xlsx")
openxlsx::write.xlsx(data, file = filename, sheetName = sheet)
