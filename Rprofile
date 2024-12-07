
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

if (interactive()) {
  require(devtools, quietly = TRUE)
  require(reprex, quietly = TRUE)
  require(usethis, quietly = TRUE)
  require(gert, quietly = TRUE)
  require(targets, quietly = TRUE)
  require(fs, quietly = TRUE)
}

if (interactive() || isatty(stdout())) {
  options(colorout.verbose = 1)
  if (require("colorout", quietly = FALSE)) {
    # Gruvbox color scheme by @sjlva
    colorout::setOutputColors(
      index    = "\x1b[38;2;215;153;33m",
      normal   = "\x1b[38;2;235;219;178m",
      number   = "\x1b[38;2;211;134;155m",
      negnum   = "\x1b[38;2;104;157;106m",
      zero     = "\x1b[38;2;69;133;136m",
      infinite = "\x1b[38;2;250;189;47m",
      string   = "\x1b[38;2;184;187;38m",
      date     = "\x1b[38;2;254;128;25m",
      const    = "\x1b[38;2;250;189;47m",
      true     = "\x1b[38;2;142;192;124m",
      false    = "\x1b[38;2;251;73;52m",
      warn     = "\x1b[38;2;250;189;47m",
      stderror = "\x1b[38;2;204;36;29m",
      error    = "\x1b[38;2;204;36;29m",
      verbose  = TRUE
    )
  }
}


function(scope = c("user", "project")) {
  path <- scoped_path_r(scope, ".Rprofile", envvar = "R_PROFILE_USER")
  edit_file(path)
  ui_bullets(c(`_` = "Restart R for changes to take effect."))
  invisible(path)
}


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


# ------------------------------------------------------------------------
# Attach a hidden environment with functions I want to have accessible in standard R sessions,
# but which I don't want to show up as objects. I do this by creating a new environment .env, 
# storing all fucntions in it and then attaching this environment
.env <- new.env()
.env$better_rprofile <- function() {
  contents <- 'Sys.setenv(
  RENV_CONFIG_RSPM_ENABLED = FALSE,
  RENV_CONFIG_SANDBOX_ENABLED = FALSE
)

if (requireNamespace("rprofile", quietly = TRUE)) {
  rprofile::load(dev = quote(reload()))
} else {
  source("renv/activate.R")
}'

  if (file.exists(".Rprofile")) {
    action <- "overwrite"
    message <- ".Rprofile already exists. Do you want to overwrite it? (yes/no): "
  } else {
    action <- "create"
    message <- "Do you want to create the .Rprofile file? (yes/no): "
  }

  cat(message)
  response <- tolower(readLines(con = "stdin", n = 1))

  if (response == "yes") {
    writeLines(contents, con = ".Rprofile")
    cat(sprintf(".Rprofile has been %sed.\n", action))
  } else {
    cat(sprintf(".Rprofile has not been %sed.\n", action))
  }
}

attach(.env)
