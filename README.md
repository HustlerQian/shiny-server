# shiny-server
Settings:
https://deanattali.com/2015/05/09/setup-rstudio-shiny-server-digital-ocean/
Install package by root account:
sudo su - -c "R -e \"install.packages('plotly', repos='http://cran.rstudio.com/')\""
sudo su - -c "R -e \"devtools::install_github('mjktfw/limma')\""

sudo su - -c "R -e \"source('https://bioconductor.org/biocLite.R');biocLite('limma')\""