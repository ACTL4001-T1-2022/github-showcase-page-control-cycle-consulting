setwd("~/Desktop/control-cycle")
source("00 set up.R")
source("01 cleanup.R")

head(league_defense)
View(league_shooting)

table11 = tournament_shooting %>%
  filter(Nation==tournament_results$country[tournament_results$tournament_rank==1 & tournament_results$year=="2020"], Year=="2020", Pos any("DF","GK")) 
View(table11)
table1a = league_shooting %>%
  filter(Nation=="Dosqaly", Year=="2020", Pos!="DF", Pos!="GK") 
View(table1a)


table2 = tournament_shooting %>%
  filter(Nation=="Dosqaly", Year=="2020") 
View(table2)
table2 = tournament_shooting %>%
  filter(Nation=="Sobianitedrucy", Year=="2021", Pos!="DF") 
View(table2)


#!str_detect(Pos, "DF")

table3 = league_shooting %>%
  count(League)
