source("Data/01 Case Data.R")

## Standardising age columns ####
calc_n_clean<-function(df){
  df%>%
    mutate(Age = Year - Born)%>%
    mutate(across(where(is.double),
                  ~if_else(.<0,0,.)))
}

league_shooting<-calc_n_clean(league_shooting)
league_passing<-calc_n_clean(league_passing)
league_defense <-calc_n_clean(league_defense)
league_goalkeeping<-calc_n_clean(league_goalkeeping)

tournament_shooting<-calc_n_clean(tournament_shooting)
tournament_passing<-calc_n_clean(tournament_passing)
tournament_defense <-calc_n_clean(tournament_defense)
tournament_goalkeeping<-calc_n_clean(tournament_goalkeeping)

rm(calc_n_clean)
save(list = ls(), file = "Data/Complete RData/SOA Data.RData")