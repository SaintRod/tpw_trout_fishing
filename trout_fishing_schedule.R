library(reshape)
library(geocodeHERE)
library(httr)
library(jsonlite)

###############################################################################################
###############################################################################################
###############################################################################################
###############################################################################################
##global vairables

file_path <- "/home/sr/Desktop/trout_sched"
file_name <- "tfw_2019_2020_trout_sched.csv"
file <- paste(file_path,file_name,sep="/")

setwd("/home/sr/Desktop")

App_id <- "MuKtwsLOKBzU8PF3yYGX"
App_code <- "ksQlCbV-Yg3WE9N696N4sQ"

###############################################################################################
###############################################################################################
###############################################################################################
###############################################################################################
##udf

distance_time_function <- function(orig_lat, orig_lon, dest_lat, dest_lon){
  
  url <- "https://route.api.here.com/routing/7.2/calculateroute.json"
  id <- paste("app_id=", App_id, sep="")
  
  pwd <- paste("app_code=", App_code, sep="")
  orig <- paste("waypoint0=geo!", paste(as.character(orig_lat) ,as.character(orig_lon), sep=","), sep="")
  dest <- paste("waypoint1=geo!", paste(as.character(dest_lat) ,as.character(dest_lon), sep=","), sep="")
  mode <- "mode=fastest;car;traffic:disabled"
  
  api_string <- paste(url, id, sep="?")
  api_string <- paste(api_string, pwd, orig, dest, mode, sep="&")
  
  foo <- fromJSON(api_string)
  
  #distance in miles
  distance <- round(foo$response$route$summary$distance*0.0006213712,0)
  
  #time in hours
  time <- round(foo$response$route$summary$baseTime/(60*60),2)
  
  return(list(dist=distance, time=time))
}

###############################################################################################
###############################################################################################
###############################################################################################
###############################################################################################
##data import

data <- read.csv(file=file, header=TRUE,sep=",", na.strings = "")
data.fm <- data.frame(data)
names(data.fm) <- tolower(names(data.fm))

###############################################################################################
###############################################################################################
###############################################################################################
###############################################################################################
##data manipulations

###transforming data
data.fm.narrow <- melt(data.fm, id=names(data.fm)[c(1,2,3)])
data.fm.narrow <- data.fm.narrow[order(data.fm.narrow$stocking.location, data.fm.narrow$variable),]
data.fm.narrow <- data.fm.narrow[!is.na(data.fm.narrow$value),]
names(data.fm.narrow) <- c("stocking.location", "city","total","stocking date num","stocking date")

###create orig geocode
orig_address <- #enter address as a string
data.fm.narrow$orig <- orig_address

orig_geocode <- geocodeHERE_simple(orig_address, App_id=App_id, App_code = App_code)
data.fm.narrow$orig_lat <- orig_geocode[[1]]
data.fm.narrow$orig_lon <- orig_geocode[[2]]

###create dest geocodes
####create search string for here api
data.fm.narrow$state <- "TX"
data.fm.narrow$search <- apply(data.fm.narrow[,c("stocking.location","city","state")], 1, paste, collapse=", ")

####create dest geocode dummy vectors
places <- unique(data.fm.narrow$search)
search_lat <- rep(0,length(places))
search_lon <- rep(0,length(places))
dist_vector <- rep(0,length(places))
drive_time <- rep(0,length(places))

for(i in 1:length(places)){
  #create dest geocode
  x <- geocodeHERE_simple(places[i], App_id=App_id, App_code = App_code)
  search_lat[i] <- as.character(x[[1]])
  search_lon[i] <- as.character(unlist(x[2]))
  
  #  #create drive distance and time variables  
  ugh <- distance_time_function(
    orig_geocode[[1]],
    orig_geocode[[2]],
    ifelse(is.na(search_lat[i]),orig_geocode[[1]],search_lat[i]),
    ifelse(is.na(search_lon[i]),orig_geocode[[2]],search_lon[i])
  )
  
  dist_vector[i] <- if(ugh$dist == 0){0}else{as.numeric(as.character(ugh$dist))}
  drive_time[i] <- if(ugh$time == 0){0}else{as.numeric(as.character(ugh$time))}
}

places.df <- cbind(places, search_lat, search_lon)
places.df <- data.frame(places.df, cbind(dist_vector, drive_time))
names(places.df) <- c("search", "dest_lat", "dest_lon", "distance (mi)", "drive time (hrs)")

###create merged dataset
data.fm.narrow.merged <- merge(data.fm.narrow, places.df, by="search", all=TRUE)

###############################################################################################
###############################################################################################
###############################################################################################
###############################################################################################
##create output summary of most likely locations/dates

summary <- data.fm.narrow.merged[
  !is.na(data.fm.narrow.merged$dest_lat)
  & data.fm.narrow.merged$`distance (mi)` <= 50
  & data.fm.narrow.merged$`distance (mi)` > 0
  & as.Date(data.fm.narrow.merged$`stocking date`, format="%m/%d/%y") >= Sys.Date()
  ,c("search","total","stocking date num","stocking date","distance (mi)","drive time (hrs)")]

summary$DOW <- weekdays(as.Date(summary$`stocking date`, format="%m/%d/%y"))
summary$DOWnum <- format(as.Date(summary$`stocking date`, format="%m/%d/%y"), "%w")

summary <- summary[order(as.Date(summary$`stocking date`, format="%m/%d/%y"),summary$`distance (mi)`,summary$`stocking date num`),]

barplot(
  table(summary$DOWnum)
  ,ylim=c(0,round(max(table(summary$DOW)),-1))
  ,names.arg = c("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat")
  ,main="Day of the Week with Most Stockings"
  ,ylab="Frequency/ Count"
  ,xlab="Day of Week"
  ,col="darkblue"
)

summary

###############################################################################################
###############################################################################################
###############################################################################################
###############################################################################################

###############################################################################################
###############################################################################################
###############################################################################################
###############################################################################################

###############################################################################################
###############################################################################################
###############################################################################################
###############################################################################################

###############################################################################################
###############################################################################################
###############################################################################################
###############################################################################################

write.csv(data.fm.narrow.merged, file=paste(file_path,"cleaned_up_trout_schedule.csv",sep="/"), row.names = FALSE)

write.csv(summary, file=paste(file_path,"trout_within_50miles.csv",sep="/"), row.names = FALSE)
