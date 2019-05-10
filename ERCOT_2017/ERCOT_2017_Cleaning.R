

# Author: Katrina Ramirez-Meyers
# Version control information available on Github
# This code was written to import 2017 powerplant and load data into 12* hourly models
# *one for each month


# Define useful paths
AnnualModel2015 = "../Fce_R_Development/v5/FCe_Model/inputs/"
# ERCOT2017_file = "../../2017_Master_Gen_Fleet.csv"
ERCOT2017_file = "../2017_ERCOT_for_Switch.csv"


# Import Data ----------------------------------
# ERCOT power plants (extracted from SCJ database + some cleaning recorded on Github)
ercot_data <- read.csv(file = ERCOT2017_file, stringsAsFactors = F, na.strings="NA",row.names=NULL, header = T, sep = ",")
names(ercot_data) <- c('Name','Fuel','Tech','Zone','Build.Year','Max.Cap.MW','PLEXOS.AHRs..MMBtu.MWh.', 'CO2.lb.MMBtu')

# Import load data (from Sam Johnson)
folder = ("../../2017 ERCOT Load/")
tp <- 8760

Z1_file <- paste(c(folder,"ERCOT\ 2017\ Hourly\ Load\ Z1NE.csv"), collapse = "")
Z1_data <- read.csv(file = Z1_file, stringsAsFactors = F, na.strings="NA",row.names=NULL, header = T, sep = ",")
Z1_data <- Z1_data[1:tp,]

Z2_file <- paste(c(folder,"ERCOT\ 2017\ Hourly\ Load\ Z2W.csv"), collapse = "")
Z2_data <- read.csv(file = Z2_file, stringsAsFactors = F, na.strings="NA",row.names=NULL, header = T, sep = ",")
Z2_data <- Z2_data[1:tp,]

Z3_file <- paste(c(folder,"ERCOT\ 2017\ Hourly\ Load\ Z3C.csv"), collapse = "")
Z3_data <- read.csv(file = Z3_file, stringsAsFactors = F, na.strings="NA",row.names=NULL, header = T, sep = ",")
Z3_data <- Z3_data[1:tp,]

Z4_file <- paste(c(folder,"ERCOT\ 2017\ Hourly\ Load\ Z4S.csv"), collapse = "")
Z4_data <- read.csv(file = Z4_file, stringsAsFactors = F, na.strings="NA",row.names=NULL, header = T, sep = ",")
Z4_data <- Z4_data[1:tp,]

PLEXOS_zone_data <- cbind.data.frame(Z1_data, Z2_data[5], Z3_data[5], Z4_data[5])
PLEXOS_zone_data$Panhandle <- 0

###############
SaveTo <- "./2017_01/inputs/" # Save to January model for now


############################ These reference FCe data in '../Fce_R_Development/20190405_Fce-To-SWITCH.R/

# generation_projects_info.tab --------------------------------------------
# FCeGenInfoTab = paste(c(AnnualModel2015,"generation_projects_info.tab"), collapse = "")
# fce_gen_info <- read.delim(file = FCeGenInfoTab, header = T, sep = "\t")
View(rbind.data.frame(lapply(fce_gen_info, class),lapply(ercot_gen_info, class)))
ercot_gen_info <- data.frame(matrix(ncol = 10, nrow = dim(ercot_data)[1]))
colnames(ercot_gen_info) <- c("GENERATION_PROJECT","gen_tech","gen_load_zone","gen_connect_cost_per_mw","gen_variable_om","gen_max_age","gen_is_variable","gen_is_baseload","gen_energy_source","gen_full_load_heat_rate")


ercot_gen_info$GENERATION_PROJECT <- as.factor(gsub(' ','_',ercot_data$Name)) #Replace spaces with underscores
ercot_gen_info$gen_tech <- as.factor(gsub(' ','_',ercot_data$Tech))
ercot_gen_info$gen_load_zone <- as.factor(ercot_data$Zone)
# For now, I'm setting empty 'Zone' entries to Panhandle
ercot_gen_info$gen_load_zone[is.na(ercot_gen_info$gen_load_zone)] <- "Panhandle"

