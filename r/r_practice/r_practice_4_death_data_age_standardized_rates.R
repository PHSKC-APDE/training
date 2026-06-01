#RADS practice
#Analyzing death data using age-standardized rates
#Ronald Buie, 2026-06-01

pacman::p_load(apde.data, data.table, dplyr, gh, gitcreds, ggplot2, ggrepel, ggthemes, keyring, lubridate, openxlsx, rads, rads.data, rstudioapi, sf, tidyverse, usethis)

localPath <- dirname(rstudioapi::getActiveDocumentContext()$path) #getActiveDocumentContext pulls the full path of the script it is ran from. dirname extracts the directtory from a given path, removing the file name at the end. We save this to get the directory for this user/instance.

#For this analysis, we will calculate the age-adjusted mortality rate for deaths by falling in the years 2016 through 2020, stratified by the intention in death (i.e. suicide, homicide, accident, ect...).

#step 1, generate numerators of deaths by age and type

#You can view the columns available for a data set by using the list_dataset_columns function and specifying the desired data set
deat_data_column_names <- apde.data::list_data_columns("death")

#Pull data using RADS::get_data_death
#note that get_data_death is the same as get_data with the dataset = "death"
individual.deaths <- apde.data::death(cols = c('chi_age',
                                  'chi_year',
                                  'underlying_cod_code'),
                         year = c(2016:2020),
                         kingco = T)

names(individual.deaths) #print the names of the variables in our new data.tabe (DT)

#we now want to turn these individual decedent observations into totals of death by type and age.
#We can use the rads::death_injury_matrix_count() function to do this
aggregate.deaths <- rads::death_injury_matrix_count(ph.data = individual.deaths,
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
population <- apde.data::population(years = c(2016:2020),
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




