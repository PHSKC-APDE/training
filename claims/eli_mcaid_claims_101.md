Medicaid claims 101
================
Eli Kern \| PHSKC-APDE \|
2024-02-16

- [Welcome](#welcome)
- [Setup the environment](#setup-the-environment)
- [Counting distinct individuals in claims
  data](#counting-distinct-individuals-in-claims-data)
- [Counting health care encounters](#counting-health-care-encounters)

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

**Counting distinct people.**  
The following code counts the total number of people in Medicaid data
across all time. PHSKC maintains Medicaid claims data for the most
recent 10 years.

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

    ## [1] 1179733

**Counting people by mutually inclusive race/ethnicity categories.**  
Now let’s count distinct individuals by race/ethnicity using a few
different approaches. First, APDE’s primary approach - mutually
inclusive race/ethnicity categories:

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

<div class="kable-table">

| race_eth | id_dcount |
|:---------|----------:|
| AI/AN    |     37172 |
| Asian    |    145570 |
| Black    |    187825 |
| Latino   |    194628 |
| NH/PI    |     80267 |
| Unknown  |    140605 |
| White    |    567704 |

</div>

**Counting people by mutually exclusive race/ethnicity categories.**  
Now let’s count people using mutually exclusive race/ethnicity
categories where people identifying with more than one race/ethnicity
are included in the Multiple Race group.

``` r
sql_query_1 <- glue::glue_sql(
  "select race_eth_me, count(distinct id_mcaid) as id_dcount
  from claims.final_mcaid_elig_demo
  group by race_eth_me;",
  .con = db_hhsaw)

result1 <- dbGetQuery(conn = db_hhsaw, statement = sql_query_1)
arrange(result1, race_eth_me)
```

<div class="kable-table">

| race_eth_me | id_dcount |
|:------------|----------:|
| AI/AN       |     16556 |
| Asian       |    120473 |
| Black       |    149297 |
| Latino      |     92745 |
| Multiple    |    155040 |
| NH/PI       |     54407 |
| Unknown     |    140605 |
| White       |    450610 |

</div>

**Calculating age.**  
Now let’s calculate the minimum, maximum, and mean age of Medicaid
beneficiaries. To calculate age, we have to choose a reference date -
let’s choose December 31, 2023.

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

<div class="kable-table">

| age_min | age_max | age_mean |
|--------:|--------:|---------:|
|       0 |     123 |     34.6 |

</div>

**Selecting people with coverage during a measurement window.**  
Now let’s start to work with time-varying concepts, beginning with
coverage start and end dates. Note that people enter and exit the
Medicaid data for three reasons: 1) people gain or lose Medicaid
coverage (change in eligibility), 2) people move into or out of King
County, or 3) people are born or die. With the exception of people
entering due to birth, we cannot differentiate between any of the other
reasons.

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
  select count(distinct id_mcaid) as id_dcount
  from cov_2023
  where custom_cov_time_day >= 1;",
  .con = db_hhsaw)

result1 <- dbGetQuery(conn = db_hhsaw, statement = sql_query_1)
result1
```

<div class="kable-table">

| id_dcount |
|----------:|
|    606890 |

</div>

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
  select count(distinct id_mcaid) as id_dcount
  from cov_2023
  where custom_cov_time_day*1.0/{reference_days}*100.0 >= 50.0;",
  .con = db_hhsaw)

result1 <- dbGetQuery(conn = db_hhsaw, statement = sql_query_1)
result1
```

<div class="kable-table">

| id_dcount |
|----------:|
|    464202 |

</div>

**Assigning people to a single geography for a given measurement
window.**  
People move and thus when conducting an analysis for a given measurement
window (let’s use 2023 again), we often want to assign each person only
once to geographic concepts, such as ZIP code of residence, to avoid
people being counted more than once in a descriptive analysis.

Let’s use the following code to 1) assign a single King County ZIP code
to each Medicaid beneficiary for 2023, and 2) count distinct people by
ZIP code of residence for the 10 ZIP codes with the largest number of
Medicaid beneficaries.

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
  
  select top 10 geo_zip, count(distinct id_mcaid) as id_dcount
  from zip_code_ranks
  where geo_zip_rank = 1
  group by geo_zip
  order by id_dcount desc;",
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

<div class="kable-table">