ercot_gen_info$gen_connect_cost_per_mw <- as.integer(0)
ercot_gen_info$gen_variable_om <- ercot_data$VOM.MWh # Need to make sure the units are right
ercot_gen_info$gen_max_age <- as.integer(100)
ercot_gen_info$gen_is_variable <- as.integer(0) # need to add consolidated renewables back in
ercot_gen_info$gen_is_baseload <- as.integer(0)
ercot_gen_info$gen_energy_source <- as.factor(ercot_data$Fuel) # where are the non-fuels in the ERCOT data?
ercot_gen_info$gen_full_load_heat_rate <- as.factor(ercot_data$PLEXOS.AHRs..MMBtu.MWh.)

write.table(ercot_gen_info, paste(c(SaveTo,"generation_projects_info.tab"), collapse = ""), sep="\t",row.names = F, quote = F)




# gen_build_predetermined.tab ---------------------------------------------
# FCePredetTab = paste(c(AnnualModel2015,"gen_build_predetermined.tab"), collapse = "")
# fce_predet <- read.delim(file = FCePredetTab, header = T, sep = "\t")
View(rbind.data.frame(lapply(fce_predet, class),lapply(ercot_predet, class)))
ercot_predet <- data.frame(matrix(ncol = 3, nrow = dim(ercot_data)[1]))
colnames(ercot_predet) <- c("GENERATION_PROJECT","build_year","gen_predetermined_cap")

# ercot_predet <- fce_predet[1:dim(ercot_data)[1],] 
ercot_predet$GENERATION_PROJECT <- ercot_gen_info$GENERATION_PROJECT
ercot_predet$build_year <- as.integer(ercot_data$Build.Year)
ercot_predet$gen_predetermined_cap <- ercot_data$Max.Cap.MW
write.table(ercot_predet, paste(c(SaveTo,"gen_build_predetermined.tab"), collapse = ""), sep="\t",row.names = F, quote = F)




# gen_build_costs.tab -----------------------------------------------------
FCeBuildTab = paste(c(AnnualModel2015,"gen_build_costs.tab"), collapse = "")
fce_build <- read.delim(file = FCeBuildTab, header = T, sep = "\t")


ercot_build <- fce_build[1:dim(ercot_data)[1],]
ercot_build$GENERATION_PROJECT <- ercot_gen_info$GENERATION_PROJECT
ercot_build$build_year <- ercot_data$Build.Year
ercot_build$gen_overnight_cost <- 100 # test value
ercot_build$gen_fixed_om <- 0 # test value. Actual values are in SCJ database
write.table(ercot_build, paste(c(SaveTo,"gen_build_costs.tab"), collapse = ""), sep="\t",row.names = F, quote = F)


############################ These reference generation_projects_info

# load_zones.tab ----------------------------------------------------------***
# ercot_zones <- as.data.frame(unique(ercot_gen_info$gen_load_zone))
ercot_zones <- data.frame(matrix(ncol = 1, nrow = 5))
colnames(ercot_zones) <- "LOAD_ZONE"
ercot_zones$LOAD_ZONE <- c("Northeast", "South", "Coast", "West", "Panhandle") 

write.table(ercot_zones, paste(c(SaveTo,"load_zones.tab"), collapse = ""), sep="\t",row.names = F, quote = F)




# fuels.tab ---------------------------------------------------------------***
FCeFuelsTab = paste(c(AnnualModel2015,"fuels.tab"), collapse = "")
fce_fuels <- read.delim(file = FCeFuelsTab, header = T, sep = "\t")

