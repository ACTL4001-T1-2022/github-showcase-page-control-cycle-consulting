source("00 set up.R")
source("01 Data Load In.R")

## 01 Splitting Data based on Position ####
column_selection<-readxl::read_excel("Data/Column Selection.xlsx")

position_data<-function(position){
  base_var<- c("Player", "Year","Squad", "Age")
  dynamic_vars <- column_selection%>%
    filter(Position == position)%>%
    pull(Columns)%>%
    str_trim(side = "both")
  nvars <- length(dynamic_vars) + length(base_var)
  
  if(position == "FW"){
    df1<-epl_shooting%>%
      filter(Pos == position)%>%
      select(all_of(base_var),any_of(dynamic_vars))
    
    df2<-epl_passing%>%
      filter(Pos == position)%>%
      select(all_of(base_var),any_of(dynamic_vars))
    
    df3<-epl_defense%>%
      filter(Pos == position)%>%
      select(all_of(base_var),any_of(dynamic_vars))
    
    output<-df1%>%
      inner_join(df2, 
                 by = c("Player", "Year","Squad", "Age", "90s"))%>%
      inner_join(df3, 
                 by = c("Player", "Year","Squad", "Age", "90s"))
  }
  
  if(position == "MF"){
    df1<-epl_shooting%>%
      filter(Pos == position)%>%
      select(all_of(base_var),any_of(dynamic_vars))
    
    df2<-epl_passing%>%
      filter(Pos == position)%>%
      select(all_of(base_var),any_of(dynamic_vars))
    
    df3<-epl_defense%>%
      filter(Pos == position)%>%
      select(all_of(base_var),any_of(dynamic_vars))
    
    output<-df1%>%
      inner_join(df2, 
                 by = c("Player", "Year","Squad", "Age", "90s"))%>%
      inner_join(df3, 
                 by = c("Player", "Year","Squad", "Age", "90s"))
  }
  
  if(position == "DF"){
    df1<-epl_passing%>%
      filter(Pos == position)%>%
      select(all_of(base_var),any_of(dynamic_vars))
    
    df2<-epl_defense%>%
      filter(Pos == position)%>%
      select(all_of(base_var),any_of(dynamic_vars))
    
    output<-df1%>%
      inner_join(df2, 
                 by = c("Player", "Year","Squad", "Age", "90s"))
  }
  
  if(position == "GK"){
    output<-epl_goalkeeping%>%
      filter(Pos == position)%>%
      select(all_of(base_var),any_of(dynamic_vars))
  }
  
  stopifnot(ncol(output) == nvars)
  return(output)
}

epl_data<-tibble(
  pos = c("FW", "MF", "DF", "GK"),
  data = map(pos, position_data)
)%>%
  mutate(data = map(data, 
                    function(df){
                      df%>%
                        left_join(EPL_SPI%>%
                                    filter(season>=2017)%>%
                                    select(season, team, spi),
                                  by = c("Year"= "season",
                                         "Squad"="team"))}))

## 02 Eliminating Players with less than 1.5 minutes ####
epl_data_clean1<-epl_data%>%
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

epl_data_clean1%>%
  unnest(cols = c(na_summary))%>%
  select(-data)%>%
  view()

epl_data_cleaned<-epl_data_clean1%>%
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

rm(epl_data_clean1)

save(epl_data, file = "models/01 Modelling Outputs/EPL_Positions.RData")
save(epl_data_cleaned, 
     file = "models/01 Modelling Outputs/EPL_Cleaned.RData")
