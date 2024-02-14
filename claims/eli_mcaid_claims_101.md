Medicaid claims 101
================
Eli Kern \| PHSKC-APDE \|
2024-02-13

## Welcome

This script serves as a companion to the Medicaid claims 101 training
slide deck developed by PHSKC-APDE for PHSKC and DCHS data analysts. The
[training slide
deck](https://kc1.sharepoint.com/:p:/r/teams/DPH-KCCross-SectorData/Shared%20Documents/Training/PHSKC_Medicaid%20claims%20data%20101.pptx?d=w1eed7465cdcc49838dc0afd54d62a97c&csf=1&web=1&e=3ob1Yr)
can be accessed by members of the
[DPH-KCCross-SectorData](https://kc1.sharepoint.com/teams/DPH-KCCross-SectorData)
SharePoint site.

This script is divided into sections corresponding to topics featured in
the training slide deck.

## Setup the environment

First, some code to set options, load package libraries, and establish a
connection to Medicaid claims data in the Health & Human Services
Analyst Workspace (HHSAW):

``` r
##### Set up global parameters and call in libraries #####
options(max.print = 350, tibble.print_max = 50, scipen = 999)
origin <- "1970-01-01" # Date origin
#devtools::install_github("PHSKC-APDE/claims_data") #install fresh package if it's been awhile
pacman::p_load(tidyverse, odbc, rads, openxlsx2, claims, rlang, glue, keyring)

#Connect to HHSAW using ODBC driver
db_hhsaw <- DBI::dbConnect(odbc::odbc(),
                           driver = "ODBC Driver 17 for SQL Server",
                           server = "tcp:kcitazrhpasqlprp16.azds.kingcounty.gov,1433",
                           database = "hhs_analytics_workspace",
                           uid = keyring::key_list("hhsaw")[["username"]],
                           pwd = keyring::key_get("hhsaw", keyring::key_list("hhsaw")[["username"]]),
                           Encrypt = "yes",
                           TrustServerCertificate = "yes",
                           Authentication = "ActiveDirectoryPassword")
```

## Counting distinct individuals in claims data

**Counting distinct people.** The following code counts the total number
of people in Medicaid data across all time. PHSKC maintains Medicaid
claims data for the most recent 10 years.

``` r
#Prep SQL query
sql_query_1 <- glue::glue_sql(
  "select count(distinct id_mcaid) as id_dcount
  from claims.final_mcaid_elig_demo;",
  .con = db_hhsaw)

#Send query to HHSAW, store result in R
result1 <- dbGetQuery(conn = db_hhsaw, statement = sql_query_1)
result1$id_dcount
```

    ## [1] 1172539

**Counting people by mutually inclusive race/ethnicity categories.** Now
let’s count distinct individuals by race/ethnicity using a few different
approaches.

First, APDE’s primary approach - mutually inclusive race/ethnicity
categories:

``` r
sql_query_1 <- glue::glue_sql(
  "select 'AI/AN' as race_eth, count(distinct id_mcaid) as id_dcount
  from claims.final_mcaid_elig_demo
  where race_aian = 1
  union select 'Asian' as race_eth, count(distinct id_mcaid) as id_dcount
  from claims.final_mcaid_elig_demo
  where race_asian = 1
  union select 'Black' as race_eth, count(distinct id_mcaid) as id_dcount
  from claims.final_mcaid_elig_demo
  where race_black = 1
  union select 'Latino' as race_eth, count(distinct id_mcaid) as id_dcount
  from claims.final_mcaid_elig_demo
  where race_latino = 1
  union select 'NH/PI' as race_eth, count(distinct id_mcaid) as id_dcount
  from claims.final_mcaid_elig_demo
  where race_nhpi = 1
  union select 'White' as race_eth, count(distinct id_mcaid) as id_dcount
  from claims.final_mcaid_elig_demo
  where race_white = 1
  union select 'Unknown' as race_eth, count(distinct id_mcaid) as id_dcount
  from claims.final_mcaid_elig_demo
  where race_eth_unk = 1;",
  .con = db_hhsaw)

result1 <- dbGetQuery(conn = db_hhsaw, statement = sql_query_1)
arrange(result1, race_eth)
```

    ##   race_eth id_dcount
    ## 1    AI/AN     36884
    ## 2    Asian    144488
    ## 3    Black    186716
    ## 4   Latino    192825
    ## 5    NH/PI     79700
    ## 6  Unknown    140056
    ## 7    White    564240

**Counting people by mutually exclusive race/ethnicity categories.** Now
let’s count people using mutually exclusive race/ethnicity categories
where people identifying with more than one race/ethnicity are included
in the Multiple Race group.

``` r
sql_query_1 <- glue::glue_sql(
  "select race_eth_me, count(distinct id_mcaid) as id_dcount
  from claims.final_mcaid_elig_demo
  group by race_eth_me;",
  .con = db_hhsaw)

result1 <- dbGetQuery(conn = db_hhsaw, statement = sql_query_1)
arrange(result1, race_eth_me)
```

    ##   race_eth_me id_dcount
    ## 1       AI/AN     16461
    ## 2       Asian    119692
    ## 3       Black    148517
    ## 4      Latino     91898
    ## 5    Multiple    153549
    ## 6       NH/PI     54101
    ## 7     Unknown    140056
    ## 8       White    448265

**Calculating age.** Now let’s calculate the minimum, maximum, and mean
age of Medicaid beneficiaries. To calculate age, we have to choose a
reference date - let’s choose December 31, 2023.

``` r
reference_date <- "2023-12-31"

sql_query_1 <- glue::glue_sql(
  "with age_20231231 as (
    select id_mcaid,
    case
        when (datediff(day, dob, {reference_date}) + 1) >= 0 then floor((datediff(day, dob, {reference_date}) + 1) / 365.25)
      when datediff(day, dob, {reference_date}) < 0 then NULL
    end as age
    from claims.final_mcaid_elig_demo
  )
  select min(age) as age_min, max(age) as age_max, cast(round(avg(age),1) as numeric(4,1)) as age_mean
  from age_20231231;",
  .con = db_hhsaw)

result1 <- dbGetQuery(conn = db_hhsaw, statement = sql_query_1)
result1
```

    ##   age_min age_max age_mean
    ## 1       0     123     34.7

**Selecting people with coverage during a measurement window.** Now
let’s start to work with time-varying concepts, beginning with coverage
start and end dates. Note that people enter and exit the Medicaid data
for three reasons: 1) people gain or lose Medicaid coverage (change in
eligibility), 2) people move into or out of King County, or 3) people
are born or die. With the exception of people entering due to birth, we
cannot differentiate between any of the other reasons.