| geo_zip | id_dcount |
|:--------|----------:|
| 98003   |     28026 |
| 98002   |     24223 |
| 98032   |     21613 |
| 98023   |     21508 |
| 98030   |     20847 |
| 98118   |     20246 |
| 98031   |     19349 |
| 98168   |     18280 |
| 98198   |     16811 |
| 98092   |     16669 |

</div>

## Counting health care encounters

**Counting emergency department visits.**  
The following code counts the total number of *distinct* emergency
department (ED) visits by year from 2018-2022, using two different
definitions for ED visit. The standard definition used by APDE is the
`ed_pophealth_id` field, as uses a broader definition of an ED visit
than the `ed_perform_id` field.

``` r
sql_query_1 <- glue::glue_sql(
  "select a.service_year, a.ed_pophealth_dcount, b.ed_perform_dcount
  from (
    select year(last_service_date) as service_year, count(distinct ed_pophealth_id) as ed_pophealth_dcount
    from claims.final_mcaid_claim_header
    where year(last_service_date) between 2018 and 2022
      and ed_pophealth_id is not null
    group by year(last_service_date)
  ) as a
  left join (
    select year(last_service_date) as service_year, count(distinct ed_perform_id) as ed_perform_dcount
    from claims.final_mcaid_claim_header
    where year(last_service_date) between 2018 and 2022
      and ed_perform_id is not null
    group by year(last_service_date)
  ) as b
  on a.service_year = b.service_year;",
  .con = db_hhsaw)

result1 <- dbGetQuery(conn = db_hhsaw, statement = sql_query_1)
arrange(result1, service_year)
```

<div class="kable-table">

| service_year | ed_pophealth_dcount | ed_perform_dcount |
|-------------:|--------------------:|------------------:|
|         2018 |              253029 |            232439 |
|         2019 |              249888 |            229344 |
|         2020 |              198647 |            181788 |
|         2021 |              227801 |            208541 |
|         2022 |              245984 |            227378 |

</div>

**Counting inpatient hospital stays.**  
The following code counts the total number of *distinct* acute inpatient
stays by year from 2018-2022, which includes hospitalizations for both
medical reasons and for labor and delivery.

``` r
sql_query_1 <- glue::glue_sql(
  "select year(last_service_date) as service_year, count(distinct inpatient_id) as inpatient_dcount
  from claims.final_mcaid_claim_header
  where year(last_service_date) between 2018 and 2022
    and inpatient_id is not null
  group by year(last_service_date);",
  .con = db_hhsaw)

result1 <- dbGetQuery(conn = db_hhsaw, statement = sql_query_1)
arrange(result1, service_year)
```

<div class="kable-table">

| service_year | inpatient_dcount |
|-------------:|-----------------:|
|         2018 |            26926 |
|         2019 |            29048 |
|         2020 |            28191 |
|         2021 |            33690 |
|         2022 |            31837 |

</div>

**Counting primary care visits.**  
The following code counts the total number of *distinct* primary care
visits by year from 2018-2022.

``` r
sql_query_1 <- glue::glue_sql(
  "select year(last_service_date) as service_year, count(distinct pc_visit_id) as pc_visit_dcount
  from claims.final_mcaid_claim_header
  where year(last_service_date) between 2018 and 2022
    and pc_visit_id is not null
  group by year(last_service_date);",
  .con = db_hhsaw)

result1 <- dbGetQuery(conn = db_hhsaw, statement = sql_query_1)
arrange(result1, service_year)
```

<div class="kable-table">

| service_year | pc_visit_dcount |
|-------------:|----------------:|
|         2018 |         1108715 |
|         2019 |         1054307 |
|         2020 |          921956 |
|         2021 |         1066642 |
|         2022 |         1009858 |

</div>

**Leading causes of ED visits, inpatient stays, and primary care
visits.**  
The `[ref].[icdcm_codes]` table provides a 4-level cause categorization
framework for grouping raw ICD-CM codes into categories that are a bit
easier for us analysts to work with. For ICD-10-CM (diagnosis coding
scheme that was introduced to the US in October 2015), this framework
can be used to group the 100,666 raw ICD-10-CM codes into a
*super-level* category (7 causes), a *broad* category (22 causes), a
*mid-level* category (176 causes), and a *detailed* category (515
causes).

