#' Command Line Interface for EconOps API
#' 
#' This module provides command-line functionality for the EconOps API client.
#' 
#' @param args Command line arguments
#' @export
main <- function(args = commandArgs(trailingOnly = TRUE)) {
  if (length(args) == 0) {
    cat("EconOps API R Client\n")
    cat("Usage: Rscript -e 'econops::main()' <route> [data]\n")
    cat("Example: Rscript -e 'econops::main()' /compute/pca '{\"data\":[[1,2,3]],\"n_components\":2}'\n")
    return(invisible(NULL))
  }
  
  route <- args[1]
  data_json <- if (length(args) > 1) args[2] else NULL
  
  # Parse data if provided
  data <- NULL
  if (!is.null(data_json) && data_json != "") {
    tryCatch({
      data <- jsonlite::fromJSON(data_json)
    }, error = function(e) {
      stop("Invalid JSON data: ", e$message)
    })
  }
  
  # Initialize client
  client <- Client$new()
  
  # Make request
  tryCatch({
    response <- client$get(route, data)
    
    # Print response
    if (httr::status_code(response) == 200) {
      result <- jsonlite::fromJSON(rawToChar(response$content))
      cat(jsonlite::toJSON(result, pretty = TRUE, auto_unbox = TRUE), "\n")
    } else {
      cat("Error:", httr::status_code(response), "\n")
      cat(rawToChar(response$content), "\n")
    }
  }, error = function(e) {
    cat("Error:", e$message, "\n")
    quit(status = 1)
  })
}

#' Interactive CLI for EconOps API
#' 
#' Provides an interactive command-line interface for testing the API.
#' 
#' @export
interactive_cli <- function() {
  cat("EconOps API Interactive CLI\n")
  cat("Type 'quit' to exit\n\n")
  
  client <- Client$new()
  
  repeat {
    cat("econops> ")
    input <- readline()
    
    if (input == "quit" || input == "exit") {
      break
    }
    
    if (input == "") {
      next
    }
    
    # Parse input (simple format: route [json_data])
    parts <- strsplit(input, " ", fixed = TRUE)[[1]]
    route <- parts[1]
    data_json <- if (length(parts) > 1) paste(parts[-1], collapse = " ") else NULL
    
    # Parse data if provided
    data <- NULL
    if (!is.null(data_json) && data_json != "") {
      tryCatch({
        data <- jsonlite::fromJSON(data_json)
      }, error = function(e) {
        cat("Invalid JSON data: ", e$message, "\n")
        next
      })
    }
    
    # Make request
    tryCatch({
      response <- client$get(route, data)
      
      if (httr::status_code(response) == 200) {
        result <- jsonlite::fromJSON(rawToChar(response$content))
        cat(jsonlite::toJSON(result, pretty = TRUE, auto_unbox = TRUE), "\n")
      } else {
        cat("Error:", httr::status_code(response), "\n")
        cat(rawToChar(response$content), "\n")
      }
    }, error = function(e) {
      cat("Error:", e$message, "\n")
    })
    
    cat("\n")
  }
  
  cat("Goodbye!\n")
}

