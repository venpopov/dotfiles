.libPaths(c(.libPaths(), "/Users/vpopov/R/vscode-R/renv/library/macos/R-4.4/aarch64-apple-darwin23.4.0"))

print("Hello World")

if (interactive() && Sys.getenv("RSTUDIO") == "") {
  try(
    source(
      file.path(
        Sys.getenv(if (.Platform$OS.type == "windows") "USERPROFILE" else "HOME"),
        ".vscode-R", "init.R"
      )
    )
  )
}

# if (interactive()) {
#   suppressMessages(require(devtools))
#   suppressMessages(require(reprex))
#   suppressMessages(require(usethis))
#   suppressMessages(require(gert))
#   suppressMessages(require(targets))
# }

options(
  # default settings for package documentation
  usethis.description = list(
    "Authors@R" = utils::person(
      "Ven", "Popov",
      email = "vencislav.popov@gmail.com",
      role = c("aut", "cre"),
      comment = c(ORCID = "0000-0002-8073-4199")
    ),
    License = "MIT + file LICENSE"
  ),
  
  # default cran repo to avoid prompts when installing packages
  repos = c(CRAN = "https://cran.r-project.org"),

  # prevent as_job because it doesn't work in vscode
  quarto.render_as_job = FALSE
)


# allows user defined shortcuts, these keys should be escaped when send through the terminal.
# In the following example, `esc` + `-` sends `<-` and `ctrl` + `right` sends `%>%`.
# Note that in some terminals, you could mark `alt` as `escape` so you could use `alt` + `-` instead.
# Also, note that some ctrl mappings are reserved. You cannot remap m, i, h, d, or c
options(
  radian.escape_key_map = list(
    list(key = "-", value = " <- ")
  ),
  radian.ctrl_key_map = list(
    list(key = "k", value = " %>% ")
  )
)


better_rprofile <- function() {
  contents <- 'Sys.setenv(
  RENV_CONFIG_RSPM_ENABLED = FALSE,
  RENV_CONFIG_SANDBOX_ENABLED = FALSE
)

if (requireNamespace("rprofile", quietly = TRUE)) {
  rprofile::load(dev = quote(reload()))
} else {
  source("renv/activate.R")
}'
  writeLines(contents, con = ".Rprofile")
}
