
### Load libraries for regression models and functions.  ###

library(data.table)
library(zoo)
library(digest)
library(Rcpp)
library(caret)
library(doSNOW)
library(e1071)
library(caretEnsemble)
library(ipred)
library(xgboost)
library(kernlab)
library(elasticnet)
library(lars)
library(MASS)
library(pls)
library(AppliedPredictiveModeling)
library(gtools)
library(stats)
library(dplyr)
library(ggplot2)
library(tidyverse)
library(plyr)
library(devtools)
library(gbm)
library(Cubist)
library(party)
library(partykit)
library(randomForest)
library(rpart)
library(RWeka)
library(earth)
library(PerformanceAnalytics)


### Set Working Directory ###
setwd("C:/Users/Your/Desktop")

### Read in prepped data for Regression Models. ###
train <- read.csv("Dover2Train.csv", stringsAsFactors = FALSE)
points <- read.csv("Dover2Test.csv", stringsAsFactors = FALSE)


### Ensure features are encoded correctly as numeric, factor, or integer. ###
train$Length <- as.numeric(train$Length)
train$Ref... <- as.factor(train$Ref...)
train$Stat.Fact <- as.factor(train$Stat.Fact)
train$ShapeF <- as.factor(train$ShapeF)
train$TrackF <- as.factor(train$TrackF)
train$MakeF <- as.factor(train$MakeF)

points$Length <- as.numeric(points$Length)
points$Ref... <- as.factor(points$Ref...)
points$Stat.Fact <- as.factor(points$Stat.Fact)
points$ShapeF <- as.factor(points$ShapeF)
points$TrackF <- as.factor(points$TrackF)
points$MakeF <- as.factor(points$MakeF)

### View the structure of the data frames and encoding. ###
str(train)
str(points)


### Tuning parameters are set for 10-fold cross validation repeated 5 times. ###
train.control <- trainControl(method = "repeatedcv", number = 10, repeats = 5, search = "grid")


### All models will run 6 clusters of the reapeated cross validation (Caution - CPU intensive, reduce clusters if necessary). ###
### Set all seeds to same number so that resamples of hold out sets can be tested against each other. ###

### Linear Regression Model ###
cl <- makeCluster(6, type = "SOCK")
registerDoSNOW(cl)

set.seed(100)
linRegModel <- train(Points ~ ., 
                data = train, 
                method = "lm",
                trControl = train.control)
stopCluster(cl)


### Partial Least Squares Model ###
cl <- makeCluster(6, type = "SOCK")
registerDoSNOW(cl)

set.seed(100)
plsModel <- train(Points ~ ., 
                  data = train, 
                  method = "pls", 
                  preProcess = c("center", "scale"), 
                  tuneLength = 15, 
                  trControl = train.control)
stopCluster(cl)


### Penalized Regression Model (elasticnet lasso) ###
enetGrid <- expand.grid(.lambda = c(0, .001, 0.01, .1),
                        .fraction = seq(.05, 1, length = 15))

cl <- makeCluster(6, type = "SOCK")
registerDoSNOW(cl)

set.seed(100)
enetModel <- train(Points ~ ., data = train,
                  method = "enet",
                  tuneGrid = enetGrid,
                  trControl = train.control,
                  preProcess = c("center", "scale"))
stopCluster(cl)


### Multivariate Adaptive Regression Splines (MARS) ###
cl <- makeCluster(6, type = "SOCK")
registerDoSNOW(cl)

set.seed(100)
earthModel <- train(Points ~ ., 
                    data = train, 
                    method = "earth", 
                    tuneGrid = expand.grid(.degree = 1, 
                                           .nprune = 2:25), 
                    trControl = train.control)
stopCluster(cl)


### Support Vector Machine ###
cl <- makeCluster(6, type = "SOCK")
registerDoSNOW(cl)

set.seed(100)
svmModel <- train(Points ~ ., 
                 data = train, 
                 method = "svmRadial", 
                 preProcess = c("center", "scale"), 
                 tuneLength = 15, trControl = train.control)               
stopCluster(cl)


### Boosted Tree ###
gbm.grid <- expand.grid(.interaction.depth = seq(1, 7, by = 2), 
                        .n.trees = seq(100, 1000, by = 50), 
                        .n.minobsinnode = 10, 
                        .shrinkage = c(0.01, 0.1))

cl <- makeCluster(6, type = "SOCK")
registerDoSNOW(cl)

set.seed(100)
gbmModel <- train(Points ~ ., 
                 data = train, 
                 method = "gbm", 
                 tuneGrid = gbm.grid, 
                 verbose = FALSE, 
                 trControl = train.control)
stopCluster(cl)


### Cubist ###
cubistGrid <- expand.grid(.committees = c(1, 5, 10, 50, 75, 100), 
                          .neighbors = c(0, 1, 3, 5, 7, 9))

cl <- makeCluster(6, type = "SOCK")
registerDoSNOW(cl)

set.seed(100)
cbModel <- train(Points ~ ., 
                 data = train, 
                 method = "cubist", 
                 tuneGrid = cubistGrid, 
                 trControl = train.control)
stopCluster(cl)


### Display tunning results and final model summaries. ###
linRegModel
earthModel
enetModel
plsModel
svmModel
gbmModel
cbModel

linRegModel$finalModel
earthModel$finalModel
enetModel$finalModel
plsModel$finalModel
svmModel$finalModel
gbmModel$finalModel
cbModel$finalModel


