## Loading in SPI Data ####
source("00 set up.R")

EPL_SPI<-read_csv("Data/SPI data/spi_matches.csv")
EPL_SPI<-EPL_SPI%>%
  filter(league_id =="2411")%>%
  mutate(date = dmy(date))%>%
  arrange(desc(season),desc(date),desc(spi1))%>%
  group_by(season)%>%
  slice_max(date)%>%
  select(season:spi2)%>%
  pivot_longer(cols = starts_with("team"),
               names_to = c("temp"),
               values_to = c("team"))%>%
  mutate(spi = if_else(temp == "team1",
                       spi1, spi2))%>%
  select( -c("spi1", "spi2","temp"))

save(EPL_SPI,file = "Data/Complete RData/EPL_SPI.RData")
