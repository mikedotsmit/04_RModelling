knitr::opts_chunk$set(echo = FALSE, warning=FALSE,message=FALSE)
knitr::opts_chunk$set(fig.align="center")
# *Load R packages used in this code:*
library(ggplot2)
library(here)
library(conflicted)
library(markdown)
library(tinytex)
library(tidyverse)
library(readxl)
library(modelr)
library(broom)
library(reshape)
library(readr)
library(knitr)
library(kableExtra)
library(magrittr)
#devtools::install_github("username/packagename")
knitr.table.format = "latex" #global option for tables. can still set any in each kable function.
#excellent for LaTeX equaitons:(probable keep this in bib)
#http://visualmatheditor.equatheque.net/VisualMathEditor.html


#pull in the data, try to give descriptive name: in this case 'gramdata'.
gramdata <- read_csv(here("data", "test-31aug-2014-csv.csv")) #read here to see ,ore about "here::here" function (https://malco.io/2018/11/05/why-should-i-use-the-here-package-when-i-m-already-using-projects/)


#save imported data as a tibble..convenient type of data frame for further processing.
gramdata <- as_tibble(gramdata)

# each screen has 5 decks and here ill average these. "deck_0" is a sample taken from the distributor that feeds the screen and thus represents all 5 decks. in this excercise ill combine the distributor sample with th decks to compile a mean.

# In this excercise ill focus on the means of the distributions.
#separating x and y eases calculation steps 

sieve <- gramdata %>% 
  select(1) %>% 
  as_tibble(as.data.frame(.))
#now to save the out put so it cab reused in the report:
# there no confusion when i use the term "takeout" (like pizza) i.e. take from here to smw else.
# simmilarlt, Im trying "BrinIn" on the other end (the child of the mother file where this code will be brought in .)
##I should have a lis tin thie beginning  of this script detailing a list of these depencansies, so one can see at 1st glance the risk of changing code.
##as well as (maybe) a key section detailing terms used for objects.

takeOut_sieve <- here("code/code-output","sieves-used-in-psd.txt")

write.table(sieve, takeOut_sieve, sep=",", quote = FALSE)
#dependents: methodSection.Rmd, code-output folder.

#here excluding the sieve (first) column.
gramdata1 <- gramdata %>%
  dplyr::select(-1) %>%   #dplyr::select(2:ncol(.)) %>%
  as_tibble()

#calculating %mass retained for all samples.

pct <- gramdata1 %>% #mass percentage
  mutate_all ( ~(./sum(.)))

#separating feed stream data from that of Over and undersize.
#calculate means at the same time.

###############
###########

# Means

# Two plant screen tested for comparison. Each plant screen has 5 decks.
# In this test we'll average the results of the five decks. We can (and should) also have a look at the variability between the 5 decks to see if all results look plausible.
#The two screen are called "screen13" and "screen14".
#Results of screen13's feed samples are located in columns 1:6, thus we select columns 1:6 and calculate their withi the dplyr's mutate function.
feed13 <- pct %>% 
  dplyr::select(1:6) %>%   #check in the data which columns contain the data stream to be averaged.
  mutate(F13m = rowMeans(.)) #mutate creates the new colu,m with mean mass percent data.

#pull this mean column out as a vector to use later:
F13m <- feed13$F13m 

#underpan from screen 13 only allowed for 1 sample to be taken and this sample represent all the decks and thus we rename it as the mean.
US13m <- pct %>%  
  dplyr::select(US13_0, "US13m" = "US13_0") 


osize13 <- pct %>% 
  dplyr::select(8:12) %>% 
  mutate(OS13m=rowMeans(.))
OS13m <- osize13$OS13m


feed14 <- pct %>% 
  dplyr::select(13:18) %>%   #check in the data which columns contain the data stream to be averaged.
  mutate(F14m = rowMeans(.)) #mutate creates the new colu,m with mean mass percent data.
F14m <- feed14$F14m