### RMSE & R2 plots of resampled hold out sets. ###
resamples2 <- resamples(list("Linear Reg" = linRegModel,
                             "MARS" = earthModel,
                             "Elastic  Net" = enetModel,
                             "PLS" = plsModel,
                             "SVM" = svmModel, 
                             "Boosted Tree" = gbmModel, 
                             "Cubist" = cbModel))

parallelplot(resamples2, metric = "RMSE")
parallelplot(resamples2, metric = "Rsquared")


### Predictions against New Data ###
pred.linReg <- predict(linRegModel, points)
pred.plsModel <- predict(plsModel, points)
pred.enet <- predict(enetModel, points)
pred.MARS <- predict(earthModel, points)
pred.svm <- predict(svmModel, points)
pred.gbm <- predict(gbmModel, points)
pred.cubist <- predict(cbModel, points)


### Load libraries for Keras regression. ###
library(reticulate)
library(keras)
library(tensorflow)

### Read in Keras prepped data. ###
train_data_df <- read.csv("Dover2_Train_Data.csv", stringsAsFactors = FALSE)
train_targets_df <- read.csv("Dover2_Train_Targets.csv", stringsAsFactors = FALSE)
test_data_df <- read.csv("Dover2_Test_Data.csv", stringsAsFactors = FALSE)


### Encode all data as numeric so both data frames can be converted to matrices. ###
train_data_df$Start <- as.numeric(train_data_df$Start)
train_data_df$Ref... <- as.numeric(train_data_df$Ref...)
train_data_df$Stat.Fact <- as.numeric(train_data_df$Stat.Fact)
train_data_df$ShapeF <- as.numeric(train_data_df$ShapeF)
train_data_df$TrackF <- as.numeric(train_data_df$TrackF)
train_data_df$MakeF <- as.numeric(train_data_df$MakeF)

test_data_df$Start <- as.numeric(test_data_df$Start)
test_data_df$Ref... <- as.numeric(test_data_df$Ref...)
test_data_df$Stat.Fact <- as.numeric(test_data_df$Stat.Fact)
test_data_df$ShapeF <- as.numeric(test_data_df$ShapeF)
test_data_df$TrackF <- as.numeric(test_data_df$TrackF)
test_data_df$MakeF <- as.numeric(test_data_df$MakeF)


### View the structure of the data frames and encoding. ###
str(train_data_df)
str(train_targets_df)
str(test_data_df)


### Convert data frames to matrices. ###
train_data <- as.matrix(train_data_df)
train_targets <- as.matrix(train_targets_df)
test_data <- as.matrix(test_data_df)


### Set data `dimnames` to `NULL` ###
dimnames(train_data) <- NULL
dimnames(train_targets) <- NULL
dimnames(test_data) <- NULL


### Normalize the data using the normalize() function in Keras. ###
train_data <- normalize(train_data)
train_test <- normalize(train_data)
test_data <- normalize(test_data)


### Model Definition ###
build_model <- function() {
  model <- keras_model_sequential() %>%
    layer_dense(units = 64, activation = "relu", 
                input_shape = dim(train_data) [[2]]) %>%
    layer_dense(units = 32, activation = "relu") %>%
    layer_dense(units = 1, activation = "linear")
  model %>% compile(
    optimizer = "adadelta", 
    loss = "mse", 
    metrics = c("mae")
  )
}


### K-fold Validation ###
k <- 5
indices <- sample(1:nrow(train_data))
folds <- cut(indices, breaks = k, labels = FALSE)


### Saving the Validation Logs at each Fold ###
num_epochs <- 500
all_mae_histories <- NULL
for (i in 1:k) {
  cat("processing fold #", i, "\n")
  
  val_indices <- which(folds == i, arr.ind = TRUE)
  val_data <- train_data[val_indices,]
  val_targets <- train_targets[val_indices]
  
  partial_train_data <- train_data[-val_indices,]
  partial_train_targets <- train_targets[-val_indices]
  
  model <- build_model()
  
  history <- model %>% fit(
    partial_train_data, partial_train_targets, 
    validation_data = list(val_data, val_targets), 
    epochs = num_epochs, batch_size = 1, verbose = 0
  )
  mae_history <- history$metrics$val_mean_absolute_error
  all_mae_histories <- rbind(all_mae_histories, mae_history)
}


### Building the History of Successive mean K-fold Validation Scores ###
average_mae_history <- data.frame(
  epoch = seq(1:ncol(all_mae_histories)), 
  validation_mae = apply(all_mae_histories, 2, mean)
)


### Plotting Validation Scores ###
ggplot(average_mae_history, aes(x = epoch, y = validation_mae)) + geom_line()

ggplot(average_mae_history, aes(x = epoch, y = validation_mae)) + geom_smooth()


### Training the Final Model ###
model <- build_model()
model %>% fit(train_data, train_targets,
              epochs = 150, batch_size = 16, verbose = 0)

### View Final Results ###
results <- model %>% evaluate(train_data, train_targets)

results


### Make predictions against new test data. ###
preds <- model %>% Predict(test_data)
pred.keras <- as.data.frame(preds)


### combine all Predictions into one Data Frame and export to an Excel.csv ###
Predictions <- data.frame(pred.linReg, pred.plsModel, pred.enet, pred.MARS, pred.svm, pred.gbm, pred.cubist, pred.keras)

col_headings <- c('linReg', 'pls', 'enet', 'MARS', 'svm', 'gbm', 'cubist', 'keras')
colnames(Predictions) <- col_headings

write.csv(Predictions, file = "Dover2Predictions.csv")








