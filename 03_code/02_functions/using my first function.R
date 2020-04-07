#set the working directory
#rename "your User Name here" based on your user name
#example: owner, Emily, Bill
getwd()
setwd("C:/Users/miked/OneDrive/Statistics/R/Projects/nuiphao/Grinding-screen-panel-comparison/2014/code/Functions")
# currwd 
getwd()

#make some data
data<- seq(from=1, to=10, by=1)
data

#import the function
source("f_myfirstfunction.R")
#call the function
my_function(data)
#call the function
data2 <- times2(data)