US14m <- pct %>%  
  dplyr::select(US14_0, "US14m" = "US14_0") 

osize14 <- pct %>% 
  dplyr::select(20:24) %>% 
  mutate(mean = rowMeans(.)) 
OS14m <- osize14$mean

## plotting raw feed distribution to have a quick view if they are simmilar. if they are not (simmilar) then the expeririment or test will not not give conclusive results. as our aim is to test if one panel size is "signifficantly" better than another panels size.

feedraw <- cbind(sieve,F13m,F14m) 

long_feedraw <- feedraw %>% 
  pivot_longer(-sieve, names_to= "stream" , values_to = "probability")
  

quickfeedplot_unmodelled <- ggplot(long_feedraw, aes(sieve, probability, colour = stream)) +
  geom_line()


#save the data that created the chart so it can be easily called from the final report.
# two way of ding this:
#1 save the chart object [rds], or
#2 save the data that can produce the chart object [CSV]
#method1:
#output_file <- here("code/code-output","feed_unmoddeled.RDS")  #https://www.middleprofessor.com/files/applied-biostatistics_bookdown/_book/data-reading-writing-and-wrangling.html
#saveRDS(object = quickfeedplot_unmodelled, file = output_file)
#method2:

takeout_file <- here("code/code-output","long_feedraw.txt")
write.table(long_feedraw, file = takeout_file, sep=",", quote = FALSE)
#dependents: methodSection



# plot on the finer sizes look visibly simmilar up to arounfd 300um.
#reaching 600um a steady differences is obvious..but "not" large..and not increasing markably.
### ok continue##

#bring all the screen stream means together.
#In the following steps, we'll be applying the transformations. these transformations involve logs, as these logs  will be applied to cummulative percentage values, the last and largest will be 1, and log of 1 is 0, and the second log (log of 0) is "-inf,
#thus i''ll exclude the last row using dplyr::slice (::filter does work anymore (tidyverse update)).

meanpct <- cbind(sieve, F13m, OS13m, US13m, F14m, OS14m, US14m)

#here the vector "meanpct" contains all stream averages. In certain circumstances this would ok. In this case, its not:
# the streams US13m and US14m have zero mass retained in the first bin of the particle size distribution (largest screen). 
#We know we're going to use log transforms and logs of zero mass = -Inf. 
#Thus we'll have to apply our models separately to the two parts of our data (due to their difference in vector lengths).
# i'll keep vector "meanpct" but also separate them and then apply the linear models on the two groups separately:
#there must a shorter way to ignore nas..[add to to do]
meanpct_excl_US <- cbind(sieve, F13m, OS13m, F14m, OS14m)

sieve_sliced <- sieve %>% 
  dplyr::slice(2:n()) #also have to prepare the x(sieve) vector to be the same n() as y (in the case of the undersize streams).(https://dplyr.tidyverse.org/reference/slice.html)

sliced_US13m <- US13m %>% 
  dplyr::slice(2:n())

sliced_US14m <- US14m %>% 
  dplyr::slice(2:n())

#combine the sliced vectors 
meanpct_US13and14 <- cbind(sieve_sliced, sliced_US13m, sliced_US14m)

mean1 <- meanpct_excl_US
  
mean2 <- meanpct_US13and14
  
#the work done here ontop is not automated and the engineer has to look think do depending on the data.

#As we have two 'sets' of data primarily because of different lengths of data points (1st screen pan had 0 grams in the largest size fraction for the Us samples),
#thus we'll do two code sets of regressions. Done simmilarly but just separately..we've already prepared the data ontop.


#rearange in long format (tidy data) to enable grouping in following step.    
#because we divided the data into groups, we'll everystep prior to and incl. the modeling in two steps aswell.
long1 <- mean1 %>% 
  pivot_longer(-sieve, names_to= "stream" , values_to = "probability") # opposite is :pivot_wider(names_from= stream, values_from = probs). use quotes when names do not yet exist, if exist ,; no quotes.

