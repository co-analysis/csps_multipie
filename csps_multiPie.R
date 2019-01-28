### This file loads the relevant libraries and stores the key functions
### to make CSPS MultiPies (Civil Service People Survey multiple pie
### charts). These are graphs of pie charts of organisation scores
### with the size of the pie chart being quasi-proportionate to the
### headcount of the organisation.

###
### To use CSPS MultiPie you will need:
###   1. a csv file with organisation codes and headcounts
###   2. a csv file with organisation codes and CSPS (scores)
###
### In Dataset [1] must be formed of two columns: 'org' for the organisation
### codes and 'hc' for headcounts.
###
### In Dataset [2] again there must be a column called 'org' for the
### organisation codes, but you can have multiple columns of organisation
### scores.
###

# check if required packages installed, if not try to install

load_pkgs <- function() {

  pkgs <- c("tidyverse", "formattable", "govstyle", "stringr", "glue")

  for (p in pkgs) {

    if ((p %in% installed.packages()) == FALSE) {

      if (p == "govstyle") {

        if (("remotes" %in% installed.packages()) == FALSE) {

          usr_inp <- readline(paste0("Need to install package \'remotes\'. ",
                                   "Is that ok? (y/n): ")
          )

          if (tolower(usr_inp) != "y") {
            stop("Install aborted")
          }

          install.packages("remotes")

        }

        usr_inp <- readline(paste0("Need to install package \'gov_style\'. ",
                                   "Is that ok? (y/n): "))

        if (tolower(usr_inp) != "y") {
          stop("Install aborted")
        }

        remotes::install_github("ukgovdatascience/govstyle")

      } else {

          usr_inp <- readline(paste0("Need to install package \'", p, "\'. ",
                                   "Is that ok? (y/n): "))

          if (tolower(usr_inp) != "y") {
            stop("Install aborted")
          }

          install.packages(p)

      }
    }

    library(p, character.only = TRUE)
  }

}



# function to import a dataset, runs sense checks before importing data after
# importing data checks for existence of a character column for orgcodes
# (column named 'org' as well as formatting column names into lowercase and
# formating orgcodes into uppercase

import_dataset <- function(dataset) {

  # check if dataset provided
  if (missing(dataset)) {
    stop("Please specify a dataset.")
  }

  # check if only one dataset has been passed to the function
  if (length(dataset) == 0) {
    stop("Please specify a dataset")
  } else if (length(dataset) > 1) {
    stop("Please only provide one dataset.")
  }

  # check dataset name is a character string
  if ((is_character(dataset)) == FALSE) {
    stop("Dataset name is not a character string.")
  }

  # check dataset name contains .csv
  if (str_count(dataset,".csv") == 0) {
    warning("Dataset name (\'", dataset, "\' does not appear to be a csv, ",
            "import will continue.")
  }

  # load dataset
  x <- try(read_csv(dataset), silent = TRUE)
  if ((class(x)[1] == "try-error")) {
    stop("File \'", dataset,"\' not found")
  } else if (is_tibble(x) == FALSE) {
    stop("read_csv did not import correctly, please try again.")
  }

  # check dataset has columns and rows
  if ((ncol(x) == 0) | nrow(x) == 0) {
    stop("Dataset \'", dataset,"\' has no data, ", ncol(x), " columns with ",
         nrow(x), " rows,")
  }

  # convert column names to lowercase
  names(x) <- tolower(names(x))

  # check if orgcodes are included in the dataset
  # be kind and allow 'organisation'
  if (("org" %in% colnames(x)) == FALSE &
      ("organisation" %in% colnames(x)) == FALSE) {
    stop("Dataset \'", dataset,"\' does not contain a column for organisation ",
         "codes: no column named \'org\' found.")
  }

  # if 'organisation' is used then change to 'org'
  if (("organisation" %in% colnames(x)) == TRUE) {
    x <- x %>% rename(org = organisation)
    message("Column \'organisation\' renamed \'org\'.")
  }

  # check 'org' is character type
  if (is.character(x$org) == FALSE) {
    stop("Column \'org\' in dataset \'", dataset, "\' is not character data.")
  }

  # capitalise orgcodes just in case
  x$org <- toupper(x$org)

  return(x)

}


# function import headcount data, a special case of import_dataset()
# imports dataset using the main function but adds further checks:
# checks is a two-column dataset including a numeric column for headcounts
# (column named 'hc')

import_hc <- function(dataset) {

  # do the generic import checks
  x <- import_dataset(dataset)

  # check if dataset has two columns
  if (ncol(x) != 2) {
    stop("Dataset \'", dataset,"\' should only have two columns, \'org\' ",
         "and \'hc\'. Imported dataset has ", ncol(x)," column(s).")
  }

  # check  headcounts are included in the dataset
  # be kind and allow and 'headcount'
  if (("hc" %in% colnames(x)) == FALSE &
             ("org" %in% colnames(x)) == FALSE) {
    stop("Dataset \'", dataset,"\' does not contain a column for organisation ",
         "codes: no column named \'hc\' found.")
  }

  # if 'headcount' is used then change to 'hc'
  if (("headcount" %in% colnames(x)) == TRUE) {
    x <- x %>% rename(hc = headcount)
    message("Column \'headcount\' renamed \'hc\'.")
  }

  # check 'hc' is numeric type
  if (is.numeric(x$hc) == FALSE) {
    stop("Column \'hc\' in dataset \'", dataset, "\' is not numerical data.")
  }

  return(x)

}


