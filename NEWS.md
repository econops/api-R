# Econops 0.1.0

## Initial Release

* Initial release of the Econops API R client
* Provides R6-based client class for interacting with the Econops API
* Supports automatic authentication and request signing
* Includes response caching functionality
* Provides command-line interface for testing
* Includes comprehensive test suite
* Supports all major Econops API endpoints (PCA, ICA, time series analysis, etc.)

## Features

* **Client Class**: R6-based client with methods for API interaction
* **Authentication**: Automatic Bearer token authentication
* **Request Signing**: Secure request signatures for enhanced security
* **Caching**: Automatic response caching to avoid redundant API calls
* **CLI**: Command-line interface for testing and automation
* **Error Handling**: Graceful error handling and informative error messages
* **Documentation**: Comprehensive R documentation with examples

## Usage

```r
library(Econops)

# Initialize client
client <- Client$new(token = "your_api_token")

# Make API request
response <- client$get("/compute/pca", list(
  data = matrix(c(1, 2, 3, 4, 5, 6), nrow = 2, byrow = TRUE),
  n_components = 2
))

# Parse response
result <- jsonlite::fromJSON(rawToChar(response$content))
```

## Dependencies

* httr: HTTP requests
* jsonlite: JSON parsing
* digest: Cryptographic hashing
* R.cache: Caching functionality
* magrittr: Pipe operator
* R6: Object-oriented programming

