# loads data & runs a report

# Load some packages
library(gridCarbon) # load this first - you will need to download & build it locally from this repo

source("env.R")

libs <- c("data.table", # data munching
          "drake", # data gets done once (ideally)
          "here", # here. not there
          "skimr") # skimming data for fast descriptives

gridCarbon::loadLibraries(libs) # should install any that are missing

# Paramaters
localParams <- list()

# Functions

makeReport <- function(f){
  # default = html
  rmarkdown::render(input = paste0(here::here("Rmd", f),".Rmd"),
                    params = list(title = title,
                                  subtitle = subtitle,
                                  authors = authors),
                    output_file = paste0(here::here("/docs/"), 
                                         f , # keep it simple
                                         ".html")
  )
}

# > Make report ----
# >> yaml ----
version <- "1.0"
title <- paste0("Simple NZ Heat Pump Adoption Simulation")
subtitle <- paste0("Very simple... v", version)
authors <- "Ben Anderson"


# >> run report ----
rmdFile <- "simpleHeatPumpSim_NZ"

makeReport(rmdFile)


