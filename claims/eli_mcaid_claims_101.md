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

<div data-pagedtable="false">

<script data-pagedtable-source type="application/json">
{"columns":[{"label":["race_eth"],"name":[1],"type":["chr"],"align":["left"]},{"label":["id_dcount"],"name":[2],"type":["int"],"align":["right"]}],"data":[{"1":"AI/AN","2":"37172"},{"1":"Asian","2":"145570"},{"1":"Black","2":"187825"},{"1":"Latino","2":"194628"},{"1":"NH/PI","2":"80267"},{"1":"Unknown","2":"140605"},{"1":"White","2":"567704"}],"options":{"columns":{"min":{},"max":[10]},"rows":{"min":[10],"max":[10]},"pages":{}}}
  </script>

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

<div data-pagedtable="false">

<script data-pagedtable-source type="application/json">
{"columns":[{"label":["race_eth_me"],"name":[1],"type":["chr"],"align":["left"]},{"label":["id_dcount"],"name":[2],"type":["int"],"align":["right"]}],"data":[{"1":"AI/AN","2":"16556"},{"1":"Asian","2":"120473"},{"1":"Black","2":"149297"},{"1":"Latino","2":"92745"},{"1":"Multiple","2":"155040"},{"1":"NH/PI","2":"54407"},{"1":"Unknown","2":"140605"},{"1":"White","2":"450610"}],"options":{"columns":{"min":{},"max":[10]},"rows":{"min":[10],"max":[10]},"pages":{}}}
  </script>

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

<div data-pagedtable="false">

<script data-pagedtable-source type="application/json">
{"columns":[{"label":["age_min"],"name":[1],"type":["dbl"],"align":["right"]},{"label":["age_max"],"name":[2],"type":["dbl"],"align":["right"]},{"label":["age_mean"],"name":[3],"type":["dbl"],"align":["right"]}],"data":[{"1":"0","2":"123","3":"34.6"}],"options":{"columns":{"min":{},"max":[10]},"rows":{"min":[10],"max":[10]},"pages":{}}}
  </script>

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
  select count(distinct id_mcaid)
  from cov_2023
  where custom_cov_time_day >= 1;",
  .con = db_hhsaw)

result1 <- dbGetQuery(conn = db_hhsaw, statement = sql_query_1)
result1
```

<div data-pagedtable="false">

<script data-pagedtable-source type="application/json">
{"columns":[{"label":[""],"name":[1],"type":["int"],"align":["right"]}],"data":[{"1":"606890"}],"options":{"columns":{"min":{},"max":[10]},"rows":{"min":[10],"max":[10]},"pages":{}}}
  </script>

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
  select count(distinct id_mcaid)
  from cov_2023
  where custom_cov_time_day*1.0/{reference_days}*100.0 >= 50.0;",
  .con = db_hhsaw)

result1 <- dbGetQuery(conn = db_hhsaw, statement = sql_query_1)
result1
```

<div data-pagedtable="false">

<script data-pagedtable-source type="application/json">
{"columns":[{"label":[""],"name":[1],"type":["int"],"align":["right"]}],"data":[{"1":"464202"}],"options":{"columns":{"min":{},"max":[10]},"rows":{"min":[10],"max":[10]},"pages":{}}}
  </script>

</div>

**Assigning people to a single geography for a given measurement
window.**  
People move and thus when conducting an analysis for a given measurement
window (let’s use 2023 again), we often want to assign each person only
once to geographic concepts, such as ZIP code of residence, to avoid
people being counted more than once in a descriptive analysis.

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

<div data-pagedtable="false">

