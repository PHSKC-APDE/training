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
                   'here',
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
                   'Microsoft365R',
                   'odbc',
                   'openxlsx',
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


# Install Public PHSKC packages
remotes::install_github("PHSKC-APDE/rads", auth_token = NULL)
remotes::install_github("PHSKC-APDE/claims_data")
remotes::install_github('https://github.com/PHSKC-APDE/spatagg')
remotes::install_github('https://github.com/PHSKC-APDE/kcparcelpop/')

# Install Private PHSKC packages
message('\U0001f6a8\U1F6D1\U0001f6a8!!!\n',
        'To install private packages, you will need to ensure your GitHub credentials are up to date.\n',
        'The best way to do this is to follow the instructions in the apde.data README:\n',
        'https://github.com/PHSKC-APDE/apde.data/blob/main/README.md')
remotes::install_github("PHSKC-APDE/apde.data", auth_token = NULL)


# The end!