For this first example, let’s find all the people with 1 or more day of
Medicaid coverage in 2023. The `[claims].[final_mcaid_elig_timevar]`
table contains from and to dates for a host of time-varying concepts -
we need to create new from and to dates within our measurement window
(2023-01-01 through 2023-12-31) in order to accurately count coverage
days.

``` r
reference_from_date <- "2023-01-01"
reference_to_date <- "2023-12-31"

sql_query_1 <- glue::glue_sql(
  "with cov_2023 as (
    select id_mcaid, from_date, to_date, geo_kc, cov_time_day,
    
    case
        --coverage period fully contains date range
        when from_date <= {reference_from_date} and to_date >= {reference_to_date}
          then datediff(day, {reference_from_date}, {reference_to_date}) + 1
        --coverage period begins before and ends within date range
        when from_date <= {reference_from_date} and to_date < {reference_to_date}and to_date >= {reference_from_date}
          then datediff(day, {reference_from_date}, to_date) + 1
        --coverage period begins within and ends after date range
        when from_date > {reference_from_date}  and to_date >= {reference_to_date} and from_date <= {reference_to_date}
          then datediff(day, from_date, {reference_to_date}) + 1
        --coverage period begins and ends within date range
        when from_date > {reference_from_date} and to_date < {reference_to_date}
          then datediff(day, from_date, to_date) + 1
        else 0
    end as custom_cov_time_day

    from claims.final_mcaid_elig_timevar
    where from_date <= {reference_to_date} and to_date >= {reference_from_date}
    and geo_kc = 1
  )
  select count(distinct id_mcaid)
  from cov_2023
  where custom_cov_time_day >= 1;",
  .con = db_hhsaw)

result1 <- dbGetQuery(conn = db_hhsaw, statement = sql_query_1)
result1
```

    ##         
    ## 1 605912