long2 <- mean2 %>% 
  pivot_longer(-sieve, names_to= "stream" , values_to = "probability") 

####plot
#feed and OS
quickfeedplot_unmodelled2 <- ggplot(long1, aes(sieve, probability, colour = stream)) +
  geom_line()

print(quickfeedplot_unmodelled2)
#US only
quickfeedplot_unmodelled3 <- ggplot(long2, aes(sieve, probability, colour = stream)) +
  geom_line()

print(quickfeedplot_unmodelled3)
###end plot

#here the cummulative passing and retained mass percentages of each stream is calculated (with dplyr::mutate),
#followed by applied the Rosin Rammler- as well as the Gates-Gaudin-Schumann distribution transformations.
#the formulas are descibed in the .rmd writeup in Latex.
transformations1 <- long1 %>% 
  group_by (stream)%>% 
  mutate (cumret = cumsum(probability)) %>%
  select (-probability) %>%
  dplyr::slice(1:11) %>% #dplyr::filter worked here previously, but now doesn't anymore. dplyr::slice works with exact same syntax as ::filter did.
  mutate (cumpass = 1-cumret) %>%
    #Rosin Rammler transforms:
  mutate (
    RRx = log(sieve),
    RRy = log(log(1/cumret)),
    # Gauss Gaudin Shumann transforms:
    GGS_x = log(sieve),
    GGS_y = log(cumret))  %>%
  
  mutate_if(is.numeric, list(~na_if(., -Inf)))%>% #removes -Infinities and replace with NA. This required as we took logs of 0 (sieve) and 1 (cumret).
  nest() 
# Nesting is often useful for creating per group models

transformations2 <- long2 %>% 
  group_by (stream)%>% 
  mutate (cumret = cumsum(probability)) %>%
  select (-probability) %>%
  dplyr::slice(1:10) %>% #i select rows 1 to 10 as we've already removed row1 in the previous step with 'slice' 2:n(). 
  mutate (cumpass = 1-cumret) %>%
  #Rosin Rammler transforms:
  mutate (
    RRx = log(sieve),
    RRy = log(log(1/cumret)),
    # Gauss Gaudin Shumann transforms:
    GGS_x = log(sieve),
    GGS_y = log(cumret))  %>%
  
  mutate_if(is.numeric, list(~na_if(., -Inf)))%>% #removes -Infinities and replace with NA. This required as we took logs of 0 (sieve) and 1 (cumret).
  nest() 

#continuing with two sets, we'll have two sets of regressions:
regression1 <- transformations1 %>% 
  mutate(
    #RRmodel
    #tidy, glance and augment are funtions from the broom package that helps extraxt model details.
    RRmodels = lapply(data, function(df) lm(RRy ~ RRx, data = df)),# "RRmodels" column will be created in the mutate.
    tidied_RR = map (RRmodels, tidy), 
    glanced_RR = map(RRmodels, glance),
    augmented_RR = map (RRmodels, augment),
    
    #GGS model    
    GGS_models = lapply(data, function(df) lm(GGS_y ~ GGS_x, data = df)),# "GGS_models" column will be created in the mutate.
    tidied_GGS = map (GGS_models, tidy), 
    glanced_GGS = map(GGS_models, glance),
    augmented_GGS = map (GGS_models, augment)
  ) 




regression2 <- transformations2 %>% 
  mutate(
    #RRmodel
    #tidy, glance and augment are funtions from the broom package that helps extraxt model details.
    RRmodels = lapply(data, function(df) lm(RRy ~ RRx, data = df)),# "RRmodels" column will be created in the mutate.
    tidied_RR = map (RRmodels, tidy), 
    glanced_RR = map(RRmodels, glance),
    augmented_RR = map (RRmodels, augment),
    
    #GGS model    
    GGS_models = lapply(data, function(df) lm(GGS_y ~ GGS_x, data = df)),# "GGS_models" column will be created in the mutate.
    tidied_GGS = map (GGS_models, tidy), 
    glanced_GGS = map(GGS_models, glance),
    augmented_GGS = map (GGS_models, augment)
  ) 


