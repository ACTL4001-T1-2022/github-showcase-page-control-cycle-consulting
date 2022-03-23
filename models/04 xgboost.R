## Loading Packages & Environment #### 
rm(list = ls())
source("00 set up.R")
source("01 Data Load In.R")

## 00 Setting up Modelling Environment ####
# Initialise parallel Processing 
cores <- parallel::detectCores()
cluster <- makePSOCKcluster(cores)

# Run parallel Processing
registerDoParallel(cluster)
cat("Parallel Processing using:", cores, "cores. \n")

# Define metrics
reg_metrics<-metric_set(rmse, mae,rsq,mase, huber_loss_pseudo)

## 01 Data Split ####
set.seed(555)
epl_split<-epl_data_cleaned%>%
  mutate(recipe = map(data, 
                    function(data){
                      recipe(spi ~., data = data)%>%
                        update_role(Player, Year, Squad, new_role = "ID")
                    }))%>%
  mutate(cvfold = map(data,
                      vfold_cv, v=4, repeats =2))

## 02 Default XGBoost Model ####
xgb_default_wflw<-epl_split%>%
  mutate(model = map(pos,
                     function(pos){
                       if(pos=="GK"){
                         boost_tree(trees=20)%>%
                           set_engine("xgboost")%>%
                           set_mode("regression")
                       }
                       else{
                         boost_tree(trees=50)%>%
                           set_engine("xgboost")%>%
                           set_mode("regression") 
                       }
                     }))%>%
  mutate(workflow = map2(model, recipe,
                        function(model,recipe){
                          workflow()%>%
                            add_model(model)%>%
                            add_recipe(recipe)
                        }))

# Investigating time for each tree
xgb_default_time<-system.time(
  xgb_default_resampled<-
    xgb_default_wflw%>%
    mutate(
      resampled = 
        map2(cvfold, workflow, 
             function(cvfold, workflow){
               workflow%>%
               fit_resamples(
                 resamples=cvfold,
                 metrics=reg_metrics,
                 control=control_resamples(
                   extract = function (x) extract_fit_parsnip(x),
                   save_pred = T, verbose=T, allow_par = T))
        }))
)


# Evaluating Default Model ####
xgb_default_results<-xgb_default_resampled%>%
  mutate(metrics = map(resampled, collect_metrics))

save(xgb_default_results, reg_metrics,
     file = "models/01 Modelling Outputs/xgboost_model.RData")
