library(readr)
library(caret)
library(class)
library(glmnet)
library(ModelMetrics)

setwd('/Users/joshd/Library/Mobile Documents/com~apple~CloudDocs/statistics_DS/statistical_learning/assignments/individual/01/')
rm(list = ls())

data_set <- read_csv("Data4036018.csv")

# consider only Y and first 6 predictors
sub_dataset <- data_set[, 1:7]

train <- sub_dataset[1:5000, ]
test <- sub_dataset[5001:10000, ]




####### Q1 and Q2

# Select relevant predictors (X1 to X3) and irrelevant predictors (X4 to X6)
predictors <- c("X1", "X2", "X3", "X4", "X5", "X6")

# Define training and test sets with relevant predictors
x_train <- train[, predictors]
y_train <- train$Y
x_test <- test[, predictors]
y_test <- test$Y

# K-nearest neighbors (KNN) analysis
# Tune KNN model using cross-validation
knn_model <- train(x = x_train, y = y_train, method = "knn", trControl = trainControl(method = "cv"))
# Make predictions
knn_pred <- predict(knn_model, newdata = x_test)
# Calculate misclassification error
knn_error <- sum(knn_pred != y_test) / length(y_test)

# LASSO logistic regression
# Fit LASSO logistic regression model
lasso_model <- cv.glmnet(x_train, y_train, alpha = 1, family = "binomial")
# Make predictions
lasso_pred <- predict(lasso_model, newx = x_test, s = "lambda.min", type = "response")
# Convert predicted probabilities to binary predictions
lasso_pred <- ifelse(lasso_pred > 0.5, 1, 0)
# Calculate misclassification error
lasso_error <- sum(lasso_pred != y_test) / length(y_test)

# Output results
cat("K-nearest neighbors (KNN) error:", knn_error, "\n")
cat("LASSO logistic regression error:", lasso_error, "\n")




####### Q3

# convert binary reponse Y to factor
train$Y <- factor(train$Y)

# Define the training control
train_control <- trainControl(method = "cv", number = 10)


# cross-validate the knn model with candidate ks
set.seed(4036018) #set seed to make sure it is the same as for LDA
knn_model <- train(Y ~ X1 + X2 + X3 + X4 + X5 + X6,
                   data = train,
                   method = "knn",
                   tuneGrid = data.frame(k = seq(1,200, by = 1) #72.19996 Highest accuracy
                   ),
                   trControl = train_control,
                   preProcess = c("center","scale"))
# Print the optimal k and corresponding accuracy
print(knn_model$bestTune)

# model results
print(knn_model$results)


















# Step 2: Define number of folds for cross-validation
k_folds <- 10

# Step 3: Loop through different values of K
k_values <- seq(1, 20, by = 2) # Example: try odd values of K from 1 to 20
accuracy <- numeric(length(k_values))

for (i in seq_along(k_values)) {
  set.seed(4036018) # for reproducibility
  knn_model <- train(
    Y ~ ., 
    data = train, 
    method = "knn", 
    trControl = trainControl(method = "cv", number = k_folds),
    tuneGrid = data.frame(k = k_values[i])
  )
  accuracy[i] <- max(knn_model$results$RMSE)
}

# Step 4: Choose optimal K
optimal_k <- k_values[which.max(accuracy)]
cat("Optimal K:", optimal_k, "\n")

# Step 5: Estimate accuracy of optimal KNN classifier on test set
final_knn_model <- knn(train_data[, -ncol(train_data)], test_data[, -ncol(test_data)], train_data$Y, k = optimal_k)
accuracy_on_test <- mean(final_knn_model == test_data$Y)
cat("Accuracy of Optimal KNN Classifier on Test Set:", accuracy_on_test, "\n")