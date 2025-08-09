# Example usage of the EconOps R client
# 
# This script demonstrates how to use the EconOps API client in R

library(econops)

# Initialize the client
client <- Client$new(token = "your_api_token")

# Example 1: Principal Component Analysis
cat("=== PCA Example ===\n")

# Create sample data
data_matrix <- matrix(c(1, 2, 3, 4, 5, 6, 7, 8, 9), nrow = 3, byrow = TRUE)

# Make PCA request
response <- client$get("/compute/pca", list(
  data = data_matrix,
  n_components = 2
))

if (httr::status_code(response) == 200) {
  result <- jsonlite::fromJSON(rawToChar(response$content))
  cat("PCA completed successfully!\n")
  cat("Explained variance:", result$explained_variance, "\n")
} else {
  cat("Error:", httr::status_code(response), "\n")
  cat(rawToChar(response$content), "\n")
}

# Example 2: Time Series Analysis with Prophet
cat("\n=== Time Series Analysis Example ===\n")

# Sample time series data
dates <- c("2023-01-01", "2023-01-02", "2023-01-03", "2023-01-04", "2023-01-05")
values <- c(10, 12, 11, 13, 15)

response <- client$get("/compute/ts/prophet", list(
  dates = dates,
  values = values,
  forecast_periods = 3
))

if (httr::status_code(response) == 200) {
  result <- jsonlite::fromJSON(rawToChar(response$content))
  cat("Prophet forecasting completed!\n")
  cat("Forecast periods:", length(result$forecast$predictions), "\n")
} else {
  cat("Error:", httr::status_code(response), "\n")
  cat(rawToChar(response$content), "\n")
}

# Example 3: Cache management
cat("\n=== Cache Management ===\n")

# Get cache info
cache_info <- client$get_cache_info()
cat("Cache directory:", cache_info$cache_directory, "\n")
cat("Cached requests:", cache_info$cached_requests, "\n")
cat("Cache size (bytes):", cache_info$cache_size_bytes, "\n")

# Clear cache if needed
# client$clear_cache()

cat("\n=== Example completed ===\n")

