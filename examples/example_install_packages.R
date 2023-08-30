# When you update R or have a fresh installation, you will have to reinstall packages
# Running this script shoudl install most of the packages commonly used by APDE
# Be sure to run it to the very end so that you install the APDE custom package

# install standard packages used by APDE
install.packages(c('broom', 
                   'configr', 
                   'cronR', 
                   'data.table', 
                   'DBI', 
                   'dbplyr', 
                   'devtools', 
                   'epiR', 
                   'flexdashboard', 
                   'future', 
                   'fuzzyjoin', 
                   'geepack', 
                   'geosphere', 
                   'ggmap', 
                   'ggplot2', 
                   'ggrepel', 
                   'glue', 
                   'haven', 
                   'Hmisc', 
                   'hrbrtheme', 
                   'httr', 
                   'janitor', 
                   'jsonlite', 
                   'kable', 
                   'kableExtra', 
                   'keyring', 
                   'knitr', 
                   'lme4', 
                   'lubridate', 
                   'odbc', 
                   'openxlsx', 
                   'pacman', 
                   'pacman', 
                   'pdftools', 
                   'plotly', 
                   'purrr', 
                   'RColorBrewer', 
                   'RCurl', 
                   'readxl', 
                   'RecordLinkage', 
                   'remotes', 
                   'rmarkdown', 
                   'sandwich', 
                   'sf', 
                   'snakecase', 
                   'srvyr', 
                   'Stringdist', 
                   'survey', 
                   'survival',
                   'targets', 
                   'tidycensus', 
                   'tidyverse', 
                   'tinytex', 
                   'tmap', 
                   'tmaphelper', 
                   'viridis', 
                   'vroom', 
                   'xml2', 
                   'xtable', 
                   'yaml', 
                   'zoo'))


# Install PHSKC packages
remotes::install_github("PHSKC-APDE/rads", auth_token = NULL)
remotes::install_github('https://github.com/PHSKC-APDE/spatagg')
remotes::install_github('https://github.com/PHSKC-APDE/kcparcelpop/')


# The end!