For the second example, let’s find all people with 50% or more of 2023
covered by Medicaid.

``` r
reference_from_date <- "2023-01-01"
reference_to_date <- "2023-12-31"
reference_period <- interval(ymd(reference_from_date), ymd(reference_to_date))
reference_days <- reference_period %/% days(1) + 1

sql_query_1 <- glue::glue_sql(
  "with cov_2023 as (
    select id_mcaid, from_date, to_date, geo_kc, cov_time_day,
    
    case
        --coverage period fully contains date range
        when from_date <= {reference_from_date} and to_date >= {reference_to_date}
          then datediff(day, {reference_from_date}, {reference_to_date}) + 1
        --coverage period begins before and ends within date range
        when from_date <= {reference_from_date} and to_date < {reference_to_date}and to_date >= {reference_from_date}
          then datediff(day, {reference_from_date}, to_date) + 1
        --coverage period begins within and ends after date range
        when from_date > {reference_from_date}  and to_date >= {reference_to_date} and from_date <= {reference_to_date}
          then datediff(day, from_date, {reference_to_date}) + 1
        --coverage period begins and ends within date range
        when from_date > {reference_from_date} and to_date < {reference_to_date}
          then datediff(day, from_date, to_date) + 1
        else 0
    end as custom_cov_time_day

    from claims.final_mcaid_elig_timevar
    where from_date <= {reference_to_date} and to_date >= {reference_from_date}
    and geo_kc = 1
  )
  select count(distinct id_mcaid)
  from cov_2023
  where custom_cov_time_day*1.0/{reference_days}*100.0 >= 50.0;",
  .con = db_hhsaw)

result1 <- dbGetQuery(conn = db_hhsaw, statement = sql_query_1)
result1
```

    ##         
    ## 1 464201

**Assigning people to a single geography for a given measurement
window.** People move and thus when conducting an analysis for a given
measurement window (let’s use 2023 again), we often want to assign each
person only once to geographic concepts, such as ZIP code of residence,
to avoid people being counted more than once in a descriptive analysis.

Let’s use the following code to 1) assign a single King County ZIP code
to each Medicaid beneficiary for 2023, and 2) count distinct people by
ZIP code of residence.