<script data-pagedtable-source type="application/json">
{"columns":[{"label":["geo_zip"],"name":[1],"type":["chr"],"align":["left"]},{"label":["id_dcount"],"name":[2],"type":["int"],"align":["right"]}],"data":[{"1":"98003","2":"28026"},{"1":"98002","2":"24223"},{"1":"98032","2":"21613"},{"1":"98023","2":"21508"},{"1":"98030","2":"20847"},{"1":"98118","2":"20246"},{"1":"98031","2":"19349"},{"1":"98168","2":"18280"},{"1":"98198","2":"16811"},{"1":"98092","2":"16669"},{"1":"98001","2":"15879"},{"1":"98042","2":"15542"},{"1":"98133","2":"15516"},{"1":"98188","2":"13714"},{"1":"98058","2":"13141"},{"1":"98125","2":"11474"},{"1":"98144","2":"10974"},{"1":"98146","2":"10878"},{"1":"98108","2":"10869"},{"1":"98034","2":"10811"},{"1":"98178","2":"10768"},{"1":"98056","2":"10633"},{"1":"98052","2":"10423"},{"1":"98122","2":"9944"},{"1":"98104","2":"9550"},{"1":"98106","2":"9407"},{"1":"98055","2":"9072"},{"1":"98155","2":"9008"},{"1":"98059","2":"8564"},{"1":"98103","2":"8184"},{"1":"98115","2":"7930"},{"1":"98105","2":"7867"},{"1":"98007","2":"7770"},{"1":"98126","2":"6800"},{"1":"98038","2":"6701"},{"1":"98006","2":"6122"},{"1":"98022","2":"6008"},{"1":"98166","2":"5566"},{"1":"98148","2":"5244"},{"1":"98057","2":"5241"},{"1":"98033","2":"5100"},{"1":"98101","2":"4938"},{"1":"98011","2":"4928"},{"1":"98121","2":"4715"},{"1":"98004","2":"4587"},{"1":"98008","2":"4506"},{"1":"98109","2":"4451"},{"1":"98028","2":"4375"},{"1":"98027","2":"4324"},{"1":"98107","2":"4294"},{"1":"98117","2":"4178"},{"1":"98102","2":"4150"},{"1":"98029","2":"4061"},{"1":"98116","2":"3785"},{"1":"98047","2":"3752"},{"1":"98119","2":"3299"},{"1":"98005","2":"3018"},{"1":"98112","2":"2868"},{"1":"98072","2":"2697"},{"1":"98177","2":"2618"},{"1":"98070","2":"2562"},{"1":"98053","2":"2363"},{"1":"98045","2":"2232"},{"1":"98040","2":"2224"},{"1":"98199","2":"2216"},{"1":"98136","2":"2104"},{"1":"98074","2":"2104"},{"1":"98065","2":"2075"},{"1":"98019","2":"1890"},{"1":"98075","2":"1883"},{"1":"98010","2":"1365"},{"1":"98014","2":"1180"},{"1":"98077","2":"1058"},{"1":"98024","2":"804"},{"1":"98051","2":"700"},{"1":"98354","2":"444"},{"1":"98134","2":"443"},{"1":"98039","2":"162"},{"1":"98195","2":"152"},{"1":"98009","2":"129"},{"1":"98062","2":"102"},{"1":"98288","2":"88"},{"1":"98071","2":"81"},{"1":"98224","2":"77"},{"1":"98063","2":"69"},{"1":"98093","2":"64"},{"1":"98111","2":"51"},{"1":"98064","2":"50"},{"1":"98050","2":"38"},{"1":"98138","2":"33"},{"1":"98025","2":"32"},{"1":"98083","2":"32"},{"1":"98035","2":"30"},{"1":"98145","2":"28"},{"1":"98114","2":"28"},{"1":"98068","2":"27"},{"1":"98127","2":"20"},{"1":"98015","2":"19"},{"1":"98113","2":"17"},{"1":"98165","2":"15"},{"1":"98073","2":"11"},{"1":"98089","2":"NA"},{"1":"98194","2":"NA"},{"1":"98041","2":"NA"},{"1":"98175","2":"NA"},{"1":"98013","2":"NA"},{"1":"98251","2":"NA"},{"1":"98139","2":"NA"},{"1":"98160","2":"NA"},{"1":"98141","2":"NA"},{"1":"98161","2":"NA"},{"1":"98124","2":"NA"},{"1":"98174","2":"NA"},{"1":"98131","2":"NA"},{"1":"98164","2":"NA"},{"1":"98185","2":"NA"}],"options":{"columns":{"min":{},"max":[10]},"rows":{"min":[10],"max":[10]},"pages":{}}}
  </script>

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

<div data-pagedtable="false">

<script data-pagedtable-source type="application/json">
{"columns":[{"label":["service_year"],"name":[1],"type":["int"],"align":["right"]},{"label":["ed_pophealth_dcount"],"name":[2],"type":["int"],"align":["right"]},{"label":["ed_perform_dcount"],"name":[3],"type":["int"],"align":["right"]}],"data":[{"1":"2018","2":"253029","3":"232439"},{"1":"2019","2":"249888","3":"229344"},{"1":"2020","2":"198647","3":"181788"},{"1":"2021","2":"227801","3":"208541"},{"1":"2022","2":"245984","3":"227378"}],"options":{"columns":{"min":{},"max":[10]},"rows":{"min":[10],"max":[10]},"pages":{}}}
  </script>

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

