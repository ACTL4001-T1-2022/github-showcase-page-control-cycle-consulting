source("00 set up.R")
source("01 Data Load In.R")

## 01 Model Selection Outcome ####
load("models/02 Model Selection/final_fit.RData")
load("models/02 Model Selection/tournament_result_pred.RData")
load("models/02 Model Selection/tournament_player_pred.RData")

## 02 League SPI Prediction ####
load("spi prediction/league_spi_pred.RData")