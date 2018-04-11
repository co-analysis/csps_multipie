#CSPS MutliPie User File

# load the libraries and functions, will cause errors if you don't have
# necessary packages installed (tidyverse, govstyle)
source("csps_multiPie.R")
load_pkgs()

# load headcount data
headcounts <- import_hc("csps_hc.csv")

# load some scores
scores <- import_dataset("csps_vision-scores.csv")

# what_scores() lets you see what scores are available in the scores dataset
# use this if you want to quickly see columns without looking at the dataset.
# assumes that your dataset is called 'scores' if you've called your data
# something else make sure to use that as the argument e.g what_scores("data")
what_scores()

# chartable_data() creates a dataset that you can pass to the  make_chart().
# it assumes that the scores are in a dataset called  'scores' and headcounts
# are in a dataset called 'headcounts', if different pass as arguments:
#   chartable_data("b61", dataset = "csps_data", hcs = "csps_hcs")
my_chart_data <- chartable_data("b61")

# make_chart() uses a chartable_data output to produce a grid of piecharts
# the default colour is light blue and assumes landscape orientation, you can
# change these using argument: make_chart(chart_data, chart_colour, orientation)
# chart_colours can be a colour defined in the govstyle package [use checkpal()
# to see what names you can use], an R named colour, or a hexadecimal colour

# chart using defaults
make_chart(my_chart_data)

# check_pal() from govstyle pkg shows the different colours in the UK GovDataScience
# standard colour palette
check_pal()

# chart using pink
make_chart(my_chart_data, "pink")

# you don't actually have to create the data as an object, just call
# chartable_data within the call to make_chart
make_chart(chartable_data("b62"), "yellow")
