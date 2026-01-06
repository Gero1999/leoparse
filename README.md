
# leoparse: Environment-Aware Code Deparser

> An R package to deparse code that uses environment objects into beautiful and reproducible scripts. Free, open source, and designed for everyone who values reproducibility and clarity in R workflows.

<br/>

## Description

`leoparse` is an R package that helps you transform code that relies on environment objects into clean, readable, and fully reproducible R scripts. It analyzes your code, extracts dependencies from environments, and generates scripts that can be shared, versioned, and rerun anywhere.

This package is ideal for users who want to:
- Refactor code that depends on hidden or session-specific environments
- Share reproducible scripts with collaborators
- Improve transparency and auditability of R analyses

`leoparse` is under active development. Contributions and suggestions for new features are welcome!



## Installation

leoparse is not yet on CRAN. To install the development version, clone the repository:

```bash
git clone https://github.com/Gero1999/leoparse
```

Then load it in your R session using [devtools](https://github.com/r-lib/devtools):

```R
if (!requireNamespace("devtools", quietly = TRUE)) {
  install.packages("devtools")
}
devtools::load_all()
```


## Quick start

To use leoparse, load the package and call its main function on your code or environment:

```R
devtools::load_all()
# Example usage:
leoparse::deparse_env(my_environment)
```

This will generate a reproducible script from all code and objects in `my_environment`.


## Contributing

leoparse is in early development and welcomes contributors!
See our [contributing guidelines](https://github.com/Gero1999/leoparse/CONTRIBUTING.md).



## Documentation and references

- More documentation will be available soon.
- For questions or suggestions, please open an issue on GitHub.
