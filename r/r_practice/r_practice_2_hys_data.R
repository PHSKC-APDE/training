#RADS practice
#Analyzing HYS data
#Ronald Buie, 2026-06-01

pacman::p_load(apde.data, data.table, dplyr, gh, gitcreds, ggplot2, ggrepel, ggthemes, keyring, lubridate, openxlsx, rads, rads.data, rstudioapi, sf, tidyverse, usethis)

localPath <- dirname(rstudioapi::getActiveDocumentContext()$path) #getActiveDocumentContext pulls the full path of the script it is ran from. dirname extracts the directtory from a given path, removing the file name at the end. We save this to get the directory for this user/instance.

#### Question 1: Using the most recent HYS data, visualize the relationship between grade and suicide-related indicators ####

#Use rads::get_data() to load survey-weighted HYS data for 2014 and 2021 survey years
hys <- apde.data::hys(year = c(2014, 2021))

#Use rads::calc() to compute summary survey statistics
hys_result <- rads::calc(ph.data = hys,
     what = c("mhlth_depressed_lstyr", "mhlth_suicideattempt_lstyear", "mhlth_suicideidea_lstyr", "mhlth_suicideplan_lstyr"),
     where = chi_grade %in% c(8,10,12),
     metrics = c("mean", "rse", "obs", "numerator", "denominator"),
     proportion = T,
     by = c("chi_year", "chi_grade"))

#Return estimates that meet suppression threshold for HYS data (counts between 0 and 10)
filter(hys_result, between(numerator, 0, 10))

#Return estimates that exceed RSE threshold for reliability check (i.e., RSE>30%)
filter(hys_result, rse>=30)

#Make some additional variables/modifications for graphing purposes
hys_result <- hys_result %>%
  mutate(
    #Make percentage variables (note you can also do this within chart creation script)
    mean_percent = rads::round2(mean*100,1),
    mean_lower_percent = rads::round2(mean_lower*100,1),
    mean_upper_percent = rads::round2(mean_upper*100,1),

    #Make a string version of the grade variable for better sorting and display
    grade = case_when(
      chi_grade == 8 ~ "08",
      chi_grade == 10 ~ "10",
      chi_grade == 12 ~ "12",
      TRUE ~ NA_character_
    )
  )

#Make a bar chart for 2014
my.chart1 <- ggplot(
  data = filter(hys_result, chi_year == 2014), #filter results dataset to 2014
  aes(x = variable, y = mean_percent, fill = grade, color = "black")) + #this dictates what will be visualized
  geom_bar(stat = "identity", position = position_dodge()) + #this specifies the type of chart, position_dodge allows for series

  scale_fill_brewer(name = "Grade", palette = "Paired") + #Sets legend title and color palette for bar colors
  scale_color_manual(values = c("#000000"), guide = "none") + #Sets bar outline as black and suppresses extra legend
  scale_x_discrete(
    limits = c("mhlth_depressed_lstyr", "mhlth_suicideidea_lstyr", "mhlth_suicideplan_lstyr", "mhlth_suicideattempt_lstyear"),
    labels = c("Depression during\npast year", "Suicide ideation\nduring past year", "Suicide plan during\npast year",
               "Suicide attempt during\npast year")) + #Manually orders and renames x-axis tick labels, note line breaks
  scale_y_continuous(label = scales::label_number(suffix = "%")) + #Adds percent symbol to y-axis label

  labs(
    title = "Youth mental health indicators by grade, King County, 2014",
    y="Percentage"
  ) + #Add chart title and y-axis title

  geom_text(aes(label = sprintf("%0.1f", mean_percent)),
            vjust = 2, color = "black", size = 5,
            position = position_dodge(0.9)) + #Add bar value labels with 0.1 decimal formatting

  theme(
    plot.title = element_text(color = "black", size = 20, face = "bold"), #Format of chart title
    legend.position = "bottom", #Position of legend
    legend.text = element_text(size = 14), #Format of legend text
    legend.title = element_text(size = 14, face = "bold"), #Format of legend title text

    axis.title.y = element_text(color = "black", size = 14), #Format of y-axis title
    axis.title.x = element_blank(), #Suppress x-axis title
    axis.text.x = element_text(color = "black", size = 14) #Format of x-axis tick labels
  )

#Plot chart in new window
dev.new(width = 11, height = 8.5, unit = "in", noRStudioGD = TRUE)
plot(my.chart1)

#Make a bar chart for 2021
my.chart2 <- ggplot(
  data = filter(hys_result, chi_year == 2021), #filter results dataset to 2021
  aes(x = variable, y = mean_percent, fill = grade, color = "black")) + #this dictates what will be visualized
  geom_bar(stat = "identity", position = position_dodge()) + #this specifies the type of chart, position_dodge allows for series

  scale_fill_brewer(name = "Grade", palette = "Paired") + #Sets legend title and color palette for bar colors
  scale_color_manual(values = c("#000000"), guide = "none") + #Sets bar outline as black and suppresses extra legend
  scale_x_discrete(
    limits = c("mhlth_depressed_lstyr", "mhlth_suicideidea_lstyr", "mhlth_suicideplan_lstyr", "mhlth_suicideattempt_lstyear"),
    labels = c("Depression during\npast year", "Suicide ideation\nduring past year", "Suicide plan during\npast year",
               "Suicide attempt during\npast year")) + #Manually orders and renames x-axis tick labels, note line breaks
  scale_y_continuous(label = scales::label_number(suffix = "%")) + #Adds percent symbol to y-axis label

  labs(
    title = "Youth mental health indicators by grade, King County, 2021",
    y="Percentage"
  ) + #Add chart title and y-axis title

  geom_text(aes(label = sprintf("%0.1f", mean_percent)),
            vjust = 2, color = "black", size = 5,
            position = position_dodge(0.9)) + #Add bar value labels with 0.1 decimal formatting

  theme(
    plot.title = element_text(color = "black", size = 20, face = "bold"), #Format of chart title
    legend.position = "bottom", #Position of legend
    legend.text = element_text(size = 14), #Format of legend text
    legend.title = element_text(size = 14, face = "bold"), #Format of legend title text

    axis.title.y = element_text(color = "black", size = 14), #Format of y-axis title
    axis.title.x = element_blank(), #Suppress x-axis title
    axis.text.x = element_text(color = "black", size = 14) #Format of x-axis tick labels
  )

#Plot chart in new window
dev.new(width = 11, height = 8.5, unit = "in", noRStudioGD = TRUE)
plot(my.chart2)

##Export graphs to folder as PNG files
ggsave(
  paste0("hys_mental_health_indicators_2014_", gsub("-", "_", Sys.Date()), ".png"),
  plot = my.chart1,
  dpi=600, width = 11, height = 8.5, units = "in",
  path = localPath)

ggsave(
  paste0("hys_mental_health_indicators_2021_", gsub("-", "_", Sys.Date()), ".png"),
  plot = my.chart2,
  dpi=600, width = 11, height = 8.5, units = "in",
  path = localPath)
