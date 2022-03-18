###################
#### Robot run ####
###################


## 1: Plot all compounds


library(reshape)
library(data.table)
rm(list = ls())
setwd("~/Desktop/COVID/")

x <- read.csv("robot_data/L1021/L1021-18.csv", check.names = F)
x$Rack.Number <- "L1021-18"
x <- melt(setDT(x), id.vars = c("well", "Rack.Number"), variable.factor = F)
names(x)[3] <- "time"
names(x)[4] <- "fluo"
x$time <- as.numeric(x$time)

# get 96 to corresponding 384 well position - 1 to 4 array
library(plyr)

array <- read.csv("Robot_DA/1to4_array.csv", sep = ",")
md <- read.csv("Robot_DA/FDA-approved-Drug-Library.csv", sep = ",", fileEncoding = "UTF-8")
names(md)[4] <- "well_96" # well column
md_array <- join(array, md, by = "well_96", type = "full")
names(md_array)[1] <- "well"

x <- join(x, md_array, by = c("well", "Rack.Number"), type = "left")

library(tidyr)
x$Item.Name <- x$Item.Name %>% replace_na('dmso')

library(Rmisc)
x_means <- summarySE(subset(x, Item.Name != "dmso"), "fluo", groupvars = c("Item.Name", "time"))


library(dplyr)
dmso_means <- summarySE(subset(x, Item.Name == "dmso"), "fluo", groupvars = c("time")) %>%
  select (-c(se,ci,N))

dmso_means <- rename(dmso_means, c("fluo.dmso" = "fluo", "sd.dmso" = "sd"))


x_means <- x_means %>%
  select(-c(se,ci,N)) %>%
  left_join(dmso_means, by = c("time"))

# plot growth curves
library(ggplot2)
library(lubridate)
pdf("fluo_L1021-18.pdf", width = 12, height = 60)
ggplot(x_means, aes(x = time, y = fluo)) +
  geom_line() +
  geom_line(data = dmso_means, aes(y = fluo.dmso), linetype = 2, col = "grey50") +
  #geom_point(aes(col = concentration)) +
  geom_ribbon(aes(ymin=fluo.dmso-sd.dmso,ymax=fluo.dmso+sd.dmso, linetype="DMSO"),fill = "grey70", color = "grey70",alpha=0.4, show.legend = F)+
  geom_ribbon(aes(ymin=fluo-sd,ymax=fluo+sd), fill="firebrick", color="grey70",alpha=0.4, show.legend = T)+
  facet_wrap(~Item.Name, ncol = 4) +
  ylab("fluo") +
  xlab("time (hours)")+
  labs(linetype = "") +
  theme_bw()+
  theme(strip.background = element_blank(),
        text = element_text(size=20))
dev.off()

