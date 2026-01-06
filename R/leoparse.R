
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
  # Handle empty objects
  if (length(object) == 0 && !is.null(object)) {
    return(paste0(class(object)[1], "()"))
  }
  UseMethod("leoparse_deparse")
}


#' @noRd
leoparse_deparse.default <- function(object, indent = 0, max_line_items = 10, min_rep_count = 3) {
  paste(deparse(object, width.cutoff = 500), collapse = "")
}


#' @noRd
leoparse_deparse.data.frame <- function(object, indent = 0, max_line_items = 10, min_rep_count = 3) {
  pad <- paste(rep("  ", indent), collapse = "")
  if (nrow(object) == 0) return("data.frame()")
  col_vals <- lapply(object, function(col) {
    leoparse_deparse(col, indent + 1, max_line_items = max_line_items)
  })
  col_lines <- paste0(pad, "  ", names(object), " = ", unlist(col_vals))
  if (length(col_lines) > 1) {
    col_lines[-length(col_lines)] <- paste0(col_lines[-length(col_lines)], ",")
  }
  paste0("data.frame(\n", paste(col_lines, collapse = "\n"), "\n", pad, ")")
}


#' @noRd
leoparse_deparse.list <- function(object, indent = 0, max_line_items = 10, min_rep_count = 3) {
  pad <- paste(rep("  ", indent), collapse = "")
  n <- length(object)
  nms <- names(object)
  items <- vapply(seq_len(n), FUN.VALUE = "", function(i) {
    nm <- if (!is.null(nms) && nzchar(nms[i])) nms[i] else paste0("V", i)
    if (!grepl("^[A-Za-z.][A-Za-z0-9._]*$", nm)) nm <- sprintf('"%s"', nm)
    val <- object[[i]]
    val_str <- leoparse_deparse(val, indent + 1, max_line_items = max_line_items)
    paste0(nm, " = ", val_str)
  })
  if (length(items) > 1) {
    items[-length(items)] <- paste0(items[-length(items)], ",")
  }
  item_lines <- paste0(pad, "  ", items)
  paste0("list(\n", paste(item_lines, collapse = "\n"), "\n", pad, ")")
}


#' @noRd
leoparse_deparse.character <- function(object, indent = 0, max_line_items = 10, min_rep_count = 3) {
  object <- sprintf('"%s"', object)
  leoparse_vector_deparse(object, indent, max_line_items, min_rep_count)
}

#' @noRd
leoparse_deparse.numeric <- function(object, indent = 0, max_line_items = 10, min_rep_count = 3) {
  object <- sprintf("%s", object)
  leoparse_vector_deparse(object, indent, max_line_items, min_rep_count)
}

#' @noRd
leoparse_deparse.integer <- function(object, indent = 0, max_line_items = 10, min_rep_count = 3) {
  leoparse_deparse.numeric(object, indent = indent, max_line_items = max_line_items, min_rep_count = min_rep_count)
}

#' @noRd
leoparse_deparse.logical <- function(object, indent = 0, max_line_items = 10, min_rep_count = 3) {
  object <- as.character(object)
  leoparse_vector_deparse(object, indent, max_line_items, min_rep_count)
}


#' Internal helper to deparse atomic vectors with repetition and line splitting
#' @noRd
leoparse_vector_deparse <- function(object, indent = 0, max_line_items = 10, min_rep_count = 3) {
  n <- length(object)
  if (n == 1) {
    return(object)
  } else {
    rle_obj <- rle(object)
    out_items <- c()
    for (i in seq_along(rle_obj$values)) {
      val <- rle_obj$values[i]
      len <- rle_obj$lengths[i]
      if (len >= min_rep_count) {
        out_items <- c(out_items, paste0("rep(", val, ", ", len, ")"))
      } else {
        out_items <- c(out_items, rep(val, len))
      }
    }
  }
  pad <- paste(rep("  ", indent), collapse = "")
  split_lines <- split(out_items, ceiling(seq_along(out_items) / max_line_items))
  line_strs <- vapply(split_lines, function(x) paste(x, collapse = ", "), "")
  if (is.list(split_lines) && length(split_lines) > 1) {
    out <- paste0(pad, "  ", line_strs, collapse = ",\n")
    paste0("c(\n", out, "\n", pad, ")")
  } else {
    paste0("c(", paste0(line_strs, collapse = ",\n"), ")")
  }
}