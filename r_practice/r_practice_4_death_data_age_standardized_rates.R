##RADS practice
##Analyzing death data using age-standardized rates##
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
#You can find this, and the rest of our training scripts at https://github.com/PHSKC-APDE/R_training/tree/main/r_practice
#
#Based on vignette found at https://github.com/PHSKC-APDE/rads/wiki/calculating_rates_with_rads
#
#More about age_standardize() https://github.com/PHSKC-APDE/rads/wiki/age_standardize
#
#Other death functions: https://github.com/PHSKC-APDE/rads/wiki/death_functions
#

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

#For this analysis, we will calculate the age-adjusted mortality rate for deaths by falling in the years 2016 through 2020, stratified by the intention in death (i.e. suicide, homicide, accident, ect...).

#step 1, generate numerators of deaths by age and type

#You can view the columns available for a data set by using the list_dataset_columns function and specifying the desired data set
columns <- rads::list_dataset_columns("death")

#Pull data using RADS::get_data_death
#note that get_data_death is the same as get_data with the dataset = "death"
individual.deaths <- rads::get_data_death(cols = c('chi_age',
                                  'chi_year',
                                  'chi_geo_seattle',
                                  'underlying_cod_code'),
                         year = c(2016:2020),
                         kingco = T)

names(individual.deaths) #print the names of the variables in our new data.tabe (DT)

#we now want to turn these individual decedent observations into totals of death by type and age.
#We can use the rads::death_injury_matrix_count() function to do this
aggregate.deaths <- death_injury_matrix_count(ph.data = individual.deaths,
                    intent = "*", #will capture all 5 intents
                    mechanism = "fall",
                    icdcol = "underlying_cod_code",
                    kingco = F, #because our data are already subset, we do not need the function to do this for us
                    group_by = "chi_age")


head(aggregate.deaths) #print the first few entries in our DT
head(aggregate.deaths[deaths > 9,]) #same as the above line, but first, subset the data to only include those with more than 9 deaths, our APDE suppression threshold when reporting counts.

#next, we want to rename variables to align with our population step later
aggregate.deaths <- aggregate.deaths[, .(intent, age = chi_age, count = deaths)] #create the variables "age" and "count" and assign them the values currently in "chi_age" and "deaths" respectively. Overwrite our original DT with the results. We also are droping the "mechanism" variable, as this is not a variable used in our analyses (we just wanted to only include falls).
head(aggregate.deaths[count >9])


##step 2 generate matching denominators

#we can use rads::get_population to pull relevant denominators. Because our analysis is by age, we should include this in the group_by variable
# this will return a table with the total population unique people in king county , for each age 0-100, from the years 2016 to 2020
population <- rads::get_population(years = c(2016:2020),
                                   geo_type = 'kc',
                                   group_by = c('ages'))
head(population)

#let's drop unnecessary variables by overwriting our population DT with one that contains only the variables we want.
population <- population[, .(age, pop)]
head(population)

#Our next step will be to merge our denominator and numerators into a single DT. Because our numerators are further stratified by intention in their death, we will merge these tables by both age AND intention. This code replicates our 101 ages-populations 5 times, adding an intent category for each set of 101 age-populations
#we need to perform this for each strata of intention
#
population.with.intents <- rbindlist(lapply(X = 1:length(unique(aggregate.deaths$intent)), #loop through a list of integers, 1 to the number of levels of intent and combine all results into population.with.intents
                               FUN = function(X){ #pass the current integer to the below function
                                 temp <- copy(population)[, intent := unique(aggregate.deaths$intent)[X]] #use the integer as an index to assign the indexed intent to our populations
                               }))

#lapply is very fast, but can be difficult to read. For loops are somewhat slow in R, but easier to read.
#this loop does the same thing as the lapply function above
for(intentIndex in 1:length(unique(aggregate.deaths$intent))) { #loop through a list of integers, 1 to the number of levels of intent
  temp <- copy(population)[, intent := unique(aggregate.deaths$intent)[intentIndex]] #use the integer as an index to assign the indexed intent to our populations
  if(exists("population.with.intents.2")) { #combine results into population.with.intents.2
    population.with.intents.2 <- rbind(temp,population.with.intents.2) #if population.with.intents.2 exists, add to it
  } else{
    population.with.intents.2 <- temp #if it doesn't exists, use teh current temp result to create it
  }
}

#confirm that we have created the same data set twice
identical(population.with.intents[order(pop, intent),], population.with.intents.2[order(pop, intent),])

head(population.with.intents)
population.with.intents[, .N, intent] # confirm that have 101 rows per intent by showing total observations per intent


#Step 3, combine numerators and denominators into one DT


deaths.with.denominators <- merge(aggregate.deaths,
                population.with.intents,
                by = c('age', 'intent'),
                all.x = F, # drop if death strata do not match a population
                all.y = T) # keep population data if do not have deaths
deaths.with.denominators[is.na(count), count := 0] # formally set rows with zero counts to zero
head(deaths.with.denominators[count > 9]) # only display non-suppressed data


#Step 4 standardize ages using rads::age_standardize()
#
#we can use rads::age_standardize to simplify our age adjustments.
est <- rads::age_standardize(ph.data = deaths.with.denominators, # our prepared data set
                       ref.popname = "2000 U.S. Std Population (11 age groups)", #the reference population, see documentation for list of options
                       collapse = T,
                       my.count = 'count',
                       my.pop = 'pop',
                       per = 100000,
                       conf.level = 0.95,
                       group_by = 'intent')
head(est)




