#RADS practice
#Analyzing birth data
#Ronald Buie, 2026-06-01

pacman::p_load(apde.data, data.table, dplyr, gh, gitcreds, ggplot2, ggrepel, ggthemes, keyring, lubridate, openxlsx, rads, rads.data, rstudioapi, sf, tidyverse, usethis)

localPath <- dirname(rstudioapi::getActiveDocumentContext()$path) #getActiveDocumentContext pulls the full path of the script it is ran from. dirname extracts the directtory from a given path, removing the file name at the end. We save this to get the directory for this user/instance.

#You can view the columns available for a data set by using the list_dataset_columns function and specifying the desired data set
cols_from_birth_data <- apde.data::list_data_columns("birth")

#For this example, we want to explore the rate of preterm births in King County

#pull relevant birth records from the data warehouse
birth <- apde.data::birth(cols = c("chi_year", "chi_sex", "chi_race_eth8",
                                 "preterm", "birth_weight_grams", "mother_birthplace_state"),
                        year = c(2013:2019),
                        kingco = T)

#calculate the rate or preterm births within the sampled population
rads::calc(ph.data = birth,
     what = c("preterm"),
     metrics = c("mean", "rse", "numerator", "denominator"),
     time_var = "chi_year")[]

#the rADS::calc function can be used to rapidly explore other dimensions of your data.
#miscillanious varibales can be specified by providing a logic evaluation statemet to the "where" parameter
rads::calc(ph.data = birth,
     what = c("preterm"),
     where = chi_sex == "Male",
     metrics = c("mean", "rse", "numerator", "denominator"),
     time_var = "chi_year")[]

#multiple statements can be linked with additional logic operators
rads::calc(ph.data = birth,
     what = c("preterm"),
     where = chi_sex == "Male" & chi_race_eth8 == "Hispanic",
     metrics = c("mean", "rse", "numerator", "denominator"),
     time_var = "chi_year")[]

#by specifying a group-by variable, we can create sub clusters. In this case, we want to view the results per-year
rads::calc(ph.data = birth,
     what = c("preterm"),
     metrics = c("mean", "rse", "numerator", "denominator"),
     time_var = "chi_year",
     by = "chi_year")[]

#notice, this will throw an error.
#Calc does not allow you to reuse your time variable, and instructs you to copy it to an additional variable instead.
birth$cy <- birth$chi_year #base R approach
birth[,"cy"] <- birth[,chi_year] #also base R
birth[, cy := chi_year] #DT approach

#now we should use this new variable in the "by" parameter
rads::calc(ph.data = birth,
     what = c("preterm"),
     metrics = c("mean", "rse", "numerator", "denominator"),
     time_var = "chi_year",
     by = "cy")[]

#In reality, if you want to view per-year results, you can use the "win"dow parameter to specify 1 year windows
rads::calc(ph.data = birth,
     what = c("preterm"),
     metrics = c("mean", "rse", "numerator", "denominator"),
     time_var = "chi_year",
     win = 1)[]

#or more
rads::calc(ph.data = birth,
     what = c("preterm"),
     metrics = c("mean", "rse", "numerator", "denominator"),
     time_var = "chi_year",
     win = 3)[]

#preterm is a categorical, binary, variable. Let's use birth_weight_grams to see results on a continuous variable
rads::calc(ph.data = birth,
     what = c("birth_weight_grams"),
     metrics = c("mean", "rse"),
     time_var = "chi_year",
     win = 3)[]

#combing the above techniques, we can ask specific questions of our data
#"What is the mean birth weight for males and females of different races?"
rads::calc(ph.data = birth,
     what = c("birth_weight_grams"),
     chi_year == 2019,
     metrics = c("mean", "rse"),
     by = c("chi_race_eth8", "chi_sex"))[]

#what about mean birth weight for each gender and preterm status?
rads::calc(ph.data = birth,
     what = c("birth_weight_grams"),
     chi_year == 2019,
     metrics = c("mean", "rse"),
     by = c("chi_race_eth8", "chi_sex", "preterm"))[]
#note the warning that NA's were introduced. This is likely due to preterm not being available for some observations.
#we can see these by singling out the preterm bivariate
rads::calc(ph.data = birth,
     what = c("preterm"),
     chi_year == 2019,
     metrics = c("mean", "rse"),
     by = c("chi_sex"))[]

#"how many birth were there between 2017 and 2019 for each race?"
rads::calc(ph.data = birth,
     what = c("chi_race_eth8"),
     chi_year %in% 2017:2019,
     metrics = c("mean", "rse", "numerator", "denominator"))[] #note the numerator statistic is our answer

#"what are the rates of these births?"
rads::calc(ph.data = birth,
     what = c("chi_race_eth8"),
     chi_year %in% 2017:2019,
     metrics = c("obs", "numerator", "denominator", "rate"),
     per = 100000)[] #per will additionally report a standardized rate

