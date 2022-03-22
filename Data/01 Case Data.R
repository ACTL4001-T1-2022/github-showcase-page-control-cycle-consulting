## Loading datasets ####

## 00 Installing the pacman package ####
list.of.packages <- c("pacman")
new.packages <- list.of.packages[
  !(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
rm(list.of.packages, new.packages)

## Loading Required Packages
pacman::p_load(
  tidyverse,
  readxl
)

## 01 Cleaning the environment and loading in data ####
rm(list = ls())
csv.dir<-list.files(path = "Data/case data/", recursive = T,
                    full.names = T)
csv.names<-basename(csv.dir)%>%
  str_remove(".csv")

csv.names<-if_else(str_detect(csv.names, "\\s"),
                   str_to_lower(
                     str_replace(csv.names, "\\s","_")),
                   csv.names)

walk2(csv.dir, csv.names,
      function(dir,name) 
        assign(name,  read_csv(dir, show_col_types = F),
               envir = .GlobalEnv))

rf_yield<-rf_yield%>%
  pivot_longer(cols = -Maturity,
               names_to = "Year", 
               values_to = "yield")%>%
  mutate(Year = lubridate::dmy(Year))

rm(csv.dir, csv.names)