# leoparse <img src="man/figures/logo.svg" alt="leoparse hex sticker with a gold tiger silhouette" align="right" width="120">

**Turn environment-backed R templates into scripts you can share and rerun.**

`leoparse_script()` reads an R template, resolves references such as
`env_obj$settings$threshold` against an environment, and writes a script with
the current values inserted as R code. The generated script can run in a fresh
R session without the original environment.

## Install

Install the development version from GitHub. The package uses base R at runtime.

```r
if (!requireNamespace("remotes", quietly = TRUE)) {
  install.packages("remotes", repos = "https://cloud.r-project.org")
}
remotes::install_github("Gero1999/leoparse")
```

## Generate and run a script

Create a template and an environment containing the values it needs. The
template uses the literal prefix `env_obj$` even if your environment has a
different name.

```r
template_file <- tempfile(fileext = ".R")
output_file <- tempfile(fileext = ".R")

writeLines(c(
  "values <- env_obj$values",
  "threshold <- env_obj$settings$threshold",
  "sum(values > threshold)"
), template_file)

inputs <- new.env(parent = emptyenv())
inputs$values <- c(1, 4, 7)
inputs$settings <- list(threshold = 3)

leoparse::leoparse_script(template_file, inputs, output_file)

writeLines(readLines(output_file))
# values <- c(1, 4, 7)
# threshold <- 3
# sum(values > threshold)

source(output_file, local = new.env(parent = baseenv()))$value
# [1] 2
```

The values become part of the generated file. Review its contents before
sharing, especially if your template references private data.

## Contribute

leoparse is in early development. Report bugs and suggest changes in
[GitHub Issues](https://github.com/Gero1999/leoparse/issues).
