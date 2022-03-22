## Loading in EPL Data ####
source("00 set up.R")

epl_defense<-read_csv("Data/EPL data/EPL Defense.csv")
epl_goalkeeping<-read_csv("Data/EPL data/EPL Goalkeeping.csv")
epl_passing<-read_csv("Data/EPL data/EPL Passing.csv")
epl_shooting<-read_csv("Data/EPL data/EPL Shooting.csv")

save(list = ls(), file = "Data/Complete RData/EPL Data.RData")