# function to list the scores available in the scores dataset
what_scores <- function(dataset = "scores") {

  # call dataset
  dataset <- get(dataset)

  # produce message listing column names, excluding 'org'
  message("The following scores are available for charting: ")
  cat(collapse(names(select(dataset, -org)), sep = ", ", last = " and "))

}


# function builds a chartable dataset
# takes one metric, one dataset for scores, one dataset for headcounts
chartable_data <- function(metric, dataset = "scores", hcs = "headcounts") {

  # check if metric argument exists
  if (missing(metric)) {
    stop("Please provide a metric.")
  }

  # check length of arguments is one
  if (length(metric) != 1) {
    stop("Please only provide one metric.")
  } else if (length(dataset) != 1) {
    stop("Please only provide one scores dataset.")
  } else if (length(hcs) != 1) {
    stop("Please only provide headcount dataset.")
  }

  # check if datasets missing/invalid
  if (exists(dataset) == FALSE) {
    stop("Dataset \'", dataset,"\' does not exist.")
  } else if (exists(hcs) == FALSE) {
    stop("Headcount dataset \'", hcs, "\' does not exist.")
  }

  # call datasets
  x <- get(dataset)
  hcs <- get(hcs)

  # check metric exists in dataset
  if ((metric %in% colnames(x)) == FALSE) {
    stop("A column named \'", metric, "\' does not exist in the dataset \'",
         dataset,"\'.")
  }

  # subset dataset to just the score of interest
  x <- x %>% select(org, val = metric)

  # transform the dataset
  #   1. merge in headcounts
  #   2. create new values:
  #       a. calculate 'negative value' (remainder of pie)
  #       b. rank scores by 'val'
  #       c. merge ranks and organisation names (for sorting)
  #       d. create 'radius' measure of headcount
  #           (the radius if hc is area of circle)
  #   3. gather data into a long-form table suitable for charting
  #   4. convert the values into a percent format
  #   5. sort dataset by ranked organisation label and by data group

  x <- inner_join(x, hcs, by = "org") %>%
    mutate(
      negval = 1 - val,
      rank = rank(val, ties.method = "min"),
      rankorg = paste(str_pad(nrow(x) - rank,3,"left",0), org, sep = "_"),
      hc_rad = sqrt(hc/pi)
      ) %>%
    gather(key = "grp", value = "score", val, negval) %>%
    mutate(score = percent(score, 0)) %>%
    arrange(rankorg, desc(grp))

  # create labels for chart
  #   1. select just the scores of interest (i.e. the 'val' data)
  #   2. drop everything but the organisation and the score
  #   3. merge the org code and score
  #   4. convert to a factor
  x_facs <- x %>%
    filter(grp == "val") %>%
    select(org, score) %>%
    mutate(
      org_lab = paste(org,as.character(score), sep = ": "),
      org_lab = as_factor(org_lab)
    ) %>%
    select(org, org_lab)

  # merge chart labels into the main chart data
  x <- inner_join(x, x_facs, by = "org")

  return(x)

}

set_chart_colours <- function(colour = "light_blue"){

  # check if a gov_cols colour, and extract hex code
  if (colour %in% names(gov_cols)) {
    colour <- gov_cols[colour]
  }

  # create variable for the colours, and give it names corresponding to
  # chart data groups
  x <- c(colour, "gray85")
  names(x) <- c("val", "negval")

  return(x)

}

# function makes a plot

make_chart <- function(chart_data, chart_colour, orientation = "landscape") {

  # check if data argument provided
  if (missing(chart_data)) {
    stop("Please provide a chartable dataset.")
  }

  if (missing(chart_colour)) {
    # no chart colours defined, use the defaults
    chart_colours <- set_chart_colours()
  } else if (length(chart_colour) > 1) {
    warning("Using colour array provided")
    chart_colours <- chart_colour
  } else {
    chart_colours <- set_chart_colours(chart_colour)
  }

  # transformation orientation into wrap
  if (orientation == "landscape") {
    n_facets <- 15
  } else if (orientation == "portrait") {
    n_facets <- 7
  } else if (is_character(orientation)) {
    n_facets <- 15
    warning("Could not process orientation, using default facet wrap ",
            "legnth of 15")
  } else if (is.numeric(orientation) == TRUE & (orientation %% 1) == 0) {
    n_facets = orientation
  } else {
    n_facets <- 15
    warning("Could not process orientation, using default facet wrap ",
            "legnth of 15")
  }

  # create a ggplot unit
  p <- ggplot(chart_data, aes(x = log10(hc_rad)/2,
                              y = score,
                              fill = grp,
                              width = log10(hc_rad)
                              )
              ) +
    # use column chart format (simple version of geom_bar)
    geom_col(show.legend = FALSE) +
    # set manual colours
    scale_fill_manual(values = chart_colours) +
    # conver to circular plot
    coord_polar("y") +
    # split into a grid by organisation
    facet_wrap(~org_lab, ncol = n_facets) +
    # remove all the chart gubbins (axes, gridlines, backgrounds, etc)
    theme_void() +
    # move legend and change text size
    theme(
          strip.text = element_text(size = 8)
    )

  return(p)

}
