source("00 set up.R")
source("01 Data Load In.R")

test_set <- tournament_shooting %>%
  filter(Year==2021) %>%
  group_by(Nation) %>%
  summarise(xG_team = sum(`Expected xG`)/n()*11)

xG_tournament <- bind_cols(
  test_set %>%
    slice(rep(1:n(),each=nrow(test_set))) %>%
    rename(Home=Nation,
           xG_Home=xG_team),
  test_set %>%
    slice(rep(1:n(),times=nrow(test_set))) %>%
    rename(Away=Nation,
           xG_Away=xG_team)) %>%
  filter(Home!=Away)

## Simulation ##
nSim <- 10000
set.seed(555)
SimTable <- xG_tournament %>% 
  slice(rep(row_number(), each = nSim))%>%
  mutate(
    Home_G=rpois(n(),xG_Home),
    Away_G=rpois(n(),xG_Away),
    Home_P=ifelse(Home_G > Away_G, 3, 
                  ifelse(Home_G == Away_G, 1, 0)), 
    Away_P=ifelse(Home_G > Away_G, 0,
                  ifelse(Home_G == Away_G, 1, 3)),
    SimNum=rep(1:nSim,times=nrow(xG_tournament))
  )%>%
  select(c(Home:xG_Away, Home_P, Away_P, SimNum))%>%
  pivot_longer(ends_with("P"),
               names_to = "Field",
               names_pattern = "(.{4})_P",
               values_to = "Points")%>%
  transmute(
    Team = if_else(Field == "Home",
                   Home, Away),
    xG = if_else(Field == "Home",
                 xG_Home, xG_Away),
    Field, 
    Points, 
    SimNum
  )

SimResults<-
  SimTable%>%
  group_by(SimNum, Team)%>%
  summarise(Points = sum(Points), .groups = "drop")%>%
  group_by(SimNum)%>%
  mutate(Rank = min_rank(desc(Points)))

# Remove detailed simulation restuls to save memory
rm(SimTable) 

## SimResults Analysis ####
SimResults %>%
  group_by(Team)%>%
  summarise(Top10 =sum(Rank<=10)/n(),
            Top1 =sum(Rank==1)/n())%>%
  arrange(desc(Top10), desc(Top1))

save(SimResults, file="Top 10 Probability/SimResults.RData")
