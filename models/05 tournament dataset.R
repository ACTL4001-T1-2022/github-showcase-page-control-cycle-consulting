## Tournament Data Cleaning ####
source("00 set up.R")
load("Data/Complete RData/SOA Data.RData")

## 01 Splitting Data based on Position ####
column_selection<-readxl::read_excel("Data/Column Selection.xlsx")

tournament_cleaning<-function(position){
  base_var<- c("Player", "Year","Nation", "Age")
  dynamic_vars <- column_selection%>%
    filter(Position == position)%>%
    pull(Columns)%>%
    str_trim(side = "both")
  nvars <- length(dynamic_vars) + length(base_var)
  
  tournament_shooting<-tournament_shooting%>%
    filter(Year == 2021)
  
  tournament_goalkeeping<-tournament_goalkeeping%>%
    filter(Year == 2021)
  
  if(position == "FW"){
    df1<-tournament_shooting%>%
      filter(Pos == position)%>%
      select(all_of(base_var),any_of(dynamic_vars))
    
    df2<-tournament_passing%>%
      filter(Pos == position)%>%
      select(all_of(base_var),any_of(dynamic_vars))
    
    df3<-tournament_defense%>%
      filter(Pos == position)%>%
      select(all_of(base_var),any_of(dynamic_vars))
    
    tmp<-df1%>%
      inner_join(df2, 
                 by = c("Player", "Year","Nation", "Age"))%>%
      inner_join(df3, 
                 by = c("Player", "Year","Nation", "Age"))
    
    mean_vec<-tmp%>%
      select(starts_with("90s"))%>%
      rowMeans
    
    output<-tmp%>%
      select(-starts_with("90s"))%>%
      mutate(`90s` = mean_vec)
  }
  
  if(position == "MF"){
    df1<-tournament_shooting%>%
      filter(Pos == position)%>%
      select(all_of(base_var),any_of(dynamic_vars))
    
    df2<-tournament_passing%>%
      filter(Pos == position)%>%
      select(all_of(base_var),any_of(dynamic_vars))
    
    df3<-tournament_defense%>%
      filter(Pos == position)%>%
      select(all_of(base_var),any_of(dynamic_vars))
    
    tmp<-df1%>%
      inner_join(df2, 
                 by = c("Player", "Year","Nation", "Age"))%>%
      inner_join(df3, 
                 by = c("Player", "Year","Nation", "Age"))
    
    mean_vec<-tmp%>%
      select(starts_with("90s"))%>%
      rowMeans
    
    output<-tmp%>%
      select(-starts_with("90s"))%>%
      mutate(`90s` = mean_vec)
  }
  
  if(position == "DF"){
    df1<-tournament_passing%>%
      filter(Pos == position)%>%
      select(all_of(base_var),any_of(dynamic_vars))
    
    df2<-tournament_defense%>%
      filter(Pos == position)%>%
      select(all_of(base_var),any_of(dynamic_vars))
    
    tmp<-df1%>%
      inner_join(df2, 
                 by = c("Player", "Year","Nation", "Age"))
    
    mean_vec<-tmp%>%
      select(starts_with("90s"))%>%
      rowMeans
    
    output<-tmp%>%
      select(-starts_with("90s"))%>%
      mutate(`90s` = mean_vec)
  }
  
  if(position == "GK"){
    output<-tournament_goalkeeping%>%
      filter(Pos == position)%>%
      select(all_of(base_var),any_of(dynamic_vars))
  }
  
  stopifnot(ncol(output) == nvars)
  return(output)
}

tournament_data<-tibble(
  pos = c("FW", "MF", "DF", "GK"),
  data = map(pos, tournament_cleaning)
)

## 02 Eliminating Players with less than 1.5 minutes ####
tournament_data_cleaned<-tournament_data%>%
  mutate(
    data = map(
      data,
      function(df){
        if(anyNA(df)){
          df%>%
            mutate(across(where(~anyNA(.)),
                          replace_na, replace = 0))
        }
        else{df}
      }))

save(tournament_data_cleaned, 
     file = "models/01 Modelling Outputs/Tournament_Cleaned.RData")
