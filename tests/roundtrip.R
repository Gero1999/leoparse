library(leoparse)

check_roundtrip <- function() {
  odd_names <- c("two words", "if", "a\"b", NA_character_, "")
  frame <- data.frame(
    c(2L, NA_integer_),
    c("a\\b", NA_character_),
    factor(c("b", "a")),
    row.names = c("row one", "row two")
  )
  names(frame) <- c("if", "two words", "two words")

  values <- list(
    characters = c("a\"b", "a\\b", "a\nb", "a\tb", "NA", NA_character_),
    integers = c(7L, 7L, 7L, NA_integer_, -2147483647L),
    doubles = c(NA_real_, Inf, -Inf, NaN, pi + 2 * .Machine$double.eps, -0.0),
    logicals = c(TRUE, FALSE, NA),
    missing_character = NA_character_,
    missing_integer = NA_integer_,
    missing_double = NA_real_,
    empty_with_names = structure(character(), names = character()),
    named_vector = setNames(c(1L, 2L, 3L, 4L, 5L), odd_names),
    nested = list(list("plain", NULL), setNames(as.list(seq_along(odd_names)), odd_names)),
    frame = frame,
    empty_frame = frame[FALSE, , drop = FALSE]
  )
  template <- tempfile(fileext = ".R")
  output <- tempfile(fileext = ".R")
  on.exit(unlink(c(template, output)))
  writeLines(paste0(names(values), " <- env_obj$", names(values)), template)

  stopifnot(identical(leoparse_script(template, list2env(values), output), output))
  result <- new.env(parent = baseenv())
  sys.source(output, result)
  for (name in names(values)) {
    if (!identical(result[[name]], values[[name]], num.eq = FALSE)) {
      stop("Value did not round-trip: ", name)
    }
  }
}

check_roundtrip()
