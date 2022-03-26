## League Simulation with Team Selection
source("00 set up.R")
source("01 Data Load In.R")

# Load in Test Simulation Results as reference
load("Top 10 Probability/SimResults.RData")
SimResults %>%
  group_by(Team)%>%
  summarise(Top10 =sum(Rank<=10)/n(),
            Top1 =sum(Rank==1)/n())%>%
  arrange(desc(Top10), desc(Top1))

# Remove Test Simulation Results to save memory
rm(SimResults)

##################
# Continue Code here 
# Remove this divider upon completion

# Remember to remove detailed per match simulation results 
# to save memory. For example:
#     rm(SimTable) 
# in the League Sim.R Script
#################



