setwd("~/GoogleDrive/1UT/2_Research/3_Switch/Test_Model/v2/R/")
load("./Latest.RData")

# This code was written to expand timescales for initial test model based on Fce Data

# Inputs that don't depend on timescales module are just imported from previous model

# Inputs that depend on timescales include:
# periods.tab
# timeseries.tab
# timepoints.tab
# loads.tab
# gen_build.tab (depends on periods.tab)
# variable_capacity_factors.tab


SaveTo = "../FCe_Model_v2/inputs/"
paste(c(SaveTo,"test.tab"), collapse = "")

#######################################################################################################
#                   Importing Data
#######################################################################################################

folder = "../../20190126_SCJ_Data/"

Z1_file <- paste(c(folder,"ERCOT\ 2018\ Hourly\ Load\ Z1NE.csv"), collapse = "")
Z1_data <- read.csv(file = Z1_file, stringsAsFactors = F, na.strings="NA",row.names=NULL, header = T, sep = ",")
Z1_data <- Z1_data[1:8760,]

Z2_file <- paste(c(folder,"ERCOT\ 2018\ Hourly\ Load\ Z2W.csv"), collapse = "")
Z2_data <- read.csv(file = Z2_file, stringsAsFactors = F, na.strings="NA",row.names=NULL, header = T, sep = ",")
Z2_data <- Z2_data[1:8760,]

Z3_file <- paste(c(folder,"ERCOT\ 2018\ Hourly\ Load\ Z3C.csv"), collapse = "")
Z3_data <- read.csv(file = Z3_file, stringsAsFactors = F, na.strings="NA",row.names=NULL, header = T, sep = ",")
Z3_data <- Z3_data[1:8760,]

Z4_file <- paste(c(folder,"ERCOT\ 2018\ Hourly\ Load\ Z4S.csv"), collapse = "")
Z4_data <- read.csv(file = Z4_file, stringsAsFactors = F, na.strings="NA",row.names=NULL, header = T, sep = ",")
Z4_data <- Z4_data[1:8760,]



#######################################################################################################
#                   Creating inputs for switch_model.timescales
#######################################################################################################


# periods.tab ----------------------------------------------------------------------------------------- 
old_periods <- periods

periods$INVESTMENT_PERIOD <- 2018
periods$period_start <- 2018
periods$period_end <- 2018
write.table(periods, paste(c(SaveTo,"periods.tab"), collapse = ""), sep="\t",row.names = F, quote = F)



# timeseries.tab ---------------------------------------------------------------------------------------
# Let 1 time series equal 1 year => 8784 tps per series and 1 series per period
# Blocks of consecutive timepoints within a period.
old_ts <- t_series

t_series$ts_period = 2018
t_series$ts_num_tps = dim(Z1_data)[1]  # number of timepoints in a series
t_series$ts_duration_of_tp = 1 # duration, in hours, of each timepoint within a timeseries
t_series$ts_scale_to_period = 1 # number of timeseries per period
t_series$TIMESERIES <- '2018_all'

# write.table(t_series, paste(c(SaveTo,"timeseries.tab"), collapse = ""), sep="\t",row.names = F, quote = F)


# timepoints.tab ---------------------------------------------------------------------------------------
old_tps <- t_points # this is the original 

