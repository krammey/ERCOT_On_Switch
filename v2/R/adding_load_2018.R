setwd("~/GoogleDrive/1UT/0_Research/3_Switch/Test_Model/v2/R/")
load("./20190225_87600tps.RData")

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
num_days = c(31,28,31,30,31,30,31,31,30,31,30,31)
hours = as.character(c("00","01","02","03","04","05","06","07","08","09",10:23))

number_tps = dim(Z1_data)[1]*dim(t_series)[1]
  
new_tps <- as.data.frame(t_points[1:number_tps,], row.names = 1:number_tps) # redefine new dataframe of with correct size
new_tps$timepoint_id <- 1:number_tps

levels(new_tps$timeseries) <- t_series$TIMESERIES

count = 0
for(y in 1:length(t_series$TIMESERIES)){
  for(m in 1:12){
    for(d in 1:num_days[m]){
      for(h in 1:length(hours)){
        count = count + 1
        new_tps$timeseries[count] <- t_series$TIMESERIES[y]
        new_tps$timestamp[count] <- paste(c(years[y],as.character(months[m]),as.character(days_max[d]),as.character(hours[h])), collapse = "")
      }
      print(count)
    }
  }
  
}
# write.table(new_tps, paste(c(SaveTo,"timepoints.tab"), collapse = ""), sep="\t",row.names = F, quote = F)



########################################################################################################
#                       Creating inputs for switch_model.generators.core.build
########################################################################################################

# This is only included because load zones may need to be changed
# generation_projects_info.tab -------------------------------------------------------------------------
fce_gen_info$gen_load_zone <- fce_data$Load.Zone

# Export .tab
write.table(fce_gen_info, paste(c(SaveTo,"generation_projects_info.tab"), collapse = ""), sep="\t",row.names = F, quote = F)



#######################################################################################################
#                   Creating inputs for switch_model.balancing.load_zones
#######################################################################################################


# load_zones.tab --------------------------------------------------------------------------------------
# Note this is left here since it may need to be changed to match data provided

# Export .tab
write.table(fce_load_zones2, paste(c(SaveTo,"load_zones.tab"), collapse = ""), sep="\t",row.names = F, quote = F)


# loads.tab -------------------------------------------------------------------------------------------
loads <- read.delim(file = "/Users/trins/switch/examples/3zone_toy/inputs/loads.tab", header = T, sep = "\t")
load_rows = dim(fce_load_zones)[1]*dim(t_points)[1]
fce_loads <- fce_data[1:load_rows,1:length(loads)] # Copy data frame to get the right size set up.
names(fce_loads) <- names(loads)
# sum generator capacities over loadzones to get totalled capacity per zone
gen_zones <- fce_gen_info[c(1,3)] # get GENERATION_PROJECT and gen_load_zone columns
gen_caps <- fce_predetermined[c(1,3)] # get GENERATION_PROJECT and gen_predetermined_cap columns
gen_zone_caps <- merge(gen_zones, gen_caps, by = "GENERATION_PROJECT") # merge the two dataframes to get GENERATION_PROJECT, gen_load_zone, gen_predetermined_cap
zone_caps <- gen_zone_caps[c(2,3)] # delete GENERATION_PROJECT column
zone_caps2 <- aggregate(as.numeric(zone_caps$gen_predetermined_cap), FUN = sum, by = list(zone_caps$gen_load_zone))
names(zone_caps2) <- c("LOAD_ZONE","zone_capacity")
zone_caps3 <- zone_caps2[order(match(zone_caps2$LOAD_ZONE,fce_load_zones$LOAD_ZONE)),]
# loop through zones and tps to create loads
row_count = 0
for(k in 1:dim(fce_load_zones)[1]){ # loop through load zones
  for(j in 1:dim(t_points)[1]){ # loop through timepoints
    row_count = row_count+1
    fce_loads$LOAD_ZONE[row_count] <- fce_load_zones[k,1]
    fce_loads$TIMEPOINT[row_count] <- t_points[j,1]
    fce_loads$zone_demand_mw[row_count] <- (0.5/j)*zone_caps3$zone_capacity[k] # each zone is at half capacity in first timepoint and decreases 50% each subesequent timepoint
  }
}
# Export .tab
# write.table(fce_loads, paste(c(SaveTo,"loads.tab"), collapse = ""), sep="\t",row.names = F, quote = F)




########################################################################################################
#                       Creating inputs for switch_model.generators.core.dispatch
########################################################################################################


# variable_capacity_factors.tab ------------------------------------------------------------------------
fce_var_gens <- fce_gen_info$GENERATION_PROJECT[fce_gen_info$gen_is_variable==1] # isolate list of variable generators
cf_rows <- length(fce_var_gens)*dim(t_points)[1]
fce_cfs <- fce_data[1:cf_rows,1:length(var_cfs)] # Copy data frame to get the right size set up.
names(fce_cfs) <- names(var_cfs)
# loop through GENERATION_PROJECT and tps to create cfs
row_count = 0
for(k in 1:length(fce_var_gens)){ # loop through variable generators
  for(j in 1:dim(t_points)[1]){ # loop through timepoints
    row_count = row_count+1
    fce_cfs$GENERATION_PROJECT[row_count] <- as.character.factor(fce_var_gens[k])
    fce_cfs$timepoint[row_count] <- t_points[j,1]
    fce_cfs$gen_max_capacity_factor[row_count] <- 0.50 # setting all cap at 1 for now
  }
}
fce_cfs$timepoint <- as.integer(fce_cfs$timepoint)

# Export .tab
# write.table(fce_cfs, paste(c(SaveTo,"variable_capacity_factors.tab"), collapse = ""), sep="\t",row.names = F, quote = F)