For the purpose of this demonstration, we will use the superlevel,
broad, and midlevel categorizations to identify the top 10 causes of ED
visits, inpatient stays, and primary care visits in 2022, using the
primary diagnosis only on each claim.

``` r
##Top 10 causes of inpatient stays in 2022

sql_query_1 <- glue::glue_sql(
  "select top 10 b.ccs_superlevel_desc,
  case when count(distinct inpatient_id) between 1 and 10 then null else count(distinct inpatient_id) end as inpatient_dcount
  from [claims].[final_mcaid_claim_header] as a
  left join ref.icdcm_codes as b
  on (a.primary_diagnosis = b.icdcm) and (a.icdcm_version = b.icdcm_version)
  where a.inpatient_id is not null and year(a.last_service_date) = 2022
  group by b.ccs_superlevel_desc
  order by inpatient_dcount desc;",
  .con = db_hhsaw)

result1 <- dbGetQuery(conn = db_hhsaw, statement = sql_query_1)

sql_query_2 <- glue::glue_sql(
  "select top 10 b.ccs_broad_desc,
  case when count(distinct inpatient_id) between 1 and 10 then null else count(distinct inpatient_id) end as inpatient_dcount
  from [claims].[final_mcaid_claim_header] as a
  left join ref.icdcm_codes as b
  on (a.primary_diagnosis = b.icdcm) and (a.icdcm_version = b.icdcm_version)
  where a.inpatient_id is not null and year(a.last_service_date) = 2022
  group by b.ccs_broad_desc
  order by inpatient_dcount desc;",
  .con = db_hhsaw)

result2 <- dbGetQuery(conn = db_hhsaw, statement = sql_query_2)

sql_query_3 <- glue::glue_sql(
  "select top 10 b.ccs_midlevel_desc,
  case when count(distinct inpatient_id) between 1 and 10 then null else count(distinct inpatient_id) end as inpatient_dcount
  from [claims].[final_mcaid_claim_header] as a
  left join ref.icdcm_codes as b
  on (a.primary_diagnosis = b.icdcm) and (a.icdcm_version = b.icdcm_version)
  where a.inpatient_id is not null and year(a.last_service_date) = 2022
  group by b.ccs_midlevel_desc
  order by inpatient_dcount desc;",
  .con = db_hhsaw)

result3 <- dbGetQuery(conn = db_hhsaw, statement = sql_query_3)

arrange(result1, desc(inpatient_dcount))
```

<div class="kable-table">

| ccs_superlevel_desc              | inpatient_dcount |
|:---------------------------------|-----------------:|
| Pregnancy or birth complications |             9632 |
| Chronic diseases                 |             8355 |
| Behavioral health disorders      |             5764 |
| Infectious diseases              |             4359 |
| Not classified                   |             2143 |
| Injuries                         |             1639 |
| Congenital anomalies             |              118 |

</div>

``` r
arrange(result2, desc(inpatient_dcount))
```

<div class="kable-table">

| ccs_broad_desc                                                      | inpatient_dcount |
|:--------------------------------------------------------------------|-----------------:|
| Certain conditions originating in the perinatal period              |             5846 |
| Mental, behavioral and neurodevelopmental disorders                 |             5727 |
| Pregnancy, childbirth and the puerperium                            |             4476 |
| Certain infectious and parasitic diseases                           |             3091 |
| Diseases of the circulatory system                                  |             2714 |
| Diseases of the digestive system                                    |             1860 |
| Injury, poisoning and certain other consequences of external causes |             1738 |
| Endocrine, nutritional and metabolic diseases                       |             1473 |
| Diseases of the respiratory system                                  |             1312 |
| Diseases of the genitourinary system                                |              625 |

</div>

``` r
arrange(result3, desc(inpatient_dcount))
```

<div class="kable-table">

| ccs_midlevel_desc                             | inpatient_dcount |
|:----------------------------------------------|-----------------:|
| Liveborn                                      |             5618 |
| Schizophrenia and other psychotic disorders   |             2371 |
| Septicemia                                    |             2242 |
| Mood disorders                                |             1896 |
| Hypertension                                  |             1124 |
| Diabetes mellitus                             |              891 |
| Complications due to a procedure or operation |              747 |
| Alcohol-related disorders                     |              744 |
| Complications during labor                    |              742 |
| Viral infection                               |              671 |

</div>
