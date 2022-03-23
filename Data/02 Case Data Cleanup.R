source("Data/01 Case Data.R")

## Standardising age columns ####
calc_n_clean<-function(df){
  extract_positions<-function(db){
    if("Pos"%in% colnames(db)){
      output<-db%>%
        mutate(Pos1 = str_sub(Pos,1,2),
               Pos2 = str_sub(Pos,3,4))%>%
        pivot_longer(c(Pos1, Pos2), 
                     names_to = "Pos_num", 
                     values_to = "Pos_name")%>%
        filter(Pos_name != "")%>%
        mutate(Pos = Pos_name)%>%
        select(-c("Pos_num", "Pos_name"))
      return(output) 
    }
  }
  df%>%
    extract_positions()%>%
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