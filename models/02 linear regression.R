### Loading Packages & Environment ###
rm(list = ls())
source("00 set up.R")
source("01 Data Load In.R")

# Define metrics
reg_metrics<-metric_set(rmse, mae,rsq,mase, huber_loss_pseudo)

# Linear Regression Model
lr_model <- linear_reg() %>%
  set_engine('lm') %>%
  set_mode('regression')

# Cross-fold
set.seed(555)
epl_model_cv<-epl_data_cleaned%>%
  mutate(recipe = map(data, 
                      function(data){
                        recipe(spi ~., data = data)%>%
                          update_role(Player, Year, Squad, 
                                      new_role = "ID")
                      }))%>%
  mutate(cvfold = map(data,
                      vfold_cv, v=4, repeats =2))

epl_model_lr_wkflw<-epl_model_cv%>%
  mutate(model = rep(list(lr_model),4))%>%
  mutate(workflow = map2(model, recipe,
                         function(model, recipe){
                           workflow()%>%
                             add_model(model)%>%
                             add_recipe(recipe)
                         }))

epl_model_lr_resampled<-epl_model_lr_wkflw%>%
  mutate(resampled = map2(workflow, cvfold,
                          function(workflow, cvfold){
                            workflow%>%
                              fit_resamples(
                                resamples = cvfold,
                                metrics = reg_metrics,
                                control = control_resamples(verbose = T, 
                                                            save_pred = T)
                              )
                          }))

epl_model_lr_resampled%>%
  mutate(results = map(resampled, collect_metrics))%>%
  pull(results)
