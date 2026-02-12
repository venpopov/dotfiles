# -------------------------------------------------------------------- #
# VSCODE setup ----
# -------------------------------------------------------------------- #
if (interactive() && Sys.getenv("RSTUDIO") == "") {
  try(
    source(
      file.path(
        Sys.getenv(if (.Platform$OS.type == "windows") "USERPROFILE" else "HOME"),
        ".vscode-R", "init.R"
      )
    )
  )
  require(languageserver, quietly = TRUE)
  require(httpgd, quietly = TRUE)
}

# -------------------------------------------------------------------- #
# Load default dev packages ----
# -------------------------------------------------------------------- #

if (interactive()) {
  require(devtools, quietly = TRUE)
  require(reprex, quietly = TRUE)
  require(usethis, quietly = TRUE)
  require(gert, quietly = TRUE)
  require(fs, quietly = TRUE)
}


# -------------------------------------------------------------------- #
# Convenience options ----
# -------------------------------------------------------------------- #
options(
  # default settings for package documentation
  usethis.description = list(
    "Authors@R" = utils::person(
      "Ven", "Popov",
      email = "vencislav.popov@gmail.com",
      role = c("aut", "cre"),
      comment = c(ORCID = "0000-0002-8073-4199")
    ),
    License = "MIT + file LICENSE",
    Additional_repositories = "https://stan-dev.r-universe.dev"
  ),
  usethis.destdir = "~/GitHub",
  usethis.overwrite = TRUE,
  
  # default cran repo to avoid prompts when installing packages
  # repos = c(
  #   CRAN = "https://cran.r-project.org",
  #   stan = "https://stan-dev.r-universe.dev"
  # ),

  # prevent as_job because it doesn't work in vscode
  quarto.render_as_job = FALSE
)


# -------------------------------------------------------------------- #
# Radian setup ----
# -------------------------------------------------------------------- #
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
