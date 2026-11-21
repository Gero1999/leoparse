
#' Generate a reproducible R script from environment-based code
#'
#' @param template_file Path to the R script template (e.g., "template.R")
#' @param env_obj An environment containing objects to extract
#' @param output_file Path to write the resulting script (e.g., "leoparse_script.R")
#' @return Invisibly returns the output_file path
#' @export
leoparse_script <- function(template_file, env_obj, output_file) {
  # Helper: extract value from environment by path (e.g., 'settings$method')
  env_extract <- function(path_str) {
    keys <- strsplit(path_str, "\\$")[[1]]
    val <- env_obj
    for (key in keys) {
      if (is.environment(val)) {
        val <- val[[key]]
      } else if (inherits(val[[key]], "reactive")) {
        val <- val[[key]]()
      } else {
        val <- val[[key]]
      }
      if (is.null(val)) return(NULL)
    }
    val
  }

  # Read template
  template_txt <- paste(readLines(template_file, warn = FALSE), collapse = "\n")

  # Find all env_obj$... placeholders
  placeholder_pattern <- "env_obj(\\$[a-zA-Z0-9_]+(\\(\\))?(\\$[a-zA-Z0-9_]+)*)"
  found <- gregexpr(placeholder_pattern, template_txt, perl = TRUE)[[1]]
  if (found[1] == -1) {
    stop(
      "Template contains no env_obj placeholders to substitute.\n",
      "Check the template path or ensure placeholders are present."
    )
  }

  # Substitute each placeholder with deparsed value
  for (i in rev(seq_along(found))) {
    idx <- found[i]
    plen <- attr(found, "match.length")[i]
    match_str <- substr(template_txt, idx, idx + plen - 1)
    # Extract path after env_obj$
    path <- sub("^env_obj\\$", "", match_str)
    val <- env_extract(path)
    code_str <- leoparse_deparse(val, max_line_items = 15)
    template_txt <- paste0(
      substr(template_txt, 1, idx - 1),
      code_str,
      substr(template_txt, idx + plen, nchar(template_txt))
    )
  }

  # Write output
  out_lines <- strsplit(template_txt, "\n")[[1]]
  writeLines(out_lines, output_file)
  invisible(output_file)
}


#' Deparse R objects into reproducible R code (internal)
#'
#' Converts R objects (data frames, lists, vectors, etc.) into character strings
#' containing R code to reconstruct them. Used by leoparse_script to serialize
#' environment objects into runnable R code.
#'
#' @param object R object to convert
#' @param indent Indentation level for multi-line outputs
#' @param max_line_items Max elements per line for long vectors/lists
#' @param min_rep_count Minimum repeated elements to use rep()
#' @return String of R code
#' @keywords internal
leoparse_deparse <- function(object, indent = 0, max_line_items = 10, min_rep_count = 3) {
  UseMethod("leoparse_deparse")
}


#' @noRd
leoparse_deparse.default <- function(object, indent = 0, max_line_items = 10, min_rep_count = 3) {
  paste(deparse(object, width.cutoff = 80L, control = c("all", "digits17")), collapse = "\n")
}


#' @noRd
leoparse_deparse_atomic <- function(object, indent = 0, max_line_items = 10, min_rep_count = 3) {
  # Deparse attributed vectors as a whole to preserve their names, shape, and class.
  if (!is.null(attributes(object)) || length(object) == 0L) {
    return(leoparse_deparse.default(object))
  }

  literals <- vapply(object, leoparse_deparse.default, character(1), USE.NAMES = FALSE)
  leoparse_vector_deparse(literals, indent, max_line_items, min_rep_count)
}

leoparse_deparse.character <- leoparse_deparse_atomic
leoparse_deparse.numeric <- leoparse_deparse_atomic
leoparse_deparse.integer <- leoparse_deparse_atomic
leoparse_deparse.logical <- leoparse_deparse_atomic


#' Internal helper to format vector literals with repetition and line splitting
#' @noRd
leoparse_vector_deparse <- function(literals, indent = 0, max_line_items = 10, min_rep_count = 3) {
  if (length(literals) == 1L) {
    return(literals)
  }

  runs <- rle(literals)
  items <- unlist(Map(function(literal, count) {
    if (count >= min_rep_count) {
      return(paste0("rep(", literal, ", ", count, ")"))
    }
    rep(literal, count)
  }, runs$values, runs$lengths), use.names = FALSE)
  lines <- split(items, ceiling(seq_along(items) / max_line_items))
  lines <- vapply(lines, paste, character(1), collapse = ", ")
  if (length(lines) == 1L) {
    return(paste0("c(", lines, ")"))
  }

  pad <- strrep("  ", indent)
  contents <- paste0(pad, "  ", lines, collapse = ",\n")
  paste0("c(\n", contents, "\n", pad, ")")
}
