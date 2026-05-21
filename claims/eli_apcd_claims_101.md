WA-APCD claims 101
================
Eli Kern \| PHSKC-APDE \|
2026-05-21

- [Welcome](#welcome)
- [Setup the environment](#setup-the-environment)
- [Counting distinct individuals in claims
  data](#counting-distinct-individuals-in-claims-data)
- [Counting health care encounters](#counting-health-care-encounters)
- [Identifying reasons for health care encounters (i.e.,
  diagnoses)](#identifying-reasons-for-health-care-encounters-ie-diagnoses)
- [Change log](#change-log)

## Welcome

This script is designed to walk analysts through how to work with WA
All-Payer Claims Database (WA-APCD) data maintained by PHSKC. For more
background information on claims data overall, check out the [Medicaid
claims-focused training slide
deck](https://kc1.sharepoint.com/:p:/r/teams/DPH-APDE-Healthcare-Data/Shared%20Documents/Guidance/PHSKC_Medicaid%20claims%20data%20101.pptx?d=wd909065239f24b57b4c48e9528793a31&csf=1&web=1&e=bXVM9g)
developed by PHSKC-APDE for PHSKC and DCHS data analysts.

This script is divided into sections corresponding to topics featured in
the training slide deck.

## Setup the environment

First, some code to set options, load package libraries, and establish a
connection to claims data in the Health & Human Services Analyst
Workspace (HHSAW):

``` r
##### Set up global parameters and call in libraries #####
options(max.print = 350, tibble.print_max = 50, scipen = 999)
origin <- "1970-01-01" # Date origin
#devtools::install_github("PHSKC-APDE/claims_data") #install fresh package if it's been awhile
pacman::p_load(tidyverse, odbc, rads, openxlsx2, claims, rlang, glue, keyring)

#Connect to HHSAW using ODBC driver
db_hhsaw <- DBI::dbConnect(odbc::odbc(),
                           driver = "ODBC Driver 17 for SQL Server",
                           server = "kcitazrhpasqlprp16.database.windows.net",
                           database = "hhs_analytics_workspace",
                           Authentication = "ActiveDirectoryIntegrated")
```

## Counting distinct individuals in claims data

**Counting distinct people.**  
The following code counts the total number of people in WA-APCD data
across all time. PHSKC maintains WA-APCD data from 2014 onward, though
data is most complete from 2016 onward.

``` r
#Prep SQL query
sql_query_1 <- glue::glue_sql(
  "select count(distinct id_apcd) as id_dcount
  from claims.final_apcd_elig_demo;",
  .con = db_hhsaw)

#Send query to HHSAW, store result in R
result1 <- dbGetQuery(conn = db_hhsaw, statement = sql_query_1)
result1$id_dcount
```

    ## [1] 11676387

**Counting people by mutually inclusive race/ethnicity categories.**  
Now let’s count distinct individuals by race/ethnicity using two
approaches. You’ll notice that there’s a lot of people with unknown
race, which we’ll explore and explain later on. First, APDE’s primary
approach - mutually inclusive race/ethnicity categories:

``` r
sql_query_1 <- glue::glue_sql(
  "select 'AI/AN' as race_eth, count(distinct id_apcd) as id_dcount
  from claims.final_apcd_elig_demo
  where race_aian = 1
  union select 'Asian' as race_eth, count(distinct id_apcd) as id_dcount
  from claims.final_apcd_elig_demo
  where race_asian = 1
  union select 'Black' as race_eth, count(distinct id_apcd) as id_dcount
  from claims.final_apcd_elig_demo
  where race_black = 1
  union select 'Latino' as race_eth, count(distinct id_apcd) as id_dcount
  from claims.final_apcd_elig_demo
  where race_latino = 1
  union select 'NH/PI' as race_eth, count(distinct id_apcd) as id_dcount
  from claims.final_apcd_elig_demo
  where race_nhpi = 1
  union select 'White' as race_eth, count(distinct id_apcd) as id_dcount
  from claims.final_apcd_elig_demo
  where race_white = 1
  union select 'Unknown' as race_eth, count(distinct id_apcd) as id_dcount
  from claims.final_apcd_elig_demo
  where race_unknown = 1;",
  .con = db_hhsaw)

result1 <- dbGetQuery(conn = db_hhsaw, statement = sql_query_1)
arrange(result1, race_eth)
```

<div class="kable-table">

| race_eth | id_dcount |
|:---------|----------:|
| AI/AN    |    199297 |
| Asian    |    466795 |
| Black    |    427257 |
| Latino   |    997577 |
| NH/PI    |    241613 |
| Unknown  |   5790860 |
| White    |   4490415 |

</div>

**Counting people by mutually exclusive race/ethnicity categories.**  
Now let’s count people using mutually exclusive race/ethnicity
categories where people identifying with more than one race/ethnicity
are included in the Multiple Race group.

``` r
sql_query_1 <- glue::glue_sql(
  "select race_eth_me, count(distinct id_apcd) as id_dcount
  from claims.final_apcd_elig_demo
  group by race_eth_me;",
  .con = db_hhsaw)

result1 <- dbGetQuery(conn = db_hhsaw, statement = sql_query_1)
arrange(result1, race_eth_me)
```

<div class="kable-table">

| race_eth_me | id_dcount |
|:------------|----------:|
| AI/AN       |    112547 |
| Asian       |    289823 |
| Black       |    328771 |
| Latino      |    392874 |
| Multiple    |    871218 |
| NH/PI       |     72730 |
| White       |   3817564 |
| NA          |   5790860 |

</div>

**Calculating age.**  
Now let’s calculate the minimum, maximum, and mean age of people in the
WA-APCD. To calculate age, we have to choose a reference date - let’s
choose December 31, 2023. One note - we don’t actually have date of
birth (as this is a direct identifier), but we have an estimated date of
birth using information about how people’s age changes month-to-month
(notice that all date of birth values are the 1st of the month).

``` r
reference_date <- "2023-12-31"

sql_query_1 <- glue::glue_sql(
  "with age_20231231 as (
    select id_apcd,
    case
        when (datediff(day, dob, {reference_date}) + 1) >= 0 then floor((datediff(day, dob, {reference_date}) + 1) / 365.25)
      when datediff(day, dob, {reference_date}) < 0 then NULL
    end as age
    from claims.final_apcd_elig_demo
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
|       0 |     100 |       42 |

</div>

**Selecting people with coverage during a measurement window.**  
Now let’s start to work with time-varying concepts, beginning with
coverage start and end dates. Note that people enter and exit the data
for three reasons: 1) people gain or lose a type of insurance coverage
that is included in the WA-APCD (change in eligibility), 2) people move
into or out of WA State, or 3) people are born or die. With the
exception of people entering due to birth, we cannot differentiate
between any of the other reasons.

For this first example, let’s find all the people with 1 or more day of
any type of medical coverage (med_covgrp \> 0) in 2023. We’re also going
to limit our query to WA state residents (geo_wa = 1), as the WA-APCD
does contain some information on people living outside of WA state. The
`[claims].[final_apcd_elig_month]` table contains monthly records mapped
to a range of time-varying concepts.

``` r
reference_from_date <- "2023-01-01"
reference_to_date <- "2023-12-31"

sql_query_1 <- glue::glue_sql(
  "select count(distinct id_apcd) as id_dcount
  from claims.final_apcd_elig_month
  where from_date between {reference_from_date} and {reference_to_date}
    and med_covgrp > 0
    and geo_wa = 1;",
  .con = db_hhsaw)

result1 <- dbGetQuery(conn = db_hhsaw, statement = sql_query_1)
result1
```

<div class="kable-table">

| id_dcount |
|----------:|
|   4930960 |

</div>

For the second example, let’s find all WA state residents with 50% or
more of 2023 covered by Medicaid medical coverage. Note that this same
approach can be used to identify people with dental or pharmacy
coverage, and we can subset people by insurance market (i.e., Medicaid,
Medicare, Commercial).

``` r
reference_from_date <- "2023-01-01"
reference_to_date <- "2023-12-31"
reference_period <- interval(ymd(reference_from_date), ymd(reference_to_date))
reference_days <- reference_period %/% days(1) + 1

sql_query_1 <- glue::glue_sql(
  "with cov_2023 as (
    select id_apcd, sum(cov_time_day) as cov_time_day
    from claims.final_apcd_elig_month
    where from_date between {reference_from_date} and {reference_to_date}
      and med_medicaid = 1
      and geo_wa = 1
    group by id_apcd
  )
  select count(distinct id_apcd) as id_dcount
  from cov_2023
  where cov_time_day*1.0/{reference_days}*100.0 >= 50.0;",
  .con = db_hhsaw)

result1 <- dbGetQuery(conn = db_hhsaw, statement = sql_query_1)
result1
```

<div class="kable-table">

| id_dcount |
|----------:|
|   2172001 |

</div>

**Assigning people to a single geography for a given measurement
window.**  
People move and thus when conducting an analysis for a given measurement
window (let’s use 2023 again), we often want to assign each person only
once to geographic concepts, such as county of residence, to avoid
people being counted more than once in a descriptive analysis.

Let’s use the following code to 1) assign a single county to each
Medicaid members for 2023, and 2) count distinct people by county of
residence for the 10 counties with the largest number of Medicaid
members

``` r
reference_from_date <- "2023-01-01"
reference_to_date <- "2023-12-31"

sql_query_1 <- glue::glue_sql(
  "with county_cov_time as (
    select id_apcd, geo_county, sum(cov_time_day) as cov_time_day
    from claims.final_apcd_elig_month
    where from_date between {reference_from_date} and {reference_to_date}
      and geo_wa = 1
    group by id_apcd, geo_county
  ),
  
  county_ranks as (
    select id_apcd, geo_county, cov_time_day,
    rank() over(partition by id_apcd
      order by case when geo_county is null then 1 else 0 end, cov_time_day desc, geo_county)
        as county_rank
    from county_cov_time
  )
  
  select top 10 geo_county, count(distinct id_apcd) as id_dcount
  from county_ranks
  where county_rank = 1
  group by geo_county
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

| geo_county | id_dcount |
|:-----------|----------:|
| King       |   1661222 |
| Pierce     |    723216 |
| Snohomish  |    628083 |
| Spokane    |    463728 |
| Clark      |    446974 |
| Thurston   |    252249 |
| Yakima     |    230248 |
| Whatcom    |    191150 |
| Kitsap     |    190528 |
| Benton     |    176094 |

</div>

**Exploring race/ethnicity by insurance market.**  
Let’s come back to race/ethnicity, and explore across insurance markets
(Medicaid, Medicare, Commercial), as this is a critical consideration
when using WA-APCD data for equity analyses. We’ll use calendar year
2022. This code is long because we’re working with mutually inclusive
concepts (market, race). First, we identify WA state residents for each
market in 2022, then we add up the number of people in the numerator and
denominator for each racial/ethnic group. Lastly, we calculate
percentages. Be sure to check out how the percentage of people with
unknown race/ethnicity varies across insurance markets.

``` r
sql_query_1 <- glue::glue_sql(
  "with medicaid as (
    select distinct a.id_apcd, b.race_aian, b.race_asian, b.race_black, b.race_latino, b.race_nhpi,
        b.race_white, b.race_unknown,
        'Medicaid' as market
    from claims.final_apcd_elig_month as a
    left join claims.final_apcd_elig_demo as b
    on a.id_apcd = b.id_apcd
    where med_medicaid = 1
        and geo_wa = 1
        and year = 2022
  ),
  medicare as (
    select distinct a.id_apcd, b.race_aian, b.race_asian, b.race_black, b.race_latino, b.race_nhpi,
        b.race_white, b.race_unknown,
        'Medicare' as market
    from claims.final_apcd_elig_month as a
    left join claims.final_apcd_elig_demo as b
    on a.id_apcd = b.id_apcd
    where med_medicare = 1
        and geo_wa = 1
        and year = 2022
  ),
  commercial as (
    select distinct a.id_apcd, b.race_aian, b.race_asian, b.race_black, b.race_latino, b.race_nhpi,
        b.race_white, b.race_unknown,
        'Commercial' as market
    from claims.final_apcd_elig_month as a
    left join claims.final_apcd_elig_demo as b
    on a.id_apcd = b.id_apcd
    where med_commercial = 1
        and geo_wa = 1
        and year = 2022
  ),
  mcaid_denom as (
    select market, count(distinct id_apcd) as denom
    from medicaid
    group by market
  ),
  mcare_denom as (
    select market, count(distinct id_apcd) as denom
    from medicare
    group by market
  ),
  comm_denom as (
    select market, count(distinct id_apcd) as denom
    from commercial
    group by market
  ),
  mcaid_num as (
    select 'AI/AN' as race_eth, count(distinct id_apcd) as id_dcount, market
    from medicaid
    where race_aian = 1
    group by market
    union select 'Asian' as race_eth, count(distinct id_apcd) as id_dcount, market
    from medicaid
    where race_asian = 1
    group by market
    union select 'Black' as race_eth, count(distinct id_apcd) as id_dcount, market
    from medicaid
    where race_black = 1
    group by market
    union select 'Latino' as race_eth, count(distinct id_apcd) as id_dcount, market
    from medicaid
    where race_latino = 1
    group by market
    union select 'NH/PI' as race_eth, count(distinct id_apcd) as id_dcount, market
    from medicaid
    where race_nhpi = 1
    group by market
    union select 'White' as race_eth, count(distinct id_apcd) as id_dcount, market
    from medicaid
    where race_white = 1
    group by market
    union select 'Unknown' as race_eth, count(distinct id_apcd) as id_dcount, market
    from medicaid
    where race_unknown = 1
    group by market
  ),
  mcare_num as (
    select 'AI/AN' as race_eth, count(distinct id_apcd) as id_dcount, market
    from medicare
    where race_aian = 1
    group by market
    union select 'Asian' as race_eth, count(distinct id_apcd) as id_dcount, market
    from medicare
    where race_asian = 1
    group by market
    union select 'Black' as race_eth, count(distinct id_apcd) as id_dcount, market
    from medicare
    where race_black = 1
    group by market
    union select 'Latino' as race_eth, count(distinct id_apcd) as id_dcount, market
    from medicare
    where race_latino = 1
    group by market
    union select 'NH/PI' as race_eth, count(distinct id_apcd) as id_dcount, market
    from medicare
    where race_nhpi = 1
    group by market
    union select 'White' as race_eth, count(distinct id_apcd) as id_dcount, market
    from medicare
    where race_white = 1
    group by market
    union select 'Unknown' as race_eth, count(distinct id_apcd) as id_dcount, market
    from medicare
    where race_unknown = 1
    group by market
  ),
  comm_num as (
    select 'AI/AN' as race_eth, count(distinct id_apcd) as id_dcount, market
    from commercial
    where race_aian = 1
    group by market
    union select 'Asian' as race_eth, count(distinct id_apcd) as id_dcount, market
    from commercial
    where race_asian = 1
    group by market
    union select 'Black' as race_eth, count(distinct id_apcd) as id_dcount, market
    from commercial
    where race_black = 1
    group by market
    union select 'Latino' as race_eth, count(distinct id_apcd) as id_dcount, market
    from commercial
    where race_latino = 1
    group by market
    union select 'NH/PI' as race_eth, count(distinct id_apcd) as id_dcount, market
    from commercial
    where race_nhpi = 1
    group by market
    union select 'White' as race_eth, count(distinct id_apcd) as id_dcount, market
    from commercial
    where race_white = 1
    group by market
    union select 'Unknown' as race_eth, count(distinct id_apcd) as id_dcount, market
    from commercial
    where race_unknown = 1
    group by market
  )
  select 
  a.market,
  a.race_eth, 
  a.id_dcount,
  b.denom,
  round(cast(a.id_dcount*1.0/b.denom*100.0 as numeric(4,1)),1) as [percent]
  from mcaid_num as a
  left join mcaid_denom as b
  on a.market = b.market
  
  union select 
  a.market,
  a.race_eth, 
  a.id_dcount,
  b.denom,
  round(cast(a.id_dcount*1.0/b.denom*100.0 as numeric(4,1)),1) as [percent]
  from mcare_num as a
  left join mcare_denom as b
  on a.market = b.market
  
  union select 
  a.market,
  a.race_eth, 
  a.id_dcount,
  b.denom,
  round(cast(a.id_dcount*1.0/b.denom*100.0 as numeric(4,1)),1) as [percent]
  from comm_num as a
  left join comm_denom as b
  on a.market = b.market;",
  .con = db_hhsaw)

result1 <- dbGetQuery(conn = db_hhsaw, statement = sql_query_1)
arrange(result1, race_eth, market)
```

<div class="kable-table">

| market     | race_eth | id_dcount |   denom | percent |
|:-----------|:---------|----------:|--------:|--------:|
| Commercial | AI/AN    |     18368 | 2111855 |     0.9 |
| Medicaid   | AI/AN    |    125866 | 2404520 |     5.2 |
| Medicare   | AI/AN    |     20049 | 1560400 |     1.3 |
| Commercial | Asian    |     84848 | 2111855 |     4.0 |
| Medicaid   | Asian    |    198277 | 2404520 |     8.2 |
| Medicare   | Asian    |     76871 | 1560400 |     4.9 |
| Commercial | Black    |     43335 | 2111855 |     2.1 |
| Medicaid   | Black    |    232514 | 2404520 |     9.7 |
| Medicare   | Black    |     46967 | 1560400 |     3.0 |
| Commercial | Latino   |     92884 | 2111855 |     4.4 |
| Medicaid   | Latino   |    589200 | 2404520 |    24.5 |
| Medicare   | Latino   |     44187 | 1560400 |     2.8 |
| Commercial | NH/PI    |     32783 | 2111855 |     1.6 |
| Medicaid   | NH/PI    |    130587 | 2404520 |     5.4 |
| Medicare   | NH/PI    |     15062 | 1560400 |     1.0 |
| Commercial | Unknown  |   1324799 | 2111855 |    62.7 |
| Medicaid   | Unknown  |    142294 | 2404520 |     5.9 |
| Medicare   | Unknown  |     91925 | 1560400 |     5.9 |
| Commercial | White    |    618541 | 2111855 |    29.3 |
| Medicaid   | White    |   1599086 | 2404520 |    66.5 |
| Medicare   | White    |   1322435 | 1560400 |    84.7 |

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
    select year(first_service_date) as service_year, count(distinct ed_pophealth_id) as ed_pophealth_dcount
    from claims.final_apcd_claim_header
    where year(first_service_date) between 2018 and 2022
      and ed_pophealth_id is not null
    group by year(first_service_date)
  ) as a
  left join (
    select year(first_service_date) as service_year, count(distinct ed_perform_id) as ed_perform_dcount
    from claims.final_apcd_claim_header
    where year(first_service_date) between 2018 and 2022
      and ed_perform_id is not null
    group by year(first_service_date)
  ) as b
  on a.service_year = b.service_year;",
  .con = db_hhsaw)

result1 <- dbGetQuery(conn = db_hhsaw, statement = sql_query_1)
arrange(result1, service_year)
```

<div class="kable-table">

| service_year | ed_pophealth_dcount | ed_perform_dcount |
|-------------:|--------------------:|------------------:|
|         2018 |             1953798 |           1672576 |
|         2019 |             1984271 |           1705812 |
|         2020 |             1633119 |           1375705 |
|         2021 |             1829830 |           1556894 |
|         2022 |             2000493 |           1711365 |

</div>

**Counting inpatient hospital stays.**  
The following code counts the total number of *distinct* acute inpatient
stays by year from 2018-2022, which includes hospitalizations for both
medical reasons and for labor and delivery.

``` r
sql_query_1 <- glue::glue_sql(
  "select year(first_service_date) as service_year, count(distinct inpatient_id) as inpatient_dcount
  from claims.final_apcd_claim_header
  where year(first_service_date) between 2018 and 2022
    and inpatient_id is not null
  group by year(first_service_date);",
  .con = db_hhsaw)

result1 <- dbGetQuery(conn = db_hhsaw, statement = sql_query_1)
arrange(result1, service_year)
```

<div class="kable-table">

| service_year | inpatient_dcount |
|-------------:|-----------------:|
|         2018 |           460702 |
|         2019 |           462832 |
|         2020 |           421495 |
|         2021 |           424347 |
|         2022 |           422957 |

</div>

**Counting primary care visits.**  
The following code counts the total number of *distinct* primary care
visits by year from 2018-2022.

``` r
sql_query_1 <- glue::glue_sql(
  "select year(first_service_date) as service_year, count(distinct pc_visit_id) as pc_visit_dcount
  from claims.final_apcd_claim_header
  where year(first_service_date) between 2018 and 2022
    and pc_visit_id is not null
  group by year(first_service_date);",
  .con = db_hhsaw)

result1 <- dbGetQuery(conn = db_hhsaw, statement = sql_query_1)
arrange(result1, service_year)
```

<div class="kable-table">

| service_year | pc_visit_dcount |
|-------------:|----------------:|
|         2018 |        13358280 |
|         2019 |        13914758 |
|         2020 |        12753318 |
|         2021 |        14187210 |
|         2022 |        14355187 |

</div>

## Identifying reasons for health care encounters (i.e., diagnoses)

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

**Leading causes of ED visits in 2022.**

``` r
sql_query_1 <- glue::glue_sql(
  "select top 10 b.ccs_superlevel_desc,
  case when count(distinct ed_pophealth_id) between 1 and 10 then null else count(distinct ed_pophealth_id) end as ed_pophealth_dcount
  from claims.final_apcd_claim_header as a
  left join ref.icdcm_codes as b
  on (a.primary_diagnosis = b.icdcm) and (a.icdcm_version = b.icdcm_version)
  where a.ed_pophealth_id is not null and year(a.first_service_date) = 2022
  group by b.ccs_superlevel_desc
  order by ed_pophealth_dcount desc;",
  .con = db_hhsaw)

result1 <- dbGetQuery(conn = db_hhsaw, statement = sql_query_1)

sql_query_2 <- glue::glue_sql(
  "select top 10 b.ccs_broad_desc,
  case when count(distinct ed_pophealth_id) between 1 and 10 then null else count(distinct ed_pophealth_id) end as ed_pophealth_dcount
  from claims.final_apcd_claim_header as a
  left join ref.icdcm_codes as b
  on (a.primary_diagnosis = b.icdcm) and (a.icdcm_version = b.icdcm_version)
  where a.ed_pophealth_id is not null and year(a.first_service_date) = 2022
  group by b.ccs_broad_desc
  order by ed_pophealth_dcount desc;",
  .con = db_hhsaw)

result2 <- dbGetQuery(conn = db_hhsaw, statement = sql_query_2)

sql_query_3 <- glue::glue_sql(
  "select top 10 b.ccs_midlevel_desc,
  case when count(distinct ed_pophealth_id) between 1 and 10 then null else count(distinct ed_pophealth_id) end as ed_pophealth_dcount
  from claims.final_apcd_claim_header as a
  left join ref.icdcm_codes as b
  on (a.primary_diagnosis = b.icdcm) and (a.icdcm_version = b.icdcm_version)
  where a.ed_pophealth_id is not null and year(a.first_service_date) = 2022
  group by b.ccs_midlevel_desc
  order by ed_pophealth_dcount desc;",
  .con = db_hhsaw)

result3 <- dbGetQuery(conn = db_hhsaw, statement = sql_query_3)

arrange(result1, desc(ed_pophealth_dcount))
```

<div class="kable-table">

| ccs_superlevel_desc              | ed_pophealth_dcount |
|:---------------------------------|--------------------:|
| Chronic diseases                 |              866438 |
| Infectious diseases              |              490502 |
| Not classified                   |              455051 |
| Injuries                         |              363820 |
| Behavioral health disorders      |              106347 |
| Pregnancy or birth complications |               64138 |
| Congenital anomalies             |                1070 |
| NA                               |                 290 |

</div>

``` r
arrange(result2, desc(ed_pophealth_dcount))
```

<div class="kable-table">

| ccs_broad_desc | ed_pophealth_dcount |
|:---|---:|
| Symptoms, signs and abnormal clinical and laboratory findings, not elsewhere classified | 408163 |
| Injury, poisoning and certain other consequences of external causes | 374582 |
| Diseases of the circulatory system | 220709 |
| Diseases of the respiratory system | 200929 |
| Certain infectious and parasitic diseases | 169886 |
| Factors influencing health status and contact with health services | 135789 |
| Diseases of the digestive system | 133570 |
| Diseases of the genitourinary system | 130109 |
| Diseases of the musculoskeletal system and connective tissue | 129707 |
| Mental, behavioral and neurodevelopmental disorders | 92372 |

</div>

``` r
arrange(result3, desc(ed_pophealth_dcount))
```

<div class="kable-table">

| ccs_midlevel_desc                                    | ed_pophealth_dcount |
|:-----------------------------------------------------|--------------------:|
| Abdominal pain                                       |              123092 |
| Viral infection                                      |              119371 |
| Immunizations and screening for infectious disease   |               89707 |
| Nonspecific chest pain                               |               82618 |
| Fractures                                            |               75469 |
| Other injuries and conditions due to external causes |               75463 |
| Other upper respiratory infections                   |               74791 |
| Superficial injury; contusion                        |               72621 |
| Other nervous system disorders                       |               64925 |
| Open wounds                                          |               63977 |

</div>

**Leading causes of inpatient stays in 2022**

``` r
sql_query_1 <- glue::glue_sql(
  "select top 10 b.ccs_superlevel_desc,
  case when count(distinct inpatient_id) between 1 and 10 then null else count(distinct inpatient_id) end as inpatient_dcount
  from claims.final_apcd_claim_header as a
  left join ref.icdcm_codes as b
  on (a.primary_diagnosis = b.icdcm) and (a.icdcm_version = b.icdcm_version)
  where a.inpatient_id is not null and year(a.first_service_date) = 2022
  group by b.ccs_superlevel_desc
  order by inpatient_dcount desc;",
  .con = db_hhsaw)

result1 <- dbGetQuery(conn = db_hhsaw, statement = sql_query_1)

sql_query_2 <- glue::glue_sql(
  "select top 10 b.ccs_broad_desc,
  case when count(distinct inpatient_id) between 1 and 10 then null else count(distinct inpatient_id) end as inpatient_dcount
  from claims.final_apcd_claim_header as a
  left join ref.icdcm_codes as b
  on (a.primary_diagnosis = b.icdcm) and (a.icdcm_version = b.icdcm_version)
  where a.inpatient_id is not null and year(a.first_service_date) = 2022
  group by b.ccs_broad_desc
  order by inpatient_dcount desc;",
  .con = db_hhsaw)

result2 <- dbGetQuery(conn = db_hhsaw, statement = sql_query_2)

sql_query_3 <- glue::glue_sql(
  "select top 10 b.ccs_midlevel_desc,
  case when count(distinct inpatient_id) between 1 and 10 then null else count(distinct inpatient_id) end as inpatient_dcount
  from claims.final_apcd_claim_header as a
  left join ref.icdcm_codes as b
  on (a.primary_diagnosis = b.icdcm) and (a.icdcm_version = b.icdcm_version)
  where a.inpatient_id is not null and year(a.first_service_date) = 2022
  group by b.ccs_midlevel_desc
  order by inpatient_dcount desc;",
  .con = db_hhsaw)

result3 <- dbGetQuery(conn = db_hhsaw, statement = sql_query_3)

arrange(result1, desc(inpatient_dcount))
```

<div class="kable-table">

| ccs_superlevel_desc              | inpatient_dcount |
|:---------------------------------|-----------------:|
| Chronic diseases                 |           172031 |
| Pregnancy or birth complications |            79444 |
| Infectious diseases              |            66385 |
| Not classified                   |            41063 |
| Behavioral health disorders      |            39347 |
| Injuries                         |            23930 |
| Congenital anomalies             |             1292 |
| NA                               |               NA |

</div>

``` r
arrange(result2, desc(inpatient_dcount))
```

<div class="kable-table">

| ccs_broad_desc | inpatient_dcount |
|:---|---:|
| Diseases of the circulatory system | 71762 |
| Certain infectious and parasitic diseases | 46804 |
| Certain conditions originating in the perinatal period | 42355 |
| Mental, behavioral and neurodevelopmental disorders | 38228 |
| Pregnancy, childbirth and the puerperium | 37118 |
| Injury, poisoning and certain other consequences of external causes | 34000 |
| Diseases of the digestive system | 33846 |
| Diseases of the respiratory system | 22306 |
| Endocrine, nutritional and metabolic diseases | 17656 |
| Neoplasms | 14727 |

</div>

``` r
arrange(result3, desc(inpatient_dcount))
```

<div class="kable-table">

| ccs_midlevel_desc                             | inpatient_dcount |
|:----------------------------------------------|-----------------:|
| Liveborn                                      |            40772 |
| Septicemia                                    |            33478 |
| Hypertension                                  |            19729 |
| Complications due to a procedure or operation |            15430 |
| Cerebrovascular disease                       |            13831 |
| Fractures                                     |            13128 |
| Mood disorders                                |            12714 |
| Viral infection                               |            11386 |
| Other gastrointestinal disorders              |            11289 |
| Diabetes mellitus                             |             8935 |

</div>

**Leading causes of primary care visits in 2022**

``` r
sql_query_1 <- glue::glue_sql(
  "select top 10 b.ccs_superlevel_desc,
  case when count(distinct pc_visit_id) between 1 and 10 then null else count(distinct pc_visit_id) end as pc_visit_dcount
  from claims.final_apcd_claim_header as a
  left join ref.icdcm_codes as b
  on (a.primary_diagnosis = b.icdcm) and (a.icdcm_version = b.icdcm_version)
  where a.pc_visit_id is not null and year(a.first_service_date) = 2022
  group by b.ccs_superlevel_desc
  order by pc_visit_dcount desc;",
  .con = db_hhsaw)

result1 <- dbGetQuery(conn = db_hhsaw, statement = sql_query_1)

sql_query_2 <- glue::glue_sql(
  "select top 10 b.ccs_broad_desc,
  case when count(distinct pc_visit_id) between 1 and 10 then null else count(distinct pc_visit_id) end as pc_visit_dcount
  from claims.final_apcd_claim_header as a
  left join ref.icdcm_codes as b
  on (a.primary_diagnosis = b.icdcm) and (a.icdcm_version = b.icdcm_version)
  where a.pc_visit_id is not null and year(a.first_service_date) = 2022
  group by b.ccs_broad_desc
  order by pc_visit_dcount desc;",
  .con = db_hhsaw)

result2 <- dbGetQuery(conn = db_hhsaw, statement = sql_query_2)

sql_query_3 <- glue::glue_sql(
  "select top 10 b.ccs_midlevel_desc,
  case when count(distinct pc_visit_id) between 1 and 10 then null else count(distinct pc_visit_id) end as pc_visit_dcount
  from claims.final_apcd_claim_header as a
  left join ref.icdcm_codes as b
  on (a.primary_diagnosis = b.icdcm) and (a.icdcm_version = b.icdcm_version)
  where a.pc_visit_id is not null and year(a.first_service_date) = 2022
  group by b.ccs_midlevel_desc
  order by pc_visit_dcount desc;",
  .con = db_hhsaw)

result3 <- dbGetQuery(conn = db_hhsaw, statement = sql_query_3)

arrange(result1, desc(pc_visit_dcount))
```

<div class="kable-table">

| ccs_superlevel_desc              | pc_visit_dcount |
|:---------------------------------|----------------:|
| Chronic diseases                 |         6532270 |
| Not classified                   |         3487793 |
| Infectious diseases              |         1965985 |
| Behavioral health disorders      |         1675220 |
| Injuries                         |          505650 |
| Pregnancy or birth complications |          237175 |
| Congenital anomalies             |           28837 |
| NA                               |             399 |

</div>

``` r
arrange(result2, desc(pc_visit_dcount))
```

<div class="kable-table">

| ccs_broad_desc | pc_visit_dcount |
|:---|---:|
| Factors influencing health status and contact with health services | 3073607 |
| Mental, behavioral and neurodevelopmental disorders | 1572034 |
| Symptoms, signs and abnormal clinical and laboratory findings, not elsewhere classified | 1546494 |
| Diseases of the musculoskeletal system and connective tissue | 1302071 |
| Diseases of the circulatory system | 1030225 |
| Endocrine, nutritional and metabolic diseases | 970546 |
| Diseases of the respiratory system | 778489 |
| Injury, poisoning and certain other consequences of external causes | 666339 |
| Diseases of the genitourinary system | 586605 |
| Diseases of the nervous system | 544825 |

</div>

``` r
arrange(result3, desc(pc_visit_dcount))
```

<div class="kable-table">

| ccs_midlevel_desc | pc_visit_dcount |
|:---|---:|
| Medical examination/evaluation | 1758424 |
| Immunizations and screening for infectious disease | 757120 |
| Diabetes mellitus | 544127 |
| Other skin disorders | 534104 |
| Hypertension | 511317 |
| Mood disorders | 479361 |
| Other nervous system disorders | 473668 |
| Other upper respiratory infections | 431149 |
| Musculoskeletal pain (not low back pain) | 430220 |
| Spondylosis; intervertebral disc disorders; other back problems | 421232 |

</div>

## Change log

- May 2026: Initial version released.
