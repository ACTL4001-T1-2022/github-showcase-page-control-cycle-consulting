## Installing the pacman package ####
list.of.packages <- c("pacman")
new.packages <- list.of.packages[
  !(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
rm(list.of.packages, new.packages)

## Loading Required Packages ####
pacman::p_load(
  tidyverse,
  lubridate,
  tidymodels,
  readxl
)