#####

#unnest two list at sme gives issues after dplyr update? 
#so for now we'll unnest individually..

# tidy_reg_RR_GGS_1 <-regression1 %>% 
#   unnest(c(tidied_RR,tidied_GGS))

#exctract regression analasese twice
#once for both parts of regression1
tidy_reg_RR_1 <-regression1 %>% 
  unnest(tidied_RR)

tidy_reg_GGS_1 <-regression1 %>% 
  unnest(tidied_GGS)

#once for both parts of regression2
tidy_reg_RR_2 <-regression2 %>% 
  unnest(tidied_RR)

tidy_reg_GGS_2 <-regression2 %>% 
  unnest(tidied_GGS) 



# the required regression data is now unnested but mixed with all the other lists and data.
#now pull out or select the relevent data.

#i do quick check if i can print tables in .rmd mother report (currently named "grams3-report-name.RMD")
# to prevent the .RMD file to all the script from this .R script, we help .RMD identify wich code to use:


Coef_RR1 <- tidy_reg_RR_1 %>% 
  dplyr::select(stream,term, estimate)


## @knitr coefprint1
table_RR1Coef_RR1 <-Coef_RR1%>% kable

## @knitr coefprint2
## @knitr coefprint3


Coef_RR2 <- tidy_reg_RR_2 %>% 
  dplyr::select(stream,term, estimate)

Coef_GGS1 <- tidy_reg_GGS_1 %>% 
  dplyr::select(stream,term, estimate)

Coef_GGS2 <- tidy_reg_GGS_2 %>% 
  dplyr::select(stream,term, estimate)

#it mihgt be worth it to separate each stream's coefficients in its own dataframe.
#this should ease creation or presentation of the regression formulas.





###########


glanced_reg_RR_1 <-regression1 %>% 
  unnest(glanced_RR)

glanced_reg_GGS_1 <-regression1 %>% 
  unnest(glanced_GGS)

#once for both parts of regression2
glanced_reg_RR_2 <-regression2 %>% 
  unnest(glanced_RR)

glanced_reg_GGS_2 <-regression2 %>% 
  unnest(glanced_GGS)


#statistical measures of model fit.
#Coefficient of determination (r^2).
coef_deter_RR1 <- glanced_reg_RR_1 %>% 
  select(stream, r.squared, adj.r.squared, p.value, AIC)

coef_deter_RR2 <- glanced_reg_RR_2 %>% 
  select(stream, r.squared, adj.r.squared, p.value, AIC)

coef_deter_GGS1 <- glanced_reg_GGS_1 %>% 
  select(stream, r.squared, adj.r.squared, p.value, AIC)

coef_deter_GGS2 <- glanced_reg_GGS_2 %>% 
  select(stream, r.squared, adj.r.squared, p.value, AIC)

R2_RR <- full_join(coef_deter_RR1,coef_deter_RR2)
R2_GGS <- full_join(coef_deter_GGS1,coef_deter_GGS2)


write.table(R2_RR, file = here("code/code-output","R2_RR.txt"), sep=",", quote = FALSE)

write.table(R2_GGS, file = here("code/code-output","R2_GGS.txt"), sep=",", quote = FALSE)

########################




# tidy_reg_RR_GGS%>% 
#   unnest (glanced_RR)
# tidy_reg_RR_GGS%>% 
#   unnest(augmented_RR)





coefs <- tidy_reg_RR_GGS %>% 
  select (stream, term, estimate, term1, estimate1)

coefs_rr <- tidy_reg_RR_GGS %>% 
  select (stream, term, estimate)

coefs_ggs <- tidy_reg_RR_GGS %>% 
  select (stream, term1, estimate1)


