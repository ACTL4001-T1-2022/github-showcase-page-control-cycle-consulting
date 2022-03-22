source("Data/01 Case Data.R")

## Standardising age columns ####
age_calc<-function(df){
    df%>%
        mutate(Age = Year - Born)
}

league_shooting<-age_calc(league_shooting)
league_passing<-age_calc(league_passing)
league_defense <-age_calc(league_defense)
league_goalkeeping<-age_calc(league_goalkeeping)

tournament_shooting<-age_calc(tournament_shooting)
tournament_passing<-age_calc(tournament_passing)
tournament_defense <-age_calc(tournament_defense)
tournament_goalkeeping<-age_calc(tournament_goalkeeping)

rm(age_calc)
save(list = ls(), file = "Data/Complete RData/SOA Data.RData")
