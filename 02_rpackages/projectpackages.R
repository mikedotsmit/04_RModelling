# packages
# this is the central place where this project will attach packages from.
# allpackeges are accumulated here (manualy).
# 
# the reason for doing this is to avoid duplicating all packages across all files.
# this eases knitting from both the 'mother-' or base.Rmd and knitting from individual files as well.
# add new packes in the list below names "mypackages" then
# run the chunck code. the chunk will write a csv file that the other files contained within the prject folder will read and attach. 

library(easypackages)
library(here)

mypackage <- c("magick", "rmd","patchwork","tidyverse","kableExtra","conflicted","tinytex","tidyverse","readxl","modelr","broom","reshape","readr","kableExtra","magrittr","qwraps2","xtable","gridExtra","svglite")

libraries(mypackage) #attaches packages
#packages(mypackage) #checks installed, installs, attaches.

# exclude from packages vector as include in "rmd" families package: "knitr",

### Software installed per Rstudio recommendation
#Ghostscript ("for using magick package for LaTeX in HTML and Word) 
#https://www.ghostscript.com/
#HaoZhu's recommendation on page 25 of https://haozhu233.github.io/kableExtra/awesome_table_in_pdf.pdf