ercot_fuels <- fce_fuels[1:length(unique(ercot_gen_info$gen_energy_source))[1],]
row.names(ercot_fuels) <- 1:dim(ercot_fuels)[1]
ercot_fuels$fuel <- unique(ercot_gen_info$gen_energy_source)
for(i in 1:dim(ercot_fuels)[1]){
  ercot_fuels$co2_intensity[i] <- mean(ercot_data$CO2.lb.MMBtu[ercot_data$Fuel == ercot_fuels$fuel[i]])/2204.62
  ercot_fuels$upstream_co2_intensity[i] <- ercot_fuels$co2_intensity[i]/10 # this is just an estimate base on trend in fce data
}
write.table(ercot_fuels, paste(c(SaveTo,"fuels.tab"), collapse = ""), sep="\t",row.names = F, quote = F)
# file.copy(AnnualFuels, SaveTo)




# periods.tab -------------------------------------------------------------UNCHANGED
AnnualPeriods = paste(c(AnnualModel2015,"periods.tab"), collapse = "")
periods <- data.frame(matrix(ncol = 3, nrow = 1))
names(periods) <- c("INVESTMENT_PERIOD","period_start","period_end")
periods[1,] <- 2017
write.table(periods, paste(c(SaveTo,"periods.tab"), collapse = ""), sep="\t",row.names = F, quote = F)





