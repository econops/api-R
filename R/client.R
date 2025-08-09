#' Generate a unique signature for route and request data
#' 
#' @param route The API route (e.g., "/compute/pca")
#' @param request_data The JSON request data as a list
#' @param pregiven If not NULL, return this value directly (for caching/pre-computed signatures)
#' 
#' @return A unique hash string representing the route and request data combination
#' @keywords internal
callsignature <- function(route, request_data, pregiven = NULL) {
  if (!is.null(pregiven)) {
    return(pregiven)
  }
  
  # Create a deterministic string representation of the data
  # Sort the request data to ensure consistent hashing regardless of key order
  sorted_data <- jsonlite::toJSON(request_data, auto_unbox = TRUE, digits = 10)
  
  # Generate SHA-256 hash
  route_hash <- digest::digest(route, algo = "sha256")
  data_hash <- digest::digest(sorted_data, algo = "sha256")
  
  return(paste0(route, data_hash))
}

#' Get the cache directory for storing API responses
#' 
#' @return Path to cache directory
#' @keywords internal
get_cache_dir <- function() {
  # Use R's tempdir() for cross-platform compatibility
  cache_dir <- file.path(tempdir(), "econops_cache")
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  return(cache_dir)
}

#' Retrieve cached response for a given signature
#' 
#' @param signature The request signature to look up
#' 
#' @return Cached response data or NULL if not found
#' @keywords internal
get_cached_response <- function(signature) {
  tryCatch({
    cache_dir <- get_cache_dir()
    # Clean signature to avoid path issues
    clean_signature <- gsub("[^a-zA-Z0-9]", "_", signature)
    cache_file <- file.path(cache_dir, paste0(clean_signature, ".rds"))
    
    if (file.exists(cache_file)) {
      cached_data <- readRDS(cache_file)
      return(cached_data)
    }
  }, error = function(e) {
    # Silently fail if cache doesn't work
    return(NULL)
  })
  
  return(NULL)
}

#' Cache a response for future use
#' 
#' @param signature The request signature as cache key
#' @param response_data The response data to cache
#' @keywords internal
cache_response <- function(signature, response_data) {
  tryCatch({
    cache_dir <- get_cache_dir()
    # Clean signature to avoid path issues
    clean_signature <- gsub("[^a-zA-Z0-9]", "_", signature)
    cache_file <- file.path(cache_dir, paste0(clean_signature, ".rds"))
    saveRDS(response_data, cache_file)
  }, error = function(e) {
    # Silently fail if we can't write to cache
    # Don't show warning - caching is optional
  })
}

#' EconOps API Client
#' A client for making requests to the EconOps API with automatic authentication
#' and request signing.
#' @field token API token
#' @field base_url Base URL for the API
#' @field use_cache Whether to use response caching
#' @field headers Default headers for requests
#' @examples
#' \dontrun{
#' # Initialize client with token
#' client <- Client$new(token = "your_api_token")
#' 
#' # Make a request
#' response <- client$get("/compute/pca", list(
#'   data = matrix(c(1, 2, 3, 4, 5, 6), nrow = 2, byrow = TRUE),
#'   n_components = 2
#' ))
#' }
#' 
#' @export
Client <- R6::R6Class("Client",
  public = list(
    token = NULL,
    base_url = NULL,
    use_cache = NULL,
    headers = NULL,
    
    #' @description Initialize a new Client instance
    #' @param token API token. If not provided, will try to get from 'ECONOPS_TOKEN' environment variable.
    #' @param base_url Base URL for the API. Defaults to "https://econops.com:8000".
    #' @param use_cache Whether to use response caching. Defaults to TRUE.
    initialize = function(token = NULL, base_url = "https://econops.com:8000", use_cache = TRUE) {
      # Get token from parameter or environment
      self$token <- token %||% Sys.getenv("ECONOPS_TOKEN", "demo")
      if (self$token == "") {
        stop("Token not provided and 'ECONOPS_TOKEN' environment variable not found")
      }
      
      self$base_url <- gsub("/$", "", base_url)
      self$use_cache <- use_cache
      
      # Prepare default headers
      self$headers <- list(
        "Authorization" = paste("Bearer", self$token),
        "Content-Type" = "application/json"
      )
    },
    
    #' @description Make a request to any route with bearer token authentication
    #' @param route The API route to call (e.g., "/compute/pca")
    #' @param data Data to send in the request body
    #' @param method HTTP method (GET, POST, etc.)
    #' @return httr::response object
    get = function(route, data = NULL, method = "POST") {
      # Generate signature for the request
      request_data <- data %||% list()
      signature <- callsignature(route, request_data)
      
      # Check cache first (only for GET requests or when explicitly requested)
      if (self$use_cache && (toupper(method) == "GET" || is.null(data))) {
        cached_response <- get_cached_response(signature)
        if (!is.null(cached_response)) {
          # Create a mock response object from cached data
          mock_response <- structure(
            list(
              status_code = cached_response$status_code,
              content = charToRaw(jsonlite::toJSON(cached_response$data, auto_unbox = TRUE)),
              headers = cached_response$headers
            ),
            class = "response"
          )
          return(mock_response)
        }
      }
      
      # Make actual API request
      url <- paste0(self$base_url, route)
      
      # Add signature to payload for security (never in URL)
      # Force POST for requests with data to keep signature in payload
      if (!is.null(data)) {
        method <- "POST"  # Override GET to POST for data requests
      }
      
      if (toupper(method) == "GET") {
        # For GET requests without data, use simple GET (no signature needed)
        response <- httr::GET(url, httr::add_headers(.headers = unlist(self$headers)), httr::config(ssl_verifypeer = FALSE))
      } else {
        # For POST/PUT requests, add signature to payload
        payload <- data %||% list()
        payload$signature <- signature
        response <- httr::POST(url, 
                              httr::add_headers(.headers = unlist(self$headers)), 
                              body = jsonlite::toJSON(payload, auto_unbox = TRUE),
                              httr::config(ssl_verifypeer = FALSE))
      }
      
      # Cache successful responses
      if (self$use_cache && httr::status_code(response) == 200) {
        tryCatch({
          response_data <- list(
            status_code = httr::status_code(response),
            data = jsonlite::fromJSON(rawToChar(response$content)),
            headers = as.list(response$headers)
          )
          cache_response(signature, response_data)
        }, error = function(e) {
          # Don't cache non-JSON responses
          warning("Failed to parse response for caching: ", e$message)
        })
      }
      
      return(response)
    },
    
    #' @description Clear all cached responses
    clear_cache = function() {
      cache_dir <- get_cache_dir()
      cache_files <- list.files(cache_dir, pattern = "\\.rds$", full.names = TRUE)
      unlink(cache_files, force = TRUE)
    },
    
    #' @description Get information about the cache
    #' @return List with cache statistics
    get_cache_info = function() {
      tryCatch({
        cache_dir <- get_cache_dir()
        cache_files <- list.files(cache_dir, pattern = "\\.rds$", full.names = TRUE)
        
        cache_size <- sum(file.size(cache_files))
        
        return(list(
          cache_directory = cache_dir,
          cached_requests = length(cache_files),
          cache_size_bytes = cache_size
        ))
      }, error = function(e) {
        return(list(
          cache_directory = "Not available",
          cached_requests = 0,
          cache_size_bytes = 0
        ))
      })
    }
  )
)

#' Helper function for NULL coalescing
#' @keywords internal
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

