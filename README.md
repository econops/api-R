# EconOps API R Client

An R client for the EconOps API providing statistical and data science capabilities for economics and finance.

## Installation

### From CRAN (when published)
```r
install.packages("econops")
```

### From GitHub
```r
# Install devtools if you haven't already
if (!require(devtools)) install.packages("devtools")

# Install from GitHub
devtools::install_github("econops/api-R")
```

### Development installation
```r
# Clone the repository and install locally
devtools::install_local("path/to/api-R")
```

## Quick Start

```r
library(econops)

# Initialize client with your API token
client <- Client$new(token = "your_api_token")

# Make a request to the API
response <- client$get("/compute/pca", list(
  data = matrix(c(1, 2, 3, 4, 5, 6), nrow = 2, byrow = TRUE),
  n_components = 2
))

print(response$content)
```

## Environment Variables

You can set your API token as an environment variable:

```r
Sys.setenv(ECONOPS_TOKEN = "your_api_token")
```

Then use the client without passing the token:

```r
library(econops)
client <- Client$new()  # Will use ECONOPS_TOKEN environment variable
```

## API Reference

### Client Class

The main `Client` class provides methods to interact with the Econops API.

#### Constructor

```r
Client$new(token = NULL, base_url = "https://econops.com:8000", use_cache = TRUE)
```

- `token` (character, optional): Your API token. If not provided, will try to get from `ECONOPS_TOKEN` environment variable.
- `base_url` (character): Base URL for the API. Defaults to "https://econops.com:8000".
- `use_cache` (logical): Whether to use response caching. Defaults to TRUE.

#### Methods

##### get(route, data = NULL, method = "POST")

Make a request to any API route with automatic authentication and request signing.

- `route` (character): The API route to call (e.g., "/compute/pca")
- `data` (list, optional): Data to send in the request body
- `method` (character): HTTP method (GET, POST, etc.)

**Security:** Request signatures are included in the payload (not headers) for enhanced security.

Returns: `httr::response` object

##### clear_cache()

Clear all cached responses.

##### get_cache_info()

Get information about the cache.

Returns: List with cache statistics

## Examples

### Principal Component Analysis
```r
library(econops)

client <- Client$new(token = "your_token")

# Perform PCA on your data
response <- client$get("/compute/pca", list(
  data = your_data_matrix,
  n_components = 3
))

result <- jsonlite::fromJSON(rawToChar(response$content))
```

### Time Series Analysis
```r
response <- client$get("/compute/timeseries", list(
  data = time_series_data,
  method = "arima"
))
```

### Caching

The client automatically caches responses to avoid redundant API calls:

```r
# First call hits the API
response1 <- client$get("/compute/pca", list(data = matrix(c(1,2,3), nrow = 1)))

# Second call with same data returns cached result (even if route changes)
response2 <- client$get("/api/v2/pca", list(data = matrix(c(1,2,3), nrow = 1)))  # Same cache hit!

# Cache management
client$clear_cache()  # Clear all cached responses
info <- client$get_cache_info()  # Get cache statistics
print(info)
# $cache_directory: "/home/user/.econops/cache"
# $cached_requests: 5
# $cache_size_bytes: 1024
```

**Note:** Caching is based on request data only, not the route. This allows for API refactoring without breaking cache compatibility.

## Development

### Running Tests
```r
devtools::test()
```

### Code Formatting
```r
# Install styler if you haven't already
if (!require(styler)) install.packages("styler")

# Format code
styler::style_dir()
```

### Documentation
```r
# Generate documentation
devtools::document()
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## Support

- Documentation: https://econops.com/docs/r
- Issues: https://github.com/econops/api-R/issues
- Email: info@econops.com