# kable(gr2, format = "html") %>% 
#   kable_styling(c("striped", "bordered"), full_width = F)%>% 
#   add_header_above(c(' ', 'r.sqaured' = 2, 'adj. r.sqaured' = 2))

#change to a wider format 
coef_wider <- coefs_rr %>% 
  pivot_wider(names_from = stream, values_from = estimate) 

coef_names1 <- coef_wider %>% 
  select("term")

coefs_intcpt_slope <- coef_wider %>% 
  select(-"term") %>% 
  t() %>% 
  as_tibble(rownames = "stream") 
#rename column names
names(coefs_intcpt_slope) <-c("stream", "intcpt", "slope")

# calc the RR scale paramater for use in percentile of back transformed distributions
coefs_intcpt_slope_scale <- coefs_intcpt_slope %>% 
  mutate(scale = exp(-intcpt/slope))


#with rownames as colnames
coefs_intcpt_slope_scale1 <-coefs_intcpt_slope_scale %>% 
  #set streams column at rownames
  column_to_rownames("stream")

kable(coefs_intcpt_slope_scale1, digits = 3)



#prepare for back transformation

#Declare function for back transformation:
# back_trform_funct_RR = function(x){
#   exp(-exp(x))
# }

Perc <- c(seq(0.95, 0.05, -0.05))
size <- ??????? 
  
  
  reg_with_fittedRR <- regression %>%
  unnest(augmented_RR) %>% 
  mutate(fitted_RR = exp(-exp(.fitted))) 



s <- reg_with_fittedRR %>% 
  select(stream,RRx,RRy,.fitted,fitted_RR) %>% 
  mutate(x = exp(log(RRx)),
         y = exp(-exp(RRy)))


ss <- s %>%  
  group_by(stream) %>% 
  nest()

# join the table containing data and model transformation with coeficients.
sss <- dplyr::left_join(ss, coefs_intcpt_slope_scale, by = "stream") 

#error from here on (cannot find "unnest_sss)
# unnest_sss <- sss %>% 
#   unnest() %>% 
#   select(stream,x,y,everything()) # rearange columns
# 
# 
# #details for adding caption
# caption <- (strwrap("Modeled PSD overlaying unnoddeled Cummulative passing distribution."))
# 
# ggplot(unnest_sss, aes(x = x, y = y, shape = stream)) +
#   
#   geom_point()+ 
#   annotate( #annotate for adding the caption.
#     geom = "text", x = 1.00, y = 1.00,    #(x = xrng[1], y = yrng[2],) i mannually tiped the y=1.oo um in here to move the caption to start at 1um and not on top of the plots at 0 um as the rng(range) arguments would do.
#     label = caption, hjust = 0, vjust = 0, size = 3
#   )
# 
# 
# 
# #y vs fitted y:
# 
# caption <- (strwrap("Observed (y-axis) VS predicted (x-axis) Cummulative passing distributions."))
# 
# ggplot(unnest_sss, aes(x = fitted_RR, y = y, shape = stream)) +
#   
#   geom_point()+ #geom_smooth() +
#   annotate( #annotate for adding the caption.
#     geom = "text", x = 1.0, y = 1.00,    #(x = xrng[1], y = yrng[2],) i mannually tiped the y=1.oo um in here to move the caption to start at 1um and not on top of the plots at 0 um as the rng(range) arguments would do.
#     label = caption, hjust = 1.25, vjust = 0, size = 3
#   )
# 
# 
# #y- and fitted y vs x:
# 
# caption <- (strwrap("Observed and predicted Cummulative passing distributions."))
# 
# ggplot() +
#   geom_point ( aes(x = x, y = y), unnest_sss) +
#   geom_smooth ( aes(x = x, y = fitted_RR), unnest_sss) +
#   
#   annotate( #annotate for adding the caption.
#     geom = "text", x = 10, y = 1.00,    
#     label = caption, hjust = 0, vjust = 0, size = 3
#   )
# 
# 
# 
# 
# 



