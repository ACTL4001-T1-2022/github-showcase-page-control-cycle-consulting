## Loading in EPL Data ####
source("00 set up.R")

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

epl_defense<-read_csv("Data/EPL data/EPL Defense.csv")%>%
  extract_positions()
epl_goalkeeping<-read_csv("Data/EPL data/EPL Goalkeeping.csv")
epl_passing<-read_csv("Data/EPL data/EPL Passing.csv")%>%
  rename(`1/3` = `1-Mar`)%>%
  extract_positions()
epl_shooting<-read_csv("Data/EPL data/EPL Shooting.csv")%>%
  extract_positions()

column_selection<-readxl::read_excel("Data/Column Selection.xlsx")

save(list = c("epl_shooting", "epl_passing", 
              "epl_defense","epl_goalkeeping"), 
     file = "Data/Complete RData/EPL Data.RData")
