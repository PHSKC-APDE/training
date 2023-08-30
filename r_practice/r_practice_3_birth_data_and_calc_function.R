##RADS practice
##Analyzing birth data##
##Ronald Buie, Aug 2023



#### Background ####
#The following is an R script introducing users to a basic analysis of APDE data.
#It is part of a larger set of training resources that can be found here: <link to training github>
#
#This vignette relies on our in-house analytics package "R Analytics "R Automatic Data System" or RADS. You can find RADS and installation instructions here: <link to RADS repository
#
#This vignette assumes you have access to the necessary data. If you do not, or are not sure, please reach out to your manager.
#
#A recorded presentation of this script, with audience Q/A can be found here:
#
#This script walks through how to access death data and perform an age standardized calculation using RADS
#
#Based on vignette found at https://github.com/PHSKC-APDE/rads/wiki/calc#example-vital-statistics-analyses
#
#More about birth data: https://github.com/PHSKC-APDE/DOHdata/tree/main/ETL/birth
#
#Data dictionary for birth can be found here: https://github.com/PHSKC-APDE/DOHdata/blob/main/ETL/birth/ref/ref_bir_user_dictionary_final.csv



#### Setup ####

##Load packages and set defaults
pacman::p_load(data.table) # Load list of packages
library(rads) #if rads is not installed, pacman cannot auto install it for you. Loading it separately will make any error easier to see.
##Install or update RADS if not already insatlled
#remotes::install_github("PHSKC-APDE/rads", auth_token = NULL) #install RADS for the first time
#remotes::update_packages("rads") #update RADS if it is out of date
library(rads.data) #if rads.data is not installed, pacman cannot auto install it for you

##Set environment options
options(max.print = 350) # Limit # of rows to show when printing/showing a data.frame
options(tibble.print_max = 50) # Limit # of rows to show when printing/showing a tibble (a tidyverse-flavored data.frame)
options(scipen = 999) # Avoid scientific notation
origin <- "1970-01-01" # Set the origin date, which is needed for many data/time functions
export_path <- "C:/Users/REPLACE WITH YOUR USER NAME/OneDrive - King County/" #replace with your desired path, use forward slashes



#### Vignette ####

#You can view the columns available for a data set by using the list_dataset_columns function and specifying the desired data set
x <- rads::list_dataset_columns("birth")

#For this example, we want to explore the rate of preterm births in King County

#pull relevant birth records from the data warehouse
birth <- get_data_birth(cols = c("chi_year", "chi_sex", "chi_race_eth8",
                                 "preterm", "birth_weight_grams", "mother_birthplace_state"),
                        year = c(2013:2019),
                        kingco = T)

#calculate the rate or preterm births within the sampled population
calc(ph.data = birth,
     what = c("preterm"),
     metrics = c("mean", "rse", "numerator", "denominator"),
     time_var = "chi_year")[]

#the rADS::calc function can be used to rapidly explore other dimensions of your data.
#miscillanious varibales can be specified by providing a logic evaluation statemet to the "where" parameter
calc(ph.data = birth,
     what = c("preterm"),
     where = chi_sex == "Male",
     metrics = c("mean", "rse", "numerator", "denominator"),
     time_var = "chi_year")[]

#multiple statements can be linked with additional logic operators
calc(ph.data = birth,
     what = c("preterm"),
     where = chi_sex == "Male" & chi_race_eth8 == "Hispanic",
     metrics = c("mean", "rse", "numerator", "denominator"),
     time_var = "chi_year")[]

#by specifying a group-by variable, we can create sub clusters. In this case, we want to view the results per-year
calc(ph.data = birth,
     what = c("preterm"),
     metrics = c("mean", "rse", "numerator", "denominator"),
     time_var = "chi_year",
     by = "chi_year")[]

#notice, this will throw an error. Calc does not allow you to reuse your time variable, and instructs you to copy it to an additional variable instead.
birth$cy <- birth$chi_year #base R approach
birth[,"cy"] <- birth[,chi_year] #also base R
birth[, cy := chi_year] #DT approach

#now we should use this new variable in the "by" parameter
calc(ph.data = birth,
     what = c("preterm"),
     metrics = c("mean", "rse", "numerator", "denominator"),
     time_var = "chi_year",
     by = "cy")[]

#In reality, if you want to view per-year results, you can use the "win"dow parameter to specify 1 year windows
calc(ph.data = birth,
     what = c("preterm"),
     metrics = c("mean", "rse", "numerator", "denominator"),
     time_var = "chi_year",
     win = 1)[]

#or more
calc(ph.data = birth,
     what = c("preterm"),
     metrics = c("mean", "rse", "numerator", "denominator"),
     time_var = "chi_year",
     win = 3)[]

#preterm is a categorical, binary, variable. Let's use birth_weight_grams to see results on a continuous variable
calc(ph.data = birth,
     what = c("birth_weight_grams"),
     metrics = c("mean", "rse"),
     time_var = "chi_year",
     win = 3)[]

#combing the above techniques, we can ask specific questions of our data
#"What is the mean birth weight for males and females of different races?"
calc(ph.data = birth,
     what = c("birth_weight_grams"),
     chi_year == 2019,
     metrics = c("mean", "rse"),
     by = c("chi_race_eth8", "chi_sex"))[]

#"how many birth were there between 2017 and 2019 for each race?"
calc(ph.data = birth,
     what = c("chi_race_eth8"),
     chi_year %in% 2017:2019,
     metrics = c("mean", "rse", "numerator", "denominator"))[] #note the numerator statistic is our answer

#"what are the rates of these births?"
calc(ph.data = birth,
     what = c("chi_race_eth8"),
     chi_year %in% 2017:2019,
     metrics = c("obs", "numerator", "denominator", "rate"),
     per = 100000)[] #per will additionally report a standardized rate

#"what is the count, and proportion, of observations missing a gender in our data?"
calc(ph.data = birth,
     what = c("chi_sex"),
     chi_year %in% 2017:2019,
     metrics = c("obs", "missing", "missing.prop"),
     by = "chi_year")[]