# Define useful time arrays
num_days = c(31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
hours = as.character(c("00","01","02","03","04","05","06","07","08","09",10:23))
years = 2017
months = as.character(c("01"))#,"02","03","04","05","06","07","08","09",10,11,12)) # to expand the for-loops to do all twelve months, remove ))#
days_max = as.character(c("01","02","03","04","05","06","07","08","09",10:31))




for(m in 1:length(months)){
  
  
  
  # create directories for each month
  SaveTo <- paste(c("./2017_",months[m],"/inputs/"), collapse = "")
  # dir.create(paste(c("2017_",months[m]), collapse = ""))
  # dir.create(SaveTo)############################ Already ran this. Doing it again will output an error
  
  
  
  # Copy the .tabs generated for January model above
  # write.table(ercot_gen_info, paste(c(SaveTo,"generation_projects_info.tab"), collapse = ""), sep="\t",row.names = F, quote = F)
  # write.table(ercot_predet, paste(c(SaveTo,"gen_build_predetermined.tab"), collapse = ""), sep="\t",row.names = F, quote = F)
  # write.table(ercot_build, paste(c(SaveTo,"gen_build_costs.tab"), collapse = ""), sep="\t",row.names = F, quote = F)
  # write.table(ercot_zones, paste(c(SaveTo,"load_zones.tab"), collapse = ""), sep="\t",row.names = F, quote = F)
  # write.table(ercot_fuels, paste(c(SaveTo,"fuels.tab"), collapse = ""), sep="\t",row.names = F, quote = F)
  # write.table(periods, paste(c(SaveTo,"periods.tab"), collapse = ""), sep="\t",row.names = F, quote = F)
  
  
  ############################ NEED TO CONFIRM if these remain unchanged
  # modules.txt ----------------------------------------------------------UNCHANGED
  modules = paste(c(AnnualModel2015,"modules.txt"), collapse = "")
  file.copy(modules, SaveTo)
  
  # switch_inputs_version.txt ----------------------------------------------------------UNCHANGED
  version = paste(c(AnnualModel2015,"switch_inputs_version.txt"), collapse = "")
  file.copy(version, SaveTo)
  
  # financials.dat ----------------------------------------------------------UNCHANGED
  AnnualFinancials = paste(c(AnnualModel2015,"financials.dat"), collapse = "")
  file.copy(AnnualFinancials, SaveTo)
  
  
  # non_fuel_energy_sources.tab ---------------------------------------------UNCHANGED
  AnnualNonFuels = paste(c(AnnualModel2015,"non_fuel_energy_sources.tab"), collapse = "")
  file.copy(AnnualNonFuels, SaveTo)
  
  
  
  
  # timeseries.tab ---------------------------------------------------------- 
  AnnualTimeseries = paste(c(AnnualModel2015,"timeseries.tab"), collapse = "")
  t_series <- read.delim(file = AnnualTimeseries, header = T, sep = "\t")
  # Unchanged columns in this .tab are:
  # ts_duration_of_tp = 1     duration, in hours, of each timepoint within a timeseries
  t_series$TIMESERIES <- paste(c("2017_",months[m]), collapse = "")
  t_series$ts_period <- 2017
  t_series$ts_num_tps <- 24*num_days[m] # number of timepoints in a series
  t_series$ts_scale_to_period <- 8766/(24*num_days[m])
  write.table(t_series, paste(c(SaveTo,"timeseries.tab"), collapse = ""), sep="\t",row.names = F, quote = F)
  
  
  
  # timepoints.tab ---------------------------------------------------------- 
  t_points <- data.frame(matrix(ncol = 3, nrow = num_days[m]*length(hours)))
  colnames(t_points) <- c("timepoint_id","timestamp","timeseries")
  t_points$timeseries <- t_series$TIMESERIES
  tp_start <- 24*sum(num_days[1:m-1]) + 1 # skip all previous months
  tp_end <- tp_start + 24*num_days[m] - 1
  t_points$timepoint_id <- tp_start:tp_end
  count = 0
  for(d in 1:num_days[m]){
    for(h in 1:length(hours)){
      count = count + 1
      t_points$timestamp[count] <- paste(c(2017, as.character(months[m]), as.character(days_max[d]), as.character(hours[h])), collapse = "")
    }
  }
  write.table(t_points, paste(c(SaveTo,"timepoints.tab"), collapse = ""), sep="\t",row.names = F, quote = F)
  
  
  
  # loads.tab ---------------------------------------------------------------
  ercot_loads <- data.frame(matrix(ncol = 3, nrow = dim(ercot_zones)[1]*dim(t_points)[1]))
  colnames(ercot_loads) <- c("LOAD_ZONE","TIMEPOINT","zone_demand_mw")
  
  row_count = 0
  for(k in 1:dim(ercot_zones)[1]){ # loop through load zones
    for(j in 1:dim(t_points)[1]){ # loop through timepoints
      row_count = row_count+1
      ercot_loads$LOAD_ZONE[row_count] <- as.character(ercot_zones$LOAD_ZONE[k])
      ercot_loads$TIMEPOINT[row_count] <- t_points$timepoint_id[j]
      ercot_loads$zone_demand_mw[row_count] <- as.numeric(PLEXOS_zone_data[j,k+4])
    }
  }

  
  # Export .tab
  write.table(ercot_loads, paste(c(SaveTo,"loads.tab"), collapse = ""), sep="\t",row.names = F, quote = F)
  
  
  # variable_capacity_factors.tab ------------------------------------------- # NEED TO SAVE ANNUAL CFS, THEN RUN LOOP
  ercot_var_gens <- ercot_gen_info$GENERATION_PROJECT[ercot_gen_info$gen_is_variable==1] # isolate list of variable generators
  ercot_cfs <- data.frame(matrix(ncol = 3, nrow = length(ercot_var_gens)*dim(t_points)[1]))
  colnames(ercot_cfs) <- c("GENERATION_PROJECT","timepoint","gen_max_capacity_factor")
  ercot_cfs$GENERATION_PROJECT <- rep(ercot_var_gens, each = dim(t_points)[1])
  ercot_cfs$gen_max_capacity_factor <- 1 # setting all cap at 1 for now
  ercot_cfs$timepoint <- as.integer( rep(1:dim(t_points)[1], length(ercot_var_gens)) )
  # rename columns and rows
  names(ercot_cfs) <- c("GENERATION_PROJECT","timepoint","gen_max_capacity_factor")
  row.names(ercot_cfs) <- 1:dim(ercot_cfs)[1]
  write.table(ercot_cfs, paste(c(SaveTo,"variable_capacity_factors.tab"), collapse = ""), sep="\t",row.names = F, quote = F)
  
  }


