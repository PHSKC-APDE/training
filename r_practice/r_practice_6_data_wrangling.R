##RADS practice
##Data wrangling##
##Eli Kern, June 2023

#### Setup ####

##Install RADS
#remotes::install_github("PHSKC-APDE/rads", auth_token = NULL) #install RADS for the first time
remotes::update_packages("rads") #update RADS if it is out of date

##Load packages and set defaults
pacman::p_load(tidyverse, rads, rads.data, openxlsx2, data.table, lubridate, Microsoft365R) # Load list of packages
options(max.print = 350) # Limit # of rows to show when printing/showing a data.frame
options(tibble.print_max = 50) # Limit # of rows to show when printing/showing a tibble (a tidyverse-flavored data.frame)
options(scipen = 999) # Avoid scientific notation
origin <- "1970-01-01" # Set the origin date, which is needed for many data/time functions
export_path <- "C:/Users/REPLACE WITH YOUR USER NAME/OneDrive - King County/" #replace with your desired path, use forward slashes

##Set keyring for SharePoint account
#keyring::key_set("sharepoint", username = "REPLACE TEXT WITH YOUR EMAIL ADDRESS") #Will prompt for password
keyring::key_list()

## Questions to answer using amusing, fake dataset:
  ## #1: Which manager is more productive?
  ## #2: Which time of day is Eli most hungry - morning or afternoon?
  ## #3: On average, how many times per day does Eli mention food?

#### Step 1: Connect to SharePoint where data files for this exercise are stored ####

## Data files for this exercise can be read from:
#https://kc1.sharepoint.com/:f:/r/teams/DPH-APDETraining/Shared%20Documents/R/apde_r_practice_exercises/r_data_wrangling_files?csf=1&web=1&e=zlbc4k

##Connect to SharePoint/TEAMS site
myteam <- get_team(team_name = "DPH-APDETraining",
                   username = keyring::key_list("sharepoint")$username,
                   password = keyring::key_get("sharepoint", keyring::key_list("sharepoint")$username),
                   auth_type = "resource_owner",
                   tenant = "kingcounty.gov")

##Connect to drive (i.e., document library)
myteam$list_drives() #lists all available document libraries
myteamdrive = myteam$get_drive("Documents") #connect to document library named "Documents"
myteamdrive$list_items() #list all items in drive

##Navigate to sub-folder holding data files for this exercise
myteamfolder = myteamdrive$get_item("R")
myteamfolder$list_items()
myteamfolder = myteamfolder$get_item("apde_r_practice_exercises")
myteamfolder$list_items()
myteamfolder = myteamfolder$get_item("r_data_wrangling_files")
myteamfolder$list_items()


#### Step 2: Practice loading one file to get import code right ####

#List all files in target subfolder
myteamfolder$list_items()
fileslist <- myteamfolder$list_items()$n

## Practice loading one file to get code right
temp <- tempfile(fileext = ".xlsx") #Create temp file to hold contents of SP file
myteamfolder$get_item("apde_staff_expressions_1.xlsx")$download(dest = temp)

## Open Excel file in R
test_file <- read_xlsx(
  xlsxFile = temp,
  sheet = "managers",
  colNames = TRUE,
  detectDates = TRUE)

## Everything looks good except the time column, thus make a new column with just the time (dropping date)
test_file_clean <- test_file %>%
  mutate(
    time_clean = as.ITime(time)
  )

## Drop test files now that we have the import code working
rm(test_file, test_file_clean, temp)


#### Step 3: Load all files ####

## Okay, now apply to all files in folder
compiled_files <- data.frame()  # Creates a blank data frame to use later
for(x in fileslist) {
  
  print(paste0("Loading file: ", x)) #Print command to console to show files loaded
  temp <- tempfile(fileext = ".xlsx") #Create temp file to hold contents of SP file
  myteamfolder$get_item(x)$download(dest = temp)
  
  each_data_file <- read_xlsx(xlsxFile = temp,
                              sheet = "managers",
                              colNames = TRUE,
                              detectDates = TRUE)
  compiled_files <- bind_rows(compiled_files, each_data_file)
}
rm(each_data_file, x, temp)

