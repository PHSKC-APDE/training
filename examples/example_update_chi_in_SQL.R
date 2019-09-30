##### Sample code for updating indicator data in SQL ######
##### Abby Schachter 
##### 9/30/2019


library(odbc) # Read to and write from SQL

# connect to SQL servers
db_extract51 <- dbConnect(odbc(), "PHExtractStore51")
db_extract50 <- dbConnect(odbc(), "PHExtractStore50")



## Output from analyses should include tables for Results, Metadata, Titles, and Table of Contents (ToC) 
## in the Tableau-ready output format



## UPDATE RESULTS TABLE WITH NEW INDICATORS (edit table names and indicators as needed)
dbGetQuery(db_extract51,
           
           "DELETE APDE_WIP.hys_results 
           WHERE indicator_key IN 
           ('tanytob_nv1', 't_smk30d', 'ecig_vape', 'marij30day', 't_smkany')")


dbWriteTable(db_extract51,
             name = DBI::Id(schema = "APDE_WIP", table = "hys_results"),
             value = hys_chi_tobacco_mj,
             overwrite = F, append = T)


#### UPDATE METADATA ####

### overwrite metadata table
### use overwrite = T if rewriting the entire table, otherwise use append = T if updating specific rows

dbWriteTable(db_extract51,
             DBI::Id(schema = "APDE_WIP", table = "hys_metadata"),
             hys_meta_join, overwrite = T, append = F)


#### UPDATE TABLE OF CONTENTS ####

### Drop rows in current TOC
dbGetQuery(db_extract51,
           "DELETE FROM APDE_WIP.indicators_toc
           WHERE indicator_key IN 
           ('tanytob_nv1', 't_smk30d', 'ecig_vape', 'marij30day', 't_smkany')")

### Add new rows
dbWriteTable(db_extract51,
             name = DBI::Id(schema = "APDE_WIP", table = "indicators_toc"),
             value = hys_toc,
             overwrite = F, append = T)


#### UPDATE TITLES ####

### Drop rows in current titles
dbGetQuery(db_extract51,
           "DELETE FROM APDE_WIP.indicators_titles
           WHERE indicator_key IN 
           ('tanytob_nv1', 't_smk30d', 'ecig_vape', 'marij30day', 't_smkany')")

### Add new rows
dbWriteTable(db_extract51,
             name = DBI::Id(schema = "APDE_WIP", table = "indicators_titles"),
             value = hys_titles,
             overwrite = F, append = T)


