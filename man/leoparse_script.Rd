\name{leoparse_script}
\alias{leoparse_script}
\title{Generate a Script from Environment-Based Code}
\description{
Replaces references to objects in an environment with R code that
reconstructs those objects in a standalone script.
}
\usage{
leoparse_script(template_file, env_obj, output_file)
}
\arguments{
  \item{template_file}{Path to a script template containing
  references such as \code{env_obj$settings$label}.}
  \item{env_obj}{Environment containing the objects referenced by the
  template.}
  \item{output_file}{Path to write the generated script.}
}
\value{The output path, invisibly.}
\examples{
inputs <- list2env(list(settings = list(label = "Example")))
template <- tempfile(fileext = ".R")
output <- tempfile(fileext = ".R")
writeLines("label <- env_obj$settings$label", template)
leoparse_script(template, inputs, output)

result <- new.env()
sys.source(output, envir = result)
result$label
unlink(c(template, output))
}
