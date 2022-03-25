## Testing ####

## 00 Setting up Model Fitting ####
source("00 set up.R")
load("models/01 Modelling Outputs/EPL_Cleaned.RData")
load("models/01 Modelling Outputs/Tournament_Cleaned.RData")

tournament_results<-read.csv(
  "Data/case data/Tournament/Tournament Results.csv")

## 01 Fitting the Model ####
engine_generator<-function(model,pos){
  if(model=="linear"){
    lm_model <- linear_reg() %>%
      set_engine('lm') %>%
      set_mode('regression')
    output<-lm_model
  }
  if(model=="el_net"){
    penalty<-if_else(pos == "DF",
                     0.0562, 1)
    mixture<-case_when(
      pos=="FW" ~0.375,
      pos =="MF" ~ 0.125,
      TRUE ~1
    )
    output<-
      linear_reg(mode = "regression",
                 penalty = !!penalty,
                 mixture = !!mixture)%>%
      set_engine("glmnet")
  }
  if(model=="xgboost"){
    if(pos=="GK"){
      output<-boost_tree(trees=20)%>%
        set_engine("xgboost")%>%
        set_mode("regression")
    }
    else{
      output<-boost_tree(trees=50)%>%
        set_engine("xgboost")%>%
        set_mode("regression") 
    }
  }
  return(output)
}

model_training<-epl_data_cleaned%>%
  rename(epl_data = data)%>%
  slice(rep(row_number(), each= 3))%>%
  mutate(model = rep(c("linear","el_net","xgboost"),4))%>%
  mutate(
    recipe = 
      map(epl_data, 
          function(epl_data){
            recipe(spi ~., data = epl_data)%>%
              update_role(Player, Year, Squad, new_role = "ID")}))%>%
  mutate(engine = map2(model, pos, engine_generator))%>%
  mutate(
    workflow = map2(engine, recipe,
                    function(engine,recipe){
                      workflow()%>%
                        add_model(engine)%>%
                        add_recipe(recipe)
                    }))%>%
  mutate(fit = map2(workflow, epl_data, 
                    function(workflow, epl_data) 
                      workflow %>% fit(epl_data)))

model_fit<-
  model_training%>%
  select(pos, model,fit)%>%
  mutate(fit_analysis = map(fit, 
                            function(x){
                              x%>% extract_fit_parsnip()
                            }))

model_test<-
  model_training%>%
  left_join(tournament_data_cleaned,
            by = "pos")%>%
  mutate(data= map(data, 
                   ~.x%>%
                     mutate(across(contains("90s"),~.*38/8))%>%
                     rename(Squad = Nation)))%>%
  mutate(pred = map2(fit, data,
                     function(fit, data) 
                       predict(fit, new_data = data)))%>%
  mutate(conf_int = 
           pmap(list(fit, data, model),
                function(fit, data, model){
                  if(model == "linear"){
                    predict(fit, new_data = data,
                            type = "conf_int")
                  }}))%>%
  mutate(prediction = pmap(list(data, pred, conf_int), bind_cols))%>%
  select(-c(recipe, engine,data, pred, conf_int))

save(model_training, model_fit, model_test,
     file = "models/02 Model Selection/final_fit.RData")
rm(model_training, model_fit)

## 02 Predict Tournament Results ####
inverse_sigmoid<-function(x){
  input = c(0.99, 0.001)
  range = log(input/(1-input))
  uniform_seq = seq(range[1], range[2], length.out = 24)
  set_names(uniform_seq,1:24)
  output<-1/(1+exp(-uniform_seq[x]))-0.5
  return(output)
}
ggplot(tibble(x= 1:24, y = inverse_sigmoid(1:24)), 
       aes(x,y))+
  geom_line()

tournament_overall_prediction<-
  model_test%>%
  select(pos, model, prediction)%>%
  unnest(cols = prediction)%>%
  group_by(model, Squad)%>%
  summarise(spi = mean(.pred),.groups = "drop_last")%>%
  arrange(model, desc(spi))%>%
  mutate(pred_rank = row_number())%>%
  left_join(tournament_results%>%
              filter(year == 2021)%>%
              select(-year)%>%
              rename(actual_rank = tournament_rank),
            by = c("Squad" = "country"))

anyNA(tournament_overall_prediction%>%
        select(contains("rank")))

tournament_overall_scoring<-tournament_overall_prediction%>%
  mutate(diff = actual_rank - pred_rank)%>%
  mutate(penalized_diff =if_else(actual_rank<pred_rank,
                       as.integer(diff*2),diff))%>%
  mutate(across(contains("rank"), inverse_sigmoid, 
                .names = "{.col}_score"))%>%
  mutate(score_diff = actual_rank_score - pred_rank_score)%>%
  group_by(model)%>%
  summarise(mse = mean(diff^2),
            mse_penalized = mean(penalized_diff^2),
            mse_score = mean(score_diff^2))

save(inverse_sigmoid, tournament_overall_prediction,
     tournament_overall_scoring, 
     file = "models/02 Model Selection/tournament_result_pred.RData")
rm(tournament_overall_prediction,
   tournament_overall_scoring)

## 03 Predict Position Results ####
tournament_player_prediction<-
  model_test%>%
  select(pos, model, prediction)%>%
  mutate(
    comparison = 
    map(prediction,
        function(x){
          x%>%
            group_by(Squad)%>%
            summarise(spi = mean(.pred),.groups = "drop")%>%
            arrange(desc(spi))%>%
            mutate(pred_rank = row_number())%>%
            left_join(tournament_results%>%
                        filter(year == 2021)%>%
                        select(-year)%>%
                        rename(actual_rank = tournament_rank),
                      by = c("Squad" = "country"))
        }))

tournament_player_scoring<-tournament_player_prediction%>%
  mutate(
    scoring = 
      map(comparison,
          function(x){
            x%>%
              mutate(diff = actual_rank - pred_rank)%>%
              mutate(penalized_diff =if_else(actual_rank<pred_rank,
                                             as.integer(diff*2),diff))%>%
              mutate(across(contains("rank"), inverse_sigmoid, 
                            .names = "{.col}_score"))%>%
              mutate(score_diff = actual_rank_score - pred_rank_score)%>%
              ungroup()%>%
              summarise(mse = mean(diff^2),
                        mse_penalized = mean(penalized_diff^2),
                        mse_score = mean(score_diff^2))
          }))

# Analyse by position
tournament_player_scoring%>%
  filter(pos == "GK")%>%
  pull(scoring)

save(tournament_player_prediction, tournament_player_scoring,
     file = "models/02 Model Selection/tournament_player_pred.RData")
rm(tournament_player_prediction, tournament_player_scoring)
## 04 Final Deliberation #### 
# Regularised Linear Regression for GK
# XGBoost for all other