years = 2018
months = as.character(c("01","02","03","04","05","06","07","08","09",10,11,12))
days_max = as.character(c("01","02","03","04","05","06","07","08","09",10:31))
num_days = c(31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
# num_days = c(1:31, 1:28, 1:31, 1:30, 1:31, 1:30, 1:31, 1:31, 1:30, 1:31, 1:30, 1:31)
hours = as.character(c("00","01","02","03","04","05","06","07","08","09",10:23))

number_tps = dim(Z1_data)[1]*dim(t_series)[1]
  
t_points <- as.data.frame(old_tps[1:number_tps,], row.names = 1:number_tps) # redefine new dataframe of with correct size
t_points$timepoint_id <- 1:number_tps
levels(t_points$timeseries) <- t_series$TIMESERIES # have to redefine levels to put new timeseries
t_points$timeseries <- t_series$TIMESERIES[1]

count = 0
for(m in 1:12){
  for(d in 1:num_days[m]){
    for(h in 1:length(hours)){
      count = count + 1
      t_points$timestamp[count] <- paste(c(years[y],as.character(months[m]),as.character(days_max[d]),as.character(hours[h])), collapse = "")
    }
  }
}


# write.table(t_points, paste(c(SaveTo,"timepoints.tab"), collapse = ""), sep="\t",row.names = F, quote = F)



########################################################################################################
#                       Creating inputs for switch_model.generators.core.build
########################################################################################################

# This is only included because load zones may need to be changed
# See changed below under 'load_zones.tab'
# Export .tab
# write.table(fce_gen_info, paste(c(SaveTo,"generation_projects_info.tab"), collapse = ""), sep="\t",row.names = F, quote = F)



#######################################################################################################
#                   Creating inputs for switch_model.balancing.load_zones
#######################################################################################################


# load_zones.tab --------------------------------------------------------------------------------------

# Importing Sam's PLEXOS Data
# Zones are derived from zones depicted on: http://www.ercot.com/about/weather
PLEXOS_zone_data <- cbind.data.frame(Z1_data, Z2_data[5], Z3_data[5], Z4_data[5])
PLEXOS_zones <- c("Northeast","West","Coastal","South")
names(PLEXOS_zone_data)[5:8] <- PLEXOS_zones
archive_zones <- fce_load_zones[ !(fce_load_zones$LOAD_ZONE  %in%  PLEXOS_zones) ,] # AEN, North, Houston, CPS, LCRA, RCEC
archive_gen_zones <- fce_gen_info[ fce_gen_info$gen_load_zone %in% archive_zones , c(1,3) ] # Saving original FCe zone designations


# Re-designating zones to match sam's PLEXOS Data
old_load_zones <- fce_load_zones  # saving old zones
fce_load_zones$LOAD_ZONE <- PLEXOS_zones
fce_load_zones <- as.data.frame(fce_load_zones[1:4,])
names(fce_load_zones) <- names(old_load_zones)


# editing gen info 
old_gen_info <- fce_gen_info
fce_gen_info$gen_load_zone[ fce_gen_info$gen_load_zone == "AEN"] <- "South" # (16 gens) Austin Energy North
fce_gen_info$gen_load_zone[ fce_gen_info$gen_load_zone == "North"] <- "Northeast" 
fce_gen_info$gen_load_zone[ fce_gen_info$gen_load_zone == "Houston"] <- "Coastal"
fce_gen_info$gen_load_zone[ fce_gen_info$gen_load_zone == "CPS"] <- "South" # (5 gens) CPS Energy load zone (San Antonio area)
fce_gen_info$gen_load_zone[ fce_gen_info$gen_load_zone == "LCRA"] <- "South" # (17 gens) Lower Colorado River Authority load zone 
fce_gen_info$gen_load_zone[ fce_gen_info$gen_load_zone == "RCEC"] <- "Northeast" # (1 gen - Hydro_RCEC_LZ) Rayburn Country Electric Cooperative load zone


# Export .tab
# write.table(fce_load_zones, paste(c(SaveTo,"load_zones.tab"), collapse = ""), sep="\t",row.names = F, quote = F)
# write.table(fce_gen_info, paste(c(SaveTo,"generation_projects_info.tab"), collapse = ""), sep="\t",row.names = F, quote = F)







# loads.tab -------------------------------------------------------------------------------------------
load_rows = dim(fce_load_zones)[1]*dim(t_points)[1]
old_fce_loads <- fce_loads
fce_loads <- old_fce_loads[1:load_rows,1:length(old_fce_loads)] # Copy data frame to get the right size set up.
# loop through zones and tps to create loads
row_count = 0
for(k in 1:dim(fce_load_zones)[1]){ # loop through load zones
  for(j in 1:dim(t_points)[1]){ # loop through timepoints
    row_count = row_count+1
    fce_loads$LOAD_ZONE[row_count] <- as.character(fce_load_zones$LOAD_ZONE[k])
    fce_loads$TIMEPOINT[row_count] <- t_points$timepoint_id[j]
    fce_loads$zone_demand_mw[row_count] <- PLEXOS_zone_data[j,k+4]
  }
}
# Export .tab
# write.table(fce_loads, paste(c(SaveTo,"loads.tab"), collapse = ""), sep="\t",row.names = F, quote = F)




########################################################################################################
#                       Creating inputs for switch_model.generators.core.dispatch
########################################################################################################


# variable_capacity_factors.tab ------------------------------------------------------------------------
var_cfs <- read.delim(file = "/Users/trins/switch/examples/3zone_toy/inputs/variable_capacity_factors.tab", header = T, sep = "\t")

fce_var_gens <- fce_gen_info$GENERATION_PROJECT[fce_gen_info$gen_is_variable==1] # isolate list of variable generators
cf_rows <- length(fce_var_gens)*dim(t_points)[1]
fce_cfs <- fce_data[1:cf_rows,1:length(var_cfs)] # Copy data frame to get the right size set up.
names(fce_cfs) <- names(var_cfs)
fce_cfs_gens_only <- rep(fce_var_gens, each = dim(t_points)[1]) # make list of generator names, each repeated 8760 times
fce_cfs$GENERATION_PROJECT <- fce_cfs_gens_only
fce_cfs$gen_max_capacity_factor <- 0.50 # setting all cap at 1 for now
fce_cfs$timepoint <- as.integer( rep(1:dim(t_points)[1], length(fce_var_gens)) )

# rename columns and rows
names(fce_cfs) <- names(var_cfs)
row.names(fce_cfs) <- 1:dim(fce_cfs)[1]

# Export .tab
write.table(fce_cfs, paste(c(SaveTo,"variable_capacity_factors.tab"), collapse = ""), sep="\t",row.names = F, quote = F)


