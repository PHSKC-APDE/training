#RADS practice
#Analyzing CHARS data
#Ronald Buie, 2026-06-01

pacman::p_load(apde.data, data.table, dplyr, gh, gitcreds, ggplot2, ggrepel, ggthemes, keyring, lubridate, openxlsx, rads, rads.data, rstudioapi, sf, tidyverse, usethis)

#CHARS functions allow you to retrieve and analyze CHARS observations by ICD and CCSR classifications.

#let's start by pulling data and looking at what is returned.

charsDT <- apde.data::chars(year = 2021) #pull data from chars

dim(charsDT) # dimensions of the downloaded CHARS data.table object

names(charsDT)[1:6] # names of the first 6 columns

unique(charsDT$chi_geo_kc) # display unique values of the king count indicator to confirm data is limited to King County
unique(charsDT$zipcode)
unique(charsDT$chi_year) # display unique values of the year variable (which years do we have)

max(charsDT$chi_age, na.rm = T) # check that ages max to 100 (ADPE standard), na.rm will remove NA's from the calculation of the maximum. If you do not, you will receive NA, instead of anumber, if any.

#### viewing possible codes and descriptors ####

classifications <- chars_icd_ccs() #returns list of all descriptions

#note that each has the relevant icd code, a broad CCSR description, detailed CCSR description, and icd version. You can use any of these for aggregating with the below functions.
classifications[1:5]

classifications[icdcm_code == "I110",] #see information for a code of interest
classifications[broad == "Diseases of the digestive system",]

classifications[broad == "Diseases of the digestive system",]$icdcm_code #this would generate a list of which ICD10 codes are under the category for "Diseases of the digestive system"


#### getting CHARS counts ####

mycode <- chars_icd_ccs_count(ph.data = charsDT, icdcm = 'I110') #using our data, charsDT, we can specify a valid icd code to display how many observations meet the code
print(mycode)

mydesc <- chars_icd_ccs_count(ph.data = charsDT, icdcm = 'hypertensive heart disease with heart failure') #you can also use the description
print(mydesc)

broad <- chars_icd_ccs_count(ph.data = charsDT, broad = 'Diseases of the circulatory system') # and, similarly, by APDE's CCSR aligned broad descriptions
print(broad)

unique(classifications[broad == "Diseases of the circulatory system",]$detailed)

### listing injury options with  chars_injury_matrix() ###
injuries <- chars_injury_matrix()

injuries[1:10]

unique(injuries$intent) # see a list of the available intents

unique(injuries$mechanism) #Similarly, to see the available mechanisms

unique(injuries[intent == "assault",]$mechanism) #by specifying teh type of intent, you can see which mechanisms are available


### generate counts of injuries from our data

mat1 <- chars_injury_matrix_count(ph.data = charsDT,
                                  intent = 'assault',
                                  mechanism = 'none')
mat1


mat2 <- chars_injury_matrix_count(ph.data = charsDT,
                                  intent = 'assault|undetermined', #note you can use logic operators, such as OR used here.
                                  mechanism = 'none')
mat2


mat2.alt <- chars_injury_matrix_count(ph.data = charsDT,
                                      intent = c('assault', 'undetermined'), #will pull same results
                                      mechanism = 'none')

identical(mat2, mat2.alt)

## Specifying a single mechanism and ignoring the intent

mat3 <- chars_injury_matrix_count(ph.data = charsDT,
                                  intent = 'none',
                                  mechanism = 'motor_vehicle_traffic')

mat3

## What happens if you specify ‘none’ for both the mechanism and intent?

mat4 <- chars_injury_matrix_count(ph.data = charsDT,
                                  intent = 'none',
                                  mechanism = 'none')

## What happens if you don’t specify the mechanism and intent?

mat5 <- chars_injury_matrix_count(ph.data = charsDT)

## How different are the `narrow` and `broad` definitions?

mat6 <- chars_injury_matrix_count(ph.data = charsDT,
                                  intent = 'none',
                                  mechanism = 'none',
                                  def = 'narrow')

mat7 <- chars_injury_matrix_count(ph.data = charsDT,
                                  intent = 'none',
                                  mechanism = 'none',
                                  def = 'broad')

mat6

mat7

deftable <- rbind(cbind(def = 'narrow', mat6),
                  cbind(def = 'broad', mat7))

deftable #notice this is quite different. Happy to discuss, but basically you should be familiar with which AHRQ/CCSR and/or ICD classifications to use for your analysis, and be intentional about using the functions to aggregate correctly.