``` r
reference_from_date <- "2023-01-01"
reference_to_date <- "2023-12-31"

sql_query_1 <- glue::glue_sql(
  "with cov_2023 as (
    select distinct id_mcaid, geo_zip,
    
    case
        --coverage period fully contains date range
        when from_date <= {reference_from_date} and to_date >= {reference_to_date}
          then datediff(day, {reference_from_date}, {reference_to_date}) + 1
        --coverage period begins before and ends within date range
        when from_date <= {reference_from_date} and to_date < {reference_to_date}and to_date >= {reference_from_date}
          then datediff(day, {reference_from_date}, to_date) + 1
        --coverage period begins within and ends after date range
        when from_date > {reference_from_date}  and to_date >= {reference_to_date} and from_date <= {reference_to_date}
          then datediff(day, from_date, {reference_to_date}) + 1
        --coverage period begins and ends within date range
        when from_date > {reference_from_date} and to_date < {reference_to_date}
          then datediff(day, from_date, to_date) + 1
        else 0
    end as custom_cov_time_day

    from claims.final_mcaid_elig_timevar
    where from_date <= {reference_to_date} and to_date >= {reference_from_date}
    and geo_kc = 1
  ),
  
  zip_code_cov_time as (
    select id_mcaid, geo_zip, sum(custom_cov_time_day) as custom_cov_time_day
    from cov_2023
    group by id_mcaid, geo_zip
  ),
  
  zip_code_ranks as (
    select id_mcaid, geo_zip, custom_cov_time_day,
    rank() over(partition by id_mcaid
      order by case when geo_zip is null then 1 else 0 end, custom_cov_time_day desc, geo_zip)
        as geo_zip_rank
    from zip_code_cov_time
  )
  
  select geo_zip, count(distinct id_mcaid) as id_dcount
  from zip_code_ranks
  where geo_zip_rank = 1
  group by geo_zip;",
  .con = db_hhsaw)

result1 <- dbGetQuery(conn = db_hhsaw, statement = sql_query_1)

#Apply small number suppression
result1_cat1 <- result1 %>%
  mutate(id_dcount = case_when(
    between(id_dcount, 1, 10) ~ NA_integer_,
    TRUE ~ id_dcount
  ))
arrange(result1_cat1, desc(id_dcount))
```

    ##     geo_zip id_dcount
    ## 1     98003     27993
    ## 2     98002     24190
    ## 3     98032     21561
    ## 4     98023     21476
    ## 5     98030     20812
    ## 6     98118     20214
    ## 7     98031     19317
    ## 8     98168     18247
    ## 9     98198     16787
    ## 10    98092     16639
    ## 11    98001     15862
    ## 12    98042     15517
    ## 13    98133     15494
    ## 14    98188     13693
    ## 15    98058     13122
    ## 16    98125     11463
    ## 17    98144     10955
    ## 18    98108     10860
    ## 19    98146     10856
    ## 20    98034     10789
    ## 21    98178     10755
    ## 22    98056     10618
    ## 23    98052     10404
    ## 24    98122      9933
    ## 25    98104      9544
    ## 26    98106      9393
    ## 27    98055      9048
    ## 28    98155      9001
    ## 29    98059      8554
    ## 30    98103      8171
    ## 31    98115      7922
    ## 32    98105      7852
    ## 33    98007      7752
    ## 34    98126      6797
    ## 35    98038      6690
    ## 36    98006      6103
    ## 37    98022      5997
    ## 38    98166      5550
    ## 39    98148      5236
    ## 40    98057      5232
    ## 41    98033      5095
    ## 42    98011      4918
    ## 43    98101      4906
    ## 44    98121      4712
    ## 45    98004      4579
    ## 46    98008      4488
    ## 47    98109      4441
    ## 48    98028      4369
    ## 49    98027      4311
    ## 50    98107      4288
    ## 51    98117      4173
    ## 52    98102      4148
    ## 53    98029      4056
    ## 54    98116      3778
    ## 55    98047      3748
    ## 56    98119      3292
    ## 57    98005      3012
    ## 58    98112      2866
    ## 59    98072      2695
    ## 60    98177      2614
    ## 61    98070      2562
    ## 62    98053      2362
    ## 63    98045      2224
    ## 64    98040      2219
    ## 65    98199      2213
    ## 66    98136      2104
    ## 67    98074      2099
    ## 68    98065      2070
    ## 69    98019      1886
    ## 70    98075      1878
    ## 71    98010      1360
    ## 72    98014      1177
    ## 73    98077      1054
    ## 74    98024       804
    ## 75    98051       699
    ## 76    98354       444
    ## 77    98134       443
    ## 78    98039       162
    ## 79    98195       152
    ## 80    98009       128
    ## 81    98062       102
    ## 82    98288        88
    ## 83    98071        81
    ## 84    98224        77
    ## 85    98063        68
    ## 86    98093        65
    ## 87    98111        51
    ## 88    98064        50
    ## 89    98050        38
    ## 90    98138        33
    ## 91    98083        32
    ## 92    98025        32
    ## 93    98035        30
    ## 94    98145        28
    ## 95    98114        28
    ## 96    98068        27
    ## 97    98127        20
    ## 98    98015        19
    ## 99    98113        17
    ## 100   98165        15
    ## 101   98073        11
    ## 102   98041        NA
    ## 103   98161        NA
    ## 104   98089        NA
    ## 105   98194        NA
    ## 106   98174        NA
    ## 107   98131        NA
    ## 108   98013        NA
    ## 109   98175        NA
    ## 110   98251        NA
    ## 111   98160        NA
    ## 112   98139        NA
    ## 113   98141        NA
    ## 114   98124        NA
    ## 115   98185        NA
    ## 116   98164        NA
