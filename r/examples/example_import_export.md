# Importing & exporting data

Simple examples to get you started ...

## Set up
------

### 1.  Load the libraries used in this tutorial

<!-- -->

    # Importing and exporting data
    library(data.table)
    library(readxl)
    library(openxlsx)
    library(haven)
    library(odbc)

### 2.  Set up path to where the training data live

-   This makes the assumption that your working directory is the Github
    repo R\_training.

<!-- -->

    data_path <- file.path(getwd(), "dummy_data")

## Import data
-----------

### csv files

-   Use data.table's fread for speedy and accurate data importing.
-   Default settings will be best most of the time (assuming you have
    headings in the data).
-   It is possible to overwrite field types using colClasses option.

<!-- -->

    training_data_csv <- fread(file.path(data_path, "r_training_data.csv"))

### Excel files

-   Use readxl package in most situations.
-   openxlsx works fine to read if you are also planning to write out
    Excel files.

<!-- -->

    training_data_xl <- read_xlsx(file.path(data_path, "r_training_data.xlsx"),
                                  sheet = "users")

\*If your data is missing headers, set col\_names = F or specify them.

    training_data_xl_girls <- read_xlsx(file.path(data_path, "r_training_data.xlsx"),
                                       sheet = "girls_names", col_names = F)
    training_data_xl_girls <- read_xlsx(file.path(data_path, "r_training_data.xlsx"),
                                       sheet = "girls_names", 
                                       col_names = c("rank", "first_name", "n", "pct", "cum_n", "cum_pct"))

-   If your data has messiness at the top, use the skip option

<!-- -->

    training_data_xl_boys <- read_xlsx(file.path(data_path, "r_training_data.xlsx"),
                                       sheet = "boys_names", skip = 3)

### Stata files

-   Use the haven package (which can also pull in SAS files).
-   Variable and value labels will be imported and can be accessed as
    objects.

<!-- -->

    training_data_stata <- read_dta(file.path(data_path, "r_training_data.dta"))

### SQL tables

-   Use the odbc package, which builds on the DBI package.
-   If reading from a non-default schema, need to specify using DBI::Id
    function.

<!-- -->

    db_apde <- dbConnect(odbc(), "PH_APDEStore50")

    brfss <- DBI::dbReadTable(db_apde, "brfss_kc_ez_2000_2017")
    brfss2 <- dbGetQuery(
      db_apde, "SELECT TOP (10) genhlth2, obese FROM dbo.brfss_kc_ez_2000_2017")

    chi_alias <- DBI::dbReadTable(db_apde,
                                DBI::Id(schema = "ref", table = "chi_alias"))

Export data
-----------

### csv files

-   Use data.table's fwrite function.
-   Default settings will work most of the time.

<!-- -->

    fwrite(training_data_csv, file = file.path(data_path, "test_output.csv"))

### Excel files

-   Decide if you really need to write to Excel format (csv is
    preferable).
-   Use openxlsx's write.xlsx function.
-   You can write multiple sheets by making a list of data frames then
    writing that.
-   Sheet names will be the name of each data frame in the list.

<!-- -->

    write.xlsx(training_data_csv, file = file.path(data_path, "test_output.xlsx"),
               sheetName = "users")

    list_of_dataframes <- list("users" = training_data_csv, "girls_names" = training_data_xl_girls)
    write.xlsx(list_of_dataframes, file = file.path(data_path, "test_output.xlsx"))

### SQL tables

-   Use odbc and underlying DBI packages.
-   If writing to a non-default schema, need to specify using DBI::Id
    function.

<!-- -->

    # NB. This is just an example and won't actually run
    dbWriteTable(db_apde, 
                 name = DBI::Id(schema = "<schema_name>", table = "<table_name>")
                 value = as.data.frame(data_frame_in_r),
                 overwrite = T, append = F)
