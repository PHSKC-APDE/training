# Essential R capabilities for APDE users

This document sets out a list of R skills all APDE analysts should have. It also contains links to resources that can help users to master R.

## Resources
### Cheatsheets
Note: most of the cheat sheets have been saved in the APDE Training SharePoint site [here](https://kc1.sharepoint.com/teams/APDETraining/Shared%20Documents/Forms/AllItems.aspx?FolderCTID=0x012000F298778C9D54E2448DEC9C27C83FC5BB&amp;id=%2Fteams%2FAPDETraining%2FShared%20Documents%2FR):

- Base R cheat sheet: [http://github.com/rstudio/cheatsheets/raw/main/base-r.pdf](http://github.com/rstudio/cheatsheets/raw/main/base-r.pdf)
- R syntax cheat sheet: [https://github.com/rstudio/cheatsheets/raw/main/syntax.pdf](https://github.com/rstudio/cheatsheets/raw/main/syntax.pdf)
- Tidyverse and dplyr (Tidyverse) comparison code: [https://atrebas.github.io/post/2019-03-03-datatable-dplyr/](https://atrebas.github.io/post/2019-03-03-datatable-dplyr/)
- Data table cheat sheet: [https://s3.amazonaws.com/assets.datacamp.com/blog\_assets/datatable\_Cheat\_Sheet\_R.pdf](https://s3.amazonaws.com/assets.datacamp.com/blog_assets/datatable_Cheat_Sheet_R.pdf)
- Tidyverse: importing data cheat sheet (readr on page 1): [https://github.com/rstudio/cheatsheets/raw/main/data-import.pdf](https://github.com/rstudio/cheatsheets/raw/main/data-import.pdf)
- Tidyverse: data transformation cheat sheet: [https://github.com/rstudio/cheatsheets/raw/main/data-transformation.pdf](https://github.com/rstudio/cheatsheets/raw/main/data-transformation.pdf)
- Tidyverse: string manipulation cheat sheet: [https://github.com/rstudio/cheatsheets/raw/main/strings.pdf](https://github.com/rstudio/cheatsheets/raw/main/strings.pdf)
- Regular expressions cheat sheet: [https://www.rstudio.com/wp-content/uploads/2016/09/RegExCheatsheet.pdf](https://www.rstudio.com/wp-content/uploads/2016/09/RegExCheatsheet.pdf)
- Tidyverse: dates and times cheat sheet: [https://github.com/rstudio/cheatsheets/raw/main/lubridate.pdf](https://github.com/rstudio/cheatsheets/raw/main/lubridate.pdf)
- Tidyverse: reshape data cheat sheet (tidyr on page 2): [https://github.com/rstudio/cheatsheets/raw/main/data-import.pdf](https://github.com/rstudio/cheatsheets/raw/main/data-import.pdf)
- purrr cheat sheet: [https://github.com/rstudio/cheatsheets/raw/main/purrr.pdf](https://github.com/rstudio/cheatsheets/raw/main/purrr.pdf)
- ggplot2 cheat sheet: [https://www.rstudio.com/wp-content/uploads/2015/03/ggplot2-cheatsheet.pdf](https://www.rstudio.com/wp-content/uploads/2015/03/ggplot2-cheatsheet.pdf)
- Other cheat sheets: [https://www.rstudio.com/resources/cheatsheets/](https://www.rstudio.com/resources/cheatsheets/)

### Tutorials & Intros
- Intro to user-defined functions: [https://swcarpentry.github.io/r-novice-inflammation/02-func-R/](https://swcarpentry.github.io/r-novice-inflammation/02-func-R/)
- Another intro to functions: [https://nicercode.github.io/guides/functions/](https://nicercode.github.io/guides/functions/)
- Intro to skimr: [https://cran.r-project.org/web/packages/skimr/vignettes/Using\_skimr.html](https://cran.r-project.org/web/packages/skimr/vignettes/Using_skimr.html)
- Intro to srvyr: [https://cran.r-project.org/web/packages/srvyr/vignettes/srvyr-vs-survey.html](https://cran.r-project.org/web/packages/srvyr/vignettes/srvyr-vs-survey.html)
- Intro to GLMs in R: [https://data.princeton.edu/r/glms](https://data.princeton.edu/r/glms)
- ggplot2 tutorial: [http://r-statistics.co/Complete-Ggplot2-Tutorial-Part1-With-R-Code.html](http://r-statistics.co/Complete-Ggplot2-Tutorial-Part1-With-R-Code.html)
- Intro to odbc: [https://db.rstudio.com/odbc/](https://db.rstudio.com/odbc/)
- Tidyverse: Introduction to pivot: [https://tidyr.tidyverse.org/dev/articles/pivot.html](https://tidyr.tidyverse.org/dev/articles/pivot.html)
- Reshaping with data.table: [https://cran.r-project.org/web/packages/data.table/vignettes/datatable-reshape.html](https://cran.r-project.org/web/packages/data.table/vignettes/datatable-reshape.html)
- Intro to the apply family: [https://www.r-bloggers.com/using-apply-sapply-lapply-in-r/](https://www.r-bloggers.com/using-apply-sapply-lapply-in-r/)

## 1. Understand R syntax
- Base R cheat sheet: [http://github.com/rstudio/cheatsheets/raw/main/base-r.pdf](http://github.com/rstudio/cheatsheets/raw/main/base-r.pdf)
- R syntax cheat sheet: [https://github.com/rstudio/cheatsheets/raw/main/syntax.pdf](https://github.com/rstudio/cheatsheets/raw/main/syntax.pdf)
- Tidyverse and dplyr (Tidyverse) comparison code: [https://atrebas.github.io/post/2019-03-03-datatable-dplyr/](https://atrebas.github.io/post/2019-03-03-datatable-dplyr/)
- R data types: [https://www.statmethods.net/input/datatypes.html](https://www.statmethods.net/input/datatypes.html)

| Skill | Package used | Function |
| --- | --- | --- |
| Assign variables/objects | Base R | See [Base R cheat sheet](http://github.com/rstudio/cheatsheets/raw/main/base-r.pdf) |
| Install and attach/load packages | Base R | See [Base R cheat sheet](http://github.com/rstudio/cheatsheets/raw/main/base-r.pdf) |
| Understand differences between Tidyverse and data.table syntax | Tidyverse/data.table | See comparison [webpage](https://atrebas.github.io/post/2019-03-03-datatable-dplyr/) |
| Understand different object types (data frames, lists, vectors, etc.) | N/A | See web [resource](https://www.statmethods.net/input/datatypes.html) |

## 2. Import and export data
- readr cheat sheet (on page 1): [https://github.com/rstudio/cheatsheets/raw/main/data-import.pdf](https://github.com/rstudio/cheatsheets/raw/main/data-import.pdf)
- Intro to odbc: [https://db.rstudio.com/odbc/](https://db.rstudio.com/odbc/)

| Skill | Package used | Function |
| --- | --- | --- |
| Load data from csv file | Base R | read.csv/read.table
| Load data from csv file | data.table | fread |
| Load Stata, SAS, or SPSS file | haven | read\_sas/read\_sav/read\_dta |
| Load data from xls/xlsx file | readxl | read\_excel |
| Load data from an RData file | Base R | readRDS |
| Load data from SQL server | odbc/DBI | dbReadTable |
| Write data to csv file | Base R | write.csv/write.table |
| Write data to csv file | data.table | fwrite |
| Write data to csv file | readr | write\_csv |
| Write data/objects to RData file | Base R | saveRDS |
| Write data to SQL server | odbc/DBI | dbWriteTable |

## 3. Manipulate data

### *A. Add and remove variables/rows*

dplyr cheat sheet: [https://github.com/rstudio/cheatsheets/raw/main/data-transformation.pdf](https://github.com/rstudio/cheatsheets/raw/main/data-transformation.pdf)

| Skill | Package used | Function |
| --- | --- | --- |
| Create/update variables in a data frame/table | dplyr | mutate |
| Create/update variables in a data frame/table | data.table | See [cheat sheet](https://s3.amazonaws.com/assets.datacamp.com/blog_assets/datatable_Cheat_Sheet_R.pdf) |
| Remove variables from data frame/table | dplyr | select |
| Keep rows that match criteria | dplyr | filter |
| Keep rows that match criteria | data.table | DT[V1 == &quot;A&quot;] |

### *B. Work with strings*

stringr cheat sheet: [https://github.com/rstudio/cheatsheets/raw/main/strings.pdf](https://github.com/rstudio/cheatsheets/raw/main/strings.pdf)

[regular expressions](https://stat.ethz.ch/R-manual/R-devel/library/base/html/regex.html) used with Base R commands can also be very powerful

| Skill | Package used | Function |
| --- | --- | --- |
| Detect matches | stringr | str\_detect/str\_locate |
| Subset strings | stringr | str\_sub/str\_subset/str\_match |
| Replace strings | stringr | str\_replace/str\_to\_lower |
| Make use of regular expressions | N/A | See cheat sheet |

### *C. Work with dates/times*

lubridate cheat sheet: [https://github.com/rstudio/cheatsheets/raw/main/lubridate.pdf](https://github.com/rstudio/cheatsheets/raw/main/lubridate.pdf)

| Skill | Package used | Function |
| --- | --- | --- |
| Convert variables to date | Base R | as.Date |
| Obtain components of dates | lubridate | See [cheat sheet](https://github.com/rstudio/cheatsheets/raw/main/lubridate.pdf) |
| Calculate durations and intervals | lubridate | See [cheat sheet](https://github.com/rstudio/cheatsheets/raw/main/lubridate.pdf) |

### *D. Reshape data*

Introduction to pivot: [https://tidyr.tidyverse.org/dev/articles/pivot.html](https://tidyr.tidyverse.org/dev/articles/pivot.html)

Reshaping with data.table: [https://cran.r-project.org/web/packages/data.table/vignettes/datatable-reshape.html](https://cran.r-project.org/web/packages/data.table/vignettes/datatable-reshape.html)

| Skill | Package used | Function |
| --- | --- | --- |
| Change data from wide to long | tidyr | pivot\_longer |
| Change data from wide to long | data.table | melt |
| Change data from long to wide | tidyr | pivot\_wider |
| Change data from long to wide | data.table | dcast |

### *E. Run functions over multiple objects*
Intro to the apply family: [https://www.r-bloggers.com/using-apply-sapply-lapply-in-r/](https://www.r-bloggers.com/using-apply-sapply-lapply-in-r/)

purrr cheat sheet: [https://github.com/rstudio/cheatsheets/raw/main/purrr.pdf](https://github.com/rstudio/cheatsheets/raw/main/purrr.pdf)

| Skill | Package used | Function |
| --- | --- | --- |
| Use a function over a list of objects | Base R | lapply, vapply |
| Use a function over a list of objects | purrr | map |
| Use a function over two lists of objects in parallel | Base R | mapply |
| Use a function over two lists of objects in parallel | purrr | map2 |


## 4 . Analyze data

### *A. Summarize data*

Intro to skimr: [https://cran.r-project.org/web/packages/skimr/vignettes/Using\_skimr.html](https://cran.r-project.org/web/packages/skimr/vignettes/Using_skimr.html)

| Skill | Package used | Function |
| --- | --- | --- |
| Summarize data with mean/min/max/etc. | dplyr | summarise |
| Summarize variables in a data frame | skimr | skim |
| Summarize data (vector or data frame) | Base R | summary |

### *B. Use survey weights*

Intro to srvyr: [https://cran.r-project.org/web/packages/srvyr/vignettes/srvyr-vs-survey.html](https://cran.r-project.org/web/packages/srvyr/vignettes/srvyr-vs-survey.html)

| Skill | Package used | Function |
| --- | --- | --- |
| Working with survey data | Survey, srvyr |   |
| Apply survey weights | srvyr | as\_survey\_design |
| Analyze data with survey weights | srvyr | survey\_mean/survey\_total |

### *C. Run regression models*

Intro to GLMs in R: [https://data.princeton.edu/r/glms](https://data.princeton.edu/r/glms)

| Skill | Package used | Function |
| --- | --- | --- |
| Run a variety of GLM models | Base R/stats | glm |
| **OPTIONAL:** Multilevel models (Frequentists) | lme4 | lmer |
| **OPTIONAL:** Multilevel models (Bayesian) | brms | brms |

## 5. Display data

ggplot2 tutorial: [http://r-statistics.co/Complete-Ggplot2-Tutorial-Part1-With-R-Code.html](http://r-statistics.co/Complete-Ggplot2-Tutorial-Part1-With-R-Code.html)

ggplot2 cheat sheet: [https://www.rstudio.com/wp-content/uploads/2015/03/ggplot2-cheatsheet.pdf](https://www.rstudio.com/wp-content/uploads/2015/03/ggplot2-cheatsheet.pdf)

| Skill | Package used | Function |
| --- | --- | --- |
| Make a variety of plot types (scatter, histogram, line graph, etc.) | ggplot2 | ggplot |
| Edit axis type | ggplot2 | scale\_\*\_continuous, scale\_\*\_discrete |
| Edit graph & axis titles | ggplot2 | ggtitle, xlab, ylab |
| Edit graph & axis titles (alternative) | ggplot2 | labs(title = "", subtitle = "", x="", y="") |
| Edit legends & style | ggplot2 | theme |
| Use facets to produce comparison charts | ggplot2 | facet\_grid, facet\_grid |
| Saving charts and graphics | ggplot2 | ggsave |

## 6. Create a function

Intro to user-defined functions: [https://swcarpentry.github.io/r-novice-inflammation/02-func-R/](https://swcarpentry.github.io/r-novice-inflammation/02-func-R/)

Another intro to functions: [https://nicercode.github.io/guides/functions/](https://nicercode.github.io/guides/functions/)

| Skill | Package used | Function |
| --- | --- | --- |
| Create a user-defined function | N/A |   |
| Incorporate error checking and useful messages into user-defined functions | N/A | e.g. stop, stopifnot, tryCatch |
