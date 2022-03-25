# League Predictions - to be used in main only 
load("models/01 Modelling Outputs/League_Cleaned.RData")

## 01 Predicting League SPI ####
league_spi_pred<-
  model_training%>%
  filter((pos == "GK" & model == "el_net") | 
           (pos!="GK" & model=="xgboost"))%>%
  left_join(league_data_cleaned,
            by = "pos")%>%
  mutate(pred = map2(fit, data,
                     function(fit, data) 
                       predict(fit, new_data = data)))%>%
  mutate(prediction = map2(pred, data, bind_cols))%>%
  select(-c(recipe, engine, pred, data))

## 02 Predicting Confidence Interval ####
league_spi_conf_int<-
  model_training%>%
  filter(model == "linear")%>%
  left_join(league_data_cleaned,
            by = "pos")%>%
  transmute(pos,
            lm_conf_int = map2(fit, data,
                            function(fit, data) 
                              predict(fit, new_data = data,
                                      type = "conf_int")))

league_spi_pred<-league_spi_pred%>%
  left_join(league_spi_conf_int, by = "pos")

save(league_spi_pred,
     file = "spi prediction/league_spi_pred.RData")
rm(league_spi_conf_int)

## 03 Writing CSV ####
league_spi_pred%>%
  transmute(pos,
            final_data = map2(prediction, lm_conf_int, bind_cols))%>%
  mutate(final_data = 
           map(final_data,
               ~.x%>%relocate(c(.pred, .pred_lower, .pred_upper))))%>%
  mutate(
    final_data = 
      walk2(final_data, pos,
            function(df, pos){
              outdir = paste0("spi prediction/01 League SPI Prediction CSV/",
                            "league_spi_",pos,".csv")
              write_csv(df, progress=F,
                        file =outdir)}))