<div data-pagedtable="false">

<script data-pagedtable-source type="application/json">
{"columns":[{"label":["service_year"],"name":[1],"type":["int"],"align":["right"]},{"label":["inpatient_dcount"],"name":[2],"type":["int"],"align":["right"]}],"data":[{"1":"2018","2":"26926"},{"1":"2019","2":"29048"},{"1":"2020","2":"28191"},{"1":"2021","2":"33690"},{"1":"2022","2":"31837"}],"options":{"columns":{"min":{},"max":[10]},"rows":{"min":[10],"max":[10]},"pages":{}}}
  </script>

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

<div data-pagedtable="false">

<script data-pagedtable-source type="application/json">
{"columns":[{"label":["service_year"],"name":[1],"type":["int"],"align":["right"]},{"label":["pc_visit_dcount"],"name":[2],"type":["int"],"align":["right"]}],"data":[{"1":"2018","2":"1108715"},{"1":"2019","2":"1054307"},{"1":"2020","2":"921956"},{"1":"2021","2":"1066642"},{"1":"2022","2":"1009858"}],"options":{"columns":{"min":{},"max":[10]},"rows":{"min":[10],"max":[10]},"pages":{}}}
  </script>

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

<div data-pagedtable="false">

<script data-pagedtable-source type="application/json">
{"columns":[{"label":["ccs_superlevel_desc"],"name":[1],"type":["chr"],"align":["left"]},{"label":["inpatient_dcount"],"name":[2],"type":["int"],"align":["right"]}],"data":[{"1":"Pregnancy or birth complications","2":"9632"},{"1":"Chronic diseases","2":"8355"},{"1":"Behavioral health disorders","2":"5764"},{"1":"Infectious diseases","2":"4359"},{"1":"Not classified","2":"2143"},{"1":"Injuries","2":"1639"},{"1":"Congenital anomalies","2":"118"}],"options":{"columns":{"min":{},"max":[10]},"rows":{"min":[10],"max":[10]},"pages":{}}}
  </script>

</div>

``` r
arrange(result2, desc(inpatient_dcount))
```

<div data-pagedtable="false">

<script data-pagedtable-source type="application/json">
{"columns":[{"label":["ccs_broad_desc"],"name":[1],"type":["chr"],"align":["left"]},{"label":["inpatient_dcount"],"name":[2],"type":["int"],"align":["right"]}],"data":[{"1":"Certain conditions originating in the perinatal period","2":"5846"},{"1":"Mental, behavioral and neurodevelopmental disorders","2":"5727"},{"1":"Pregnancy, childbirth and the puerperium","2":"4476"},{"1":"Certain infectious and parasitic diseases","2":"3091"},{"1":"Diseases of the circulatory system","2":"2714"},{"1":"Diseases of the digestive system","2":"1860"},{"1":"Injury, poisoning and certain other consequences of external causes","2":"1738"},{"1":"Endocrine, nutritional and metabolic diseases","2":"1473"},{"1":"Diseases of the respiratory system","2":"1312"},{"1":"Diseases of the genitourinary system","2":"625"}],"options":{"columns":{"min":{},"max":[10]},"rows":{"min":[10],"max":[10]},"pages":{}}}
  </script>

</div>

``` r
arrange(result3, desc(inpatient_dcount))
```

<div data-pagedtable="false">

<script data-pagedtable-source type="application/json">
{"columns":[{"label":["ccs_midlevel_desc"],"name":[1],"type":["chr"],"align":["left"]},{"label":["inpatient_dcount"],"name":[2],"type":["int"],"align":["right"]}],"data":[{"1":"Liveborn","2":"5618"},{"1":"Schizophrenia and other psychotic disorders","2":"2371"},{"1":"Septicemia","2":"2242"},{"1":"Mood disorders","2":"1896"},{"1":"Hypertension","2":"1124"},{"1":"Diabetes mellitus","2":"891"},{"1":"Complications due to a procedure or operation","2":"747"},{"1":"Alcohol-related disorders","2":"744"},{"1":"Complications during labor","2":"742"},{"1":"Viral infection","2":"671"}],"options":{"columns":{"min":{},"max":[10]},"rows":{"min":[10],"max":[10]},"pages":{}}}
  </script>

</div>
