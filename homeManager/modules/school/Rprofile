# Set CRAN Mirror:
local({
  r <- getOption("repos")
  r["CRAN"] <- "https://cloud.r-project.org/"
  options(repos = r)
})

# Use HTTPS
options(download.file.method = "libcurl")

# Set prompt
options(prompt = "r \x1b[32m>\x1b[0m ", continue = "    ")

# Colour output
require("colorout", quietly = TRUE)
colorout::setOutputColors(
  normal = 2, negnum = 3, zero = 3, number = 3,
  date = 3, string = 6, const = 5, false = 5,
  true = 2, infinite = 5, index = 2, stderror = 4,
  warn = c(1, 0, 1), error = c(1, 7),
  verbose = FALSE, zero.limit = NA
)

# Return previous value as fraction
last_frac <- function() {
  library(MASS)
  return(as.fractions(.Last.value))
}
