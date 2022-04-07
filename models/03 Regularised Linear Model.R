## Loading Packages in Environment ##
rm(list=ls())
source("00 set up.R")
source("01 Data Load In.R")

### Regularised Linear Regression ###
linear_function <- function(df){
  epl_split<-initial_split(df)
  epl_train<-training(epl_split)
  epl_test<-testing(epl_split)
  
  training_folds=vfold_cv(epl_train,v=4, repeats = 2)
  
  epl_recipe <- recipe(spi~.,data=epl_train) %>%
    update_role(c(Year,Squad,Player),new_role="ID")
  
  # Model Fitting #
  epl_ridge <- linear_reg(mode="regression",
                          penalty=tune(),
                          mixture=tune()) %>%
    set_engine("glmnet")
  
  # Workflow #
  epl_ridge_workflow <- workflow() %>%
    add_model(epl_ridge) %>%
    add_recipe(epl_recipe)
  
  ridge_grid <- grid_regular(penalty(),
                             mixture(),
                             levels = 9)
  
  ridge_res <- epl_ridge_workflow %>%
    tune_grid(
      resamples = training_folds,
      grid = ridge_grid,
      control = control_grid(save_pred = T,
                             verbose = T)
    )
  
  output <- list(
    rmse=(ridge_res %>%
            show_best("rmse",n=1)),
    rsq=(ridge_res %>%
           show_best("rsq",n=1)))
  return(output)
}

model_results_new <- epl_data_cleaned %>%
  mutate(model=map(data,linear_function))

rmse=sapply(model_results_new$model,"[[",1)
rsq=sapply(model_results_new$model,"[[",2)


save(model_results_new,linear_function,
     file="models/01 Modelling Outputs/Regularised Linear Model.RData")

#####
ridge_res %>%
  autoplot(metric="rsq")

ridge_res %>%
  autoplot(metric="rmse")

best_ridge <- ridge_res %>% 
  select_best("rsq")

ridge_final <- epl_ridge_workflow %>%
  finalize_workflow(best_ridge)

final_fit <-
  ridge_final %>%
  fit()