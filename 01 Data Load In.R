## Loading in Relevant RData files ####
library(tidyverse)

## 01 Raw Datasets ####
load("Data/Complete RData/SOA Data.RData")

## 02 Cleaned Datasets ####
# EPL Data
load("models/01 Modelling Outputs/EPL_Cleaned.RData")

# Tournament Data 
load("models/01 Modelling Outputs/Tournament_Cleaned.RData")

# League Data
load("models/01 Modelling Outputs/League_Cleaned.RData")
