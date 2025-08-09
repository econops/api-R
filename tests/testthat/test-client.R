library(testthat)
library(econops)

test_that("Client initialization works", {
  # Test with token parameter
  client <- Client$new(token = "test_token")
  expect_equal(client$token, "test_token")
  expect_equal(client$base_url, "https://econops.com:8000")
  expect_true(client$use_cache)
  
  # Test with environment variable
  Sys.setenv(ECONOPS_TOKEN = "env_token")
  client_env <- Client$new()
  expect_equal(client_env$token, "env_token")
  
  # Test with custom base_url
  client_custom <- Client$new(token = "test", base_url = "https://custom.com")
  expect_equal(client_custom$base_url, "https://custom.com")
  
  # Test with use_cache = FALSE
  client_no_cache <- Client$new(token = "test", use_cache = FALSE)
  expect_false(client_no_cache$use_cache)
})

test_that("callsignature function works", {
  route <- "/compute/pca"
  data <- list(data = matrix(c(1, 2, 3, 4), nrow = 2), n_components = 2)
  
  signature1 <- callsignature(route, data)
  signature2 <- callsignature(route, data)
  
  # Should be consistent
  expect_equal(signature1, signature2)
  
  # Should be different for different data
  data2 <- list(data = matrix(c(1, 2, 3, 5), nrow = 2), n_components = 2)
  signature3 <- callsignature(route, data2)
  expect_false(signature1 == signature3)
})

test_that("Cache functions work", {
  # Test cache directory creation
  cache_dir <- get_cache_dir()
  expect_true(dir.exists(cache_dir))
  
  # Test caching and retrieval
  test_data <- list(test = "data")
  signature <- "test_signature"
  
  cache_response(signature, test_data)
  retrieved <- get_cached_response(signature)
  
  expect_equal(retrieved, test_data)
})

test_that("Client get method handles errors gracefully", {
  client <- Client$new(token = "invalid_token")
  
  # This should not crash even with invalid token
  expect_error(
    client$get("/nonexistent/route"),
    NA
  )
})

test_that("Cache info returns correct structure", {
  client <- Client$new(token = "test")
  info <- client$get_cache_info()
  
  expect_true(is.list(info))
  expect_true("cache_directory" %in% names(info))
  expect_true("cached_requests" %in% names(info))
  expect_true("cache_size_bytes" %in% names(info))
})

test_that("Clear cache works", {
  client <- Client$new(token = "test")
  
  # Add some test data to cache
  test_data <- list(test = "data")
  cache_response("test_sig", test_data)
  
  # Clear cache
  client$clear_cache()
  
  # Verify cache is empty
  info <- client$get_cache_info()
  expect_equal(info$cached_requests, 0)
})