## Make new time column
compiled_files <- compiled_files %>%
  mutate(
    time_clean = as.ITime(time)
  )

## Now I realize that the 4 files are just duplicates and thus let's collapse to distinct rows
compiled_files <- distinct(compiled_files)


#### Step 4: Analyze data ####

## To answer question #1, let's identify all the unique words in manager's expressions and categorize as
  # 1 - food, 2 - work, and 3 - words to ignore

#Separate expressions into single words
words_matrix <- as.data.frame(str_split(compiled_files$expression, " ", simplify = TRUE))
length(words_matrix) #Return number of columns

#Combine words into a single column for tabulation
words_df <- as.data.frame(stack(words_matrix[1:11])) #Stack stacks columns of a matrix on top of each other to create 1 column
words_df <- words_df %>% rename(word = values) #Rename cryptic result of stack command
words_df <- select(words_df, word) #Drop helper variable(s)
words_df <- filter(words_df, !is.na(word) & word != "") #Drop blanks
words_df <- words_df %>% mutate(word = str_replace_all(word, "[:punct:]", "")) #Replace punctuation with blanks

#Tally words by number of occurrences
words_tally <- count(words_df, word)

#Upon manual review of words, categorize each word as food, work, or ignore
words_df <- words_df %>%
  mutate(
    word_cat = case_when(
      word %in% c("QA", "Tableau", "Teams", "analysis", "dashboard", "data", "debrief",
                  "media", "meet", "phone", "pipeline", "request", "result", "review",
                  "slide", "team", "trend", "update", "upgrade", "upload") ~ "work",
      word %in% c("almonds", "cherries", "chocolate", "coffee", "dinner", "food", "lunch", "rumbling",
                  "ripe", "snack", "stomach") ~ "food",
      TRUE ~ "ignore"
    ))

#Extract lists of keywords for further analysis
work <- words_df$word[words_df$word_cat=="work"]
food <- words_df$word[words_df$word_cat=="food"]

#Using original dataset, flag each expression as work or food, prioritizing work over food if both match
#Note code to convert vector of words into a single string with values separate by |, this is so str_detect will work
compiled_files <- compiled_files %>%
  mutate(
    word_cat = case_when(
      str_detect(expression, str_c("\\b(", str_c(work, collapse = "|"), ")\\b")) ~ "work",
      str_detect(expression, str_c("\\b(", str_c(food, collapse = "|"), ")\\b")) ~ "food",
      TRUE ~ NA_character_
    ))

#Answer 1st question - which manager is more productive
count(filter(compiled_files, word_cat == "work"), staff_name, word_cat)

#Answer: Aley is much more productive than Eli according to number of work-associated expressions identified

#Okay, now that we've identified that Eli is less productive, let's answer question #2 - when is Eli most hungry?

#Flag each time period as morning or afternoon
compiled_files <- compiled_files %>%
  mutate(
    time_of_day = case_when(
      between(time_clean, as.ITime("06:00:00"), as.ITime("11:30:00")) ~ "morning",
      between(time_clean, as.ITime("11:30:01"), as.ITime("18:00:00")) ~ "afternoon",
      TRUE ~ NA_character_
    )
  )

#Tabulate Eli's food-associated expressions by time period
compiled_files %>%
  filter(staff_name == "Eli" & word_cat == "food") %>%
  count(time_of_day)

#Answer: Eli appears to be distracted by hunger in the afternoon. Perhaps we should consider giving him extra snack?

#Okay, now for the final question - on average, how many times per day does Eli mention food?

#Create a numeric flag for instances of Eli mentioning food
compiled_files <- compiled_files %>%
  mutate(
    eli_food = case_when(
      staff_name == "Eli" & word_cat == "food" ~ 1,
      TRUE ~ 0))

#Use RADS calc function to calculate i) number of times Eli said something food-related, and ii) number of distinct days
q3_result <- calc(ph.data = compiled_files,
     what = c("eli_food", "date"),
     metrics = c("total", "denominator", "ndistinct"))

q3_result

#Answer to our question: Eli mentioned food on average 4.5 times per day
q3_result$total[q3_result$variable=="eli_food"] / q3_result$ndistinct[q3_result$variable=="date"]