########################################
####  Parameterization of Eve data  ####
########################################

### What this script does:

# takes data from robot_merge.py and gives yield, GT and lag using the package growthrates
# t-test ? statistics
# https://cran.r-project.org/web/packages/growthrates/vignettes/Introduction.html

#########################################################
## 0 Preparations
# empty environment and set directory
rm(list = ls())
setwd("~/Desktop/COVID/robot_data/L1021") # folder with the files - change to correct

# read packages
library(reshape)
library(data.table)
library(dplyr)

#########################################################
## 1 Read in data and transform into compatible format - all at once
library(plyr)
all_data <- ldply(list.files(pattern = ".csv"), function(fname) {
  dum = read.csv(fname, check.names = F) # without check.names = F function adds 'X.' to headers
  dum$Rack.Number = gsub('.csv$', '', fname) # get plate ID as column = filename without .csv as column
  dum <- melt(setDT(dum), id.vars = c("well", "Rack.Number"), variable.factor = F) # make long format, variable as factor F, otherwise time unit is categorical
  return(dum)
})

# change colnames
names(all_data)[3] <- "time"
names(all_data)[4] <- "fluo"
all_data$time <- as.numeric(all_data$time) # change time variable to numeric (from character)


#########################################################
## 2 Growth model
# using package growthrates
library(growthrates)

## initial parameters set by smooth spline of entire dataset
fit1 <- fit_spline(y = all_data$fluo[all_data$Rack.Number == "L1021-01"], time = all_data$time[all_data$Rack.Number == "L1021-01"],
                    spar = 0.5)

p <- c(coef(fit1), K = max(all_data$fluo)) # create vector using fitted model
#p <- c(y0 = 0.1, mumax = 1, K = 5000) # or with fixed values

# avoid negative parameters
lower = c(y0 = 0, mumax = 0, K = 0)

# some appropriate upper limits
upper = c(y0 = 2500, mumax = 100, K = max(all_data$fluo)*1.5) 

# model done using gompertz sigmoid function (gompertz2 used as suggested by help page)
# would be better to find yield peak 20-30h when difference might be bigger? shorten timeline to < 30-35h?
xsub <- subset(all_data, time <= 35)
fit2 <- all_growthmodels(fluo ~ time | well + Plate.ID, 
                        FUN = grow_gompertz2, # might not be appropriate, diverges from many curves and wrongly estimates slow growing to fast growing
                        data = xsub, 
                        p = p,
                        lower = lower)

# save parameters in table - yield (K) and mumax (max growth rate)
results2 <- results(fit2)
# check individual wells 
#plot(fit2["G20:L1035-05"])
rm(fit2) # remove model to save resources

#########################################################
## 3 save plots with raw data points and growth model
# need to subset per plate first. How to do that w S4 object? plot(fit2@Rack.Number == i) wip
#png("fluo-model_L1035-1-test.png", 
#    width = 30, height = 90, 
#    units = "cm", res = 300)
#par(mfrow = c(32,12))
#par(mar = c(1.5,1,1.5,1))
#plot(fit2)
#dev.off()

#########################################################
## 4 add metadata
# plate number - change corresponding to plate
#results2$Rack.Number <- "L1035-01" 

# get 96 to corresponding 384 well position - 1 to 4 array

array <- read.csv("../../Robot_DA/1to4_array.csv", sep = ",")
md <- read.csv("../../Robot_DA/FDA-approved-Drug-Library.csv", sep = ";", fileEncoding = "UTF-8")
names(md)[12] <- "well_96" # well column
md_array <- join(array, md, by = "well_96", type = "full")
names(md_array)[1] <- "well"

# merge data and metadata
results2 <- join(results2, md_array, by = c("well", "Rack.Number"), type = "left")

library(tidyr)

# add dmso 
results2$Item.Name <- results2$Item.Name %>% replace_na('dmso')
results2 <- results2 %>% 
  select(c(1:6,9)) %>% # useful columns
  filter(K < 80000) # remove unrealistic yield values


#########################################################
## 5 T-test

talva <- data.frame(Compound = 0, Rack.Number = 0, N = 0, yield.est = 0, yield.sd = 0, p.yield = 0, yield.log2.ratio = 0, gt.N = 0, gt.est = 0, gt.sd = 0, p.gt = 0)
talva <- slice(talva,0) # empty's table so loop starts with 0 rows

out <- data.frame(Compound = 0, Rack.Number = 0, yield.est = 0, N = 0) # Items with < 2 observations
out <- slice(out, 0)

## If making two loops, it is possible to do multiple plates at once - compare compound to internal dmso control
for(j in sort(unique(results2$Rack.Number))){
  subs <- results2[results2$Rack.Number == j,]
  for(i in sort(unique(subs$Item.Name))){
    dmso <- subs[subs$Item.Name == "dmso",]
    aa <- subs[subs$Item.Name == i,]
    if(nrow(aa) > 1){
      yield <- t.test(dmso$K, aa$K)
      mumax <- t.test(dmso$mumax, aa$mumax)
      div <- yield[["estimate"]][["mean of y"]] / mean(dmso$K) # divide compound with control
      regla <- data.frame(Compound = i, 
                          Rack.Number = j,
                          N = nrow(aa), 
                          yield.est = yield[["estimate"]][["mean of y"]], 
                          yield.sd = sd(aa$K), 
                          yield.log2.ratio = log2(div), # log2 of division (compound / control)
                          p.yield = yield[[3]], 
                          gt.est = mumax[["estimate"]][["mean of y"]], 
                          gt.sd = sd(aa$mumax), 
                          p.gt = mumax[[3]])
      talva <- rbind(talva, regla)
    } else {
      regla <- data.frame(Compound = i, Rack.Number = j, yield.est = mean(aa$K), N = nrow(aa))
      out <- rbind(out, regla) # compounds with < 2 observations, not possible to do t-test
    }
  }
}

#########################################################
## 6 p adjustment and filtering

talva$p.adj.yield <- p.adjust(talva$p.yield, method = "fdr")
talva$p.adj.gt <- p.adjust(talva$p.gt, method = "fdr")

## Yield
# Significant hits with average > dmso control and p.adj < 0.05
# should add yield ratio


Significant.hits <- subset(talva,talva$p.adj.yield <= 0.05 | NA)
Significant.hits <- subset(Significant.hits,Significant.hits$yield.log2.ratio > 0.13 | NA | NaN)
Significant.hits <- Significant.hits[order(Significant.hits$yield.est,decreasing = TRUE, na.last = FALSE ),]

## Save tables as csv
write.csv(talva, "../L1021_yield.csv", row.names = F)
write.csv(Significant.hits, "../L1021_hits.csv", row.names = F)
