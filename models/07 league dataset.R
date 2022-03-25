## League Data Cleaning ####
source("00 set up.R")
load("Data/Complete RData/SOA Data.RData")

## 01 Splitting Data based on Position ####
column_selection<-readxl::read_excel("Data/Column Selection.xlsx")

league_cleaning<-function(position){
  base_var<- c("Player","Nation", "Year", "League","Squad", "Age")
  dynamic_vars <- column_selection%>%
    filter(Position == position)%>%
    pull(Columns)%>%
    str_trim(side = "both")
  nvars <- length(dynamic_vars) + length(base_var)
  
  if(position == "FW"){
    df1<-league_shooting%>%
      filter(Pos == position)%>%
      select(all_of(base_var),any_of(dynamic_vars))
    
    df2<-league_passing%>%
      filter(Pos == position)%>%
      select(all_of(base_var),any_of(dynamic_vars))
    
    df3<-league_defense%>%
      filter(Pos == position)%>%
      select(all_of(base_var),any_of(dynamic_vars))
    
    tmp<-df1%>%
      inner_join(df2, 
                 by = base_var)%>%
      inner_join(df3, 
                 by = base_var)
    
    stopifnot(nrow(tmp)<= max(map_dbl(list(df1, df2, df3),nrow)))
    
    mean_vec<-tmp%>%
      select(starts_with("90s"))%>%
      rowMeans
    
    output<-tmp%>%
      select(-starts_with("90s"))%>%
      mutate(`90s` = mean_vec)
  }
  
  if(position == "MF"){
    df1<-league_shooting%>%
      filter(Pos == position)%>%
      select(all_of(base_var),any_of(dynamic_vars))
    
    df2<-league_passing%>%
      filter(Pos == position)%>%
      select(all_of(base_var),any_of(dynamic_vars))
    
    df3<-league_defense%>%
      filter(Pos == position)%>%
      select(all_of(base_var),any_of(dynamic_vars))
    
    tmp<-df1%>%
      inner_join(df2, 
                 by = base_var)%>%
      inner_join(df3, 
                 by = base_var)
    
    stopifnot(nrow(tmp)<= max(map_dbl(list(df1, df2, df3),nrow)))
    
    mean_vec<-tmp%>%
      select(starts_with("90s"))%>%
      rowMeans
    
    output<-tmp%>%
      select(-starts_with("90s"))%>%
      mutate(`90s` = mean_vec)
  }
  
  if(position == "DF"){
    df1<-league_passing%>%
      filter(Pos == position)%>%
      select(all_of(base_var),any_of(dynamic_vars))
    
    df2<-league_defense%>%
      filter(Pos == position)%>%
      select(all_of(base_var),any_of(dynamic_vars))
    
    tmp<-df1%>%
      inner_join(df2, 
                 by = base_var)
    
    stopifnot(nrow(tmp)<= max(map_dbl(list(df1, df2),nrow)))
    
    mean_vec<-tmp%>%
      select(starts_with("90s"))%>%
      rowMeans
    
    output<-tmp%>%
      select(-starts_with("90s"))%>%
      mutate(`90s` = mean_vec)
  }
  
  if(position == "GK"){
    output<-league_goalkeeping%>%
      filter(Pos == position)%>%
      select(all_of(base_var),any_of(dynamic_vars))
  }
  
  stopifnot(ncol(output) == nvars)
  return(output)
}

player_salary<-player_2020_salary%>%
  bind_rows(player_2021_salary)%>%
  rename(Player = `Player Name`)

league_data<-tibble(
  pos = c("FW", "MF", "DF", "GK"),
  data = map(pos, league_cleaning)
)%>%
  mutate(
    data = 
      map2(data, pos,
           function(df, pos){
             base_var<- c("Player","Nation", "Year", "League","Squad", "Age")
             df%>%
               left_join(player_salary%>%
                           filter(Pos == pos)%>%
                           select(-Pos),
                         by = c("Player","League", 
                                "Squad", "Nation", "Year"))%>%
               filter(!is.na(salary))%>%
               distinct(across(all_of(base_var)), .keep_all=T)
           }))

## 02 Eliminating Players with less than 1.5 minutes ####
league_data_clean1<-league_data%>%
  mutate(data = map(data,
                    function(df){
                      if("90s" %in% colnames(df)){
                        df%>%
                          filter(`90s`>1.5)}
                      else{
                        df%>%
                          filter(`Playing Time 90s`>0.5)
                      }}))%>%
  mutate(na_summary = 
           map(data,
               function(df){
                 if(anyNA(df)){
                   df%>%
                     select(where(~anyNA(.)))%>%
                     summarise(across(everything(),~sum(is.na(.))))%>%
                     pivot_longer(everything())
                 }
                 else{tibble()}
               }))

league_data_clean1%>%
  unnest(cols = c(na_summary))%>%
  select(-data)%>%
  view()

league_data_cleaned<-league_data_clean1%>%
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
      }))%>%
  select(-na_summary)

save(league_data_cleaned, 
     file = "models/01 Modelling Outputs/League_Cleaned.RData")
