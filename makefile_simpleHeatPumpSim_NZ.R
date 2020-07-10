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
localParams$fromYear <- 2017
localParams$toYear <- 2017 # we only want 2017
update <- "yes"
# > data paths ----
gridDataPath <- paste0(repoParams$nzGridDataLoc, 
                       "processed/yearly/")

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

loadGridData <- function(path, fromYear, toYear, update){
  # lists files within a folder (path) & loads
  # edit fromYear to force a new data load
  # path <- gridDataPath
  # fromYear <- localParams$fromYear
  # toYear <- localParams$toYear
  message("Loading from: ", path)
  message("Loading files >= ", fromYear, " and <= ", toYear )
  filesToDateDT <- data.table::as.data.table(list.files(path, ".csv.gz")) # get list of files already downloaded & converted to long form
  filesToDateDT[, file := V1]
  filesToDateDT[, c("year", "name") := tstrsplit(file, split = "_")]
  filesToDateDT[, year := as.numeric(year)]
  filesToGet <- filesToDateDT[year >= fromYear & year <= toYear, # to reduce files loaded
                              file]
  
  l <- lapply(paste0(path, filesToGet), # construct path for each file
              data.table::fread) # mega fast read
  dt <- rbindlist(l, fill = TRUE) # rbind them
  l <- NULL
  # dt <- do.call(rbind,
  #               lapply(filesToGet, # a list
  #                      function(f)
  #                        data.table::fread(paste0(path,f))
  #               ) # decodes .gz on the fly
  # )
  # > fix grid data ----
  dt[, rDateTimeOrig := rDateTime] # just in case
  dt[, rDateTime := lubridate::as_datetime(rDateTime)]
  dt[, rDateTimeNZT := lubridate::force_tz(rDateTime, 
                                                   tzone = "Pacific/Auckland")] # just to be sure
  dt[, rTime := hms::as_hms(rDateTimeNZT)]
  dt[, rMonth := lubridate::month(rDateTimeNZT, label = TRUE, abbr = TRUE)]
  dt[, rDate := lubridate::date(rDateTimeNZT)]
  dt <- gridCarbon::addSeason(dt, 
                              h = "S", 
                              dateVar =  "rDate")
  # check
  print("Grid gen loaded")
  message("Loaded ", tidyNum(nrow(dt)), " rows of data")
  table(dt[is.na(rDateTimeNZT)]$Time_Period)
  nrow(dt)
  allGridDT <- dt[!is.na(rDateTimeNZT)] # removes TP 49 & 50
  allGridDT <- allGridDT[!is.na(kWh)] # removes NA kWh
  message("After cleaning: ", tidyNum(nrow(allGridDT)), " rows of data")
  #summary(allGridDT$rDateTimeNZT)
  return(allGridDT) # large
}

loadHeatPumpData <- function(f){
  dt <- data.table::fread(f)
  dt[, r_dateTimeLubridated := lubridate::as_datetime(r_dateTime)]
  dt[, rDateTimeNZT := lubridate::with_tz(r_dateTimeLubridated, tzone = "Pacific/Auckland")]
  
  dt[, obsDate := as.Date(rDateTimeNZT)]
  dt <- gridCarbon::addSeason(dt, h = "S", dateVar = "obsDate")
  dt[, year := lubridate::year(rDateTimeNZT)]
  dt[, hms:= hms::as_hms(rDateTimeNZT)]
  dt[, halfHour:= hms::trunc_hms(hms, 30*60)]
  return(dt)
}

# 
#gridData <- loadGenData(localParams$gridDataLoc, # from where?
#                        localParams$fromYear) # from what date?

# drake plan ----
plan <- drake::drake_plan(
  gridGenData = loadGridData(gridDataPath, # from where?
                         localParams$fromYear,  # from what date?
                         localParams$toYear, 
                         update),
  heatPumpData =   loadHeatPumpData(paste0(repoParams$GreenGridData, 
                                           "1min/dataExtracts/Heat Pump_2015-04-01_2016-03-31_observations.csv.gz")
                                    )

)
# 
# path <- localParams$gridDataLoc
# fromYear <- localParams$fromYear
# dt <- loadGenData(path, # from where?
#                   fromYear)

# > run drake plan ----
plan # test the plan
make(plan) # run the plan, re-loading data if needed


# code ----


# > Make report ----
# >> yaml ----
version <- "1.0"
title <- paste0("Simple NZ Heat Pump Adoption Simulation")
subtitle <- paste0("Very simple... v", version)
authors <- "Ben Anderson"


# >> run report ----
rmdFile <- "simpleHeatPumpSim_NZ"

makeReport(rmdFile)


