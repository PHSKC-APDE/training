##RADS practice
##Setup for R/RADS practice##
##Eli Kern, June 2023

#### Setup ####

##Check to make sure your packages are being saved to your C drive
.libPaths() #1st entry should be a folder on your C drive (e.g., C:/Rpackages)
#If the 1st entry is not on your C drive, then follow instructions in R orientation slide deck to correct:
#https://tinyurl.com/zemwyucb

##Install RADS
remotes::install_github("PHSKC-APDE/rads", auth_token = NULL) #install RADS for the first time
remotes::update_packages("rads") #update RADS if it is out of date

##Install pacman packages for easier installation/loading of packages
install.packages("pacman")

##Load (or install) packages used for exercises
#Note that we will be using both tidyverse and data.table in these practice exercises
pacman::p_load(tidyverse, rads, rads.data, openxlsx2, data.table, lubridate, sf, ggrepel, ggthemes, keyring)

##Set defaults
options(max.print = 350, tibble.print_max = 50, scipen = 999)
origin <- "1970-01-01" # Date origin
export_path <- "C:/Users/kerneli/OneDrive - King County/" #replace with your desired path, use forward slashes

##Set keyring for HHSAW connection (only need to run this once initially or whenever password or laptop changes)
keyring::key_set('hhsaw', username = 'YOURUSERNAME@kingcounty.gov')

##Create a test file for export
test_df <- data.frame("col1" = 1, "col2" = 2, "col3" = 3)

##Export results to Excel, one dataframe per tab
data <- list(test_df)
sheet <- list("test_data")
filename <- paste0(export_path, "test_data.xlsx")
write_xlsx(data, file = filename, sheetName = sheet)