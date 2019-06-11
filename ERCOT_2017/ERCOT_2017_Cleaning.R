

# Author: Katrina Ramirez-Meyers
# Version control information available on Github
# This code was written to import 2017 powerplant and load data into 12* hourly models. -> *one for each month
# Last updated 06/11/2019


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
# PLEXOS_zone_data$Panhandle <- 0

##########################################################################################
#             Create January files only - will be copied later
##########################################################################################
SaveTo <- "./2017_01/inputs/" # Save to January model for now


# generation_projects_info.tab --------------------------------------------
# Create empty data frame
ercot_gen_info <- data.frame(matrix(ncol = 10, nrow = dim(ercot_data)[1]))
colnames(ercot_gen_info) <- c("GENERATION_PROJECT","gen_tech","gen_load_zone","gen_connect_cost_per_mw","gen_variable_om","gen_max_age","gen_is_variable","gen_is_baseload","gen_energy_source","gen_full_load_heat_rate")

# Fill in data
ercot_gen_info$GENERATION_PROJECT <- as.factor(gsub(' ','_',ercot_data$Name)) #Replace spaces with underscores
ercot_gen_info$gen_tech <- as.factor(gsub(' ','_',ercot_data$Tech))
ercot_gen_info$gen_load_zone <- as.factor(ercot_data$Zone) # For now, I'm deleting everything with zone entry that's empty or is Panhandle
ercot_gen_info$gen_connect_cost_per_mw <- as.integer(0)
ercot_gen_info$gen_variable_om <- 0 # Can update this using formula: Round(GENERIC_VOM_Cost_USD_per_MWh / (1 + GENERIC_CPI_Inflation_Rate_2010-2011))
ercot_gen_info$gen_max_age <- as.integer(100)
ercot_gen_info$gen_is_variable <- as.integer(0) # note there are no renewables in this scenario
ercot_gen_info$gen_is_baseload <- as.integer(0)
ercot_gen_info$gen_energy_source <- as.factor(ercot_data$Fuel)
ercot_gen_info$gen_full_load_heat_rate <- as.factor(ercot_data$PLEXOS.AHRs..MMBtu.MWh.) # The plants below were given same heat rates as similar plants nearby in the list:
# [1] Ferguson_Replacement
# [2] Panda_Sherman       
# [3] Panda_Temple_1      
# [4] Panda_Temple_2  
ercot_gen_info$gen_full_load_heat_rate[ercot_gen_info$gen_full_load_heat_rate == 0] <- levels(ercot_gen_info$gen_full_load_heat_rate)[20] # I can't remember why I did this part... it doesn't seem to change anything

# Save .tab
write.table(ercot_gen_info, paste(c(SaveTo,"generation_projects_info.tab"), collapse = ""), sep="\t",row.names = F, quote = F)




# gen_build_predetermined.tab ---------------------------------------------
# Create empty data frame
ercot_predet <- data.frame(matrix(ncol = 3, nrow = dim(ercot_data)[1]))
colnames(ercot_predet) <- c("GENERATION_PROJECT","build_year","gen_predetermined_cap")
# Fill in data
ercot_predet$GENERATION_PROJECT <- ercot_gen_info$GENERATION_PROJECT
ercot_predet$build_year <- as.integer(ercot_data$Build.Year)
ercot_predet$build_year[is.na(ercot_predet$build_year)] <- as.integer(2017) # For now setting empty years as 2017
ercot_predet$gen_predetermined_cap <- ercot_data$Max.Cap.MW
# Save .tab
write.table(ercot_predet, paste(c(SaveTo,"gen_build_predetermined.tab"), collapse = ""), sep="\t",row.names = F, quote = F)




# gen_build_costs.tab -----------------------------------------------------
# Create empty data frame
ercot_build <- data.frame(matrix(ncol = 4, nrow = dim(ercot_data)[1] ))
colnames(ercot_build) <- c("GENERATION_PROJECT","build_year","gen_overnight_cost","gen_fixed_om")
# Fill in data
ercot_build$GENERATION_PROJECT <- ercot_gen_info$GENERATION_PROJECT
ercot_build$build_year <- as.integer(ercot_data$Build.Year)
ercot_build$build_year[is.na(ercot_build$build_year)] <- as.integer(2017) # for now setting setting empty years as 2017
ercot_build$gen_overnight_cost <- as.integer(100) # test value
ercot_build$gen_fixed_om <- 0 # test value. Actual values are in SCJ database
# Export .tab
write.table(ercot_build, paste(c(SaveTo,"gen_build_costs.tab"), collapse = ""), sep="\t",row.names = F, quote = F)


# load_zones.tab ----------------------------------------------------------***
# Create empty data frame
ercot_zones <- data.frame(matrix(ncol = 1, nrow = 4))
colnames(ercot_zones) <- "LOAD_ZONE"
# Fill in data
ercot_zones$LOAD_ZONE <- as.factor(c("Northeast", "South", "Coast", "West")) 
write.table(ercot_zones, paste(c(SaveTo,"load_zones.tab"), collapse = ""), sep="\t",row.names = F, quote = F)




# fuels.tab ---------------------------------------------------------------***
# Get list of unique fuels in ercot data, excluding Hydro - the only nonfuel in this data set
fuels <- unique(ercot_gen_info$gen_energy_source[!(ercot_gen_info$gen_energy_source %in%c('Hydro'))])
# Create empty data frame
ercot_fuels <- data.frame(matrix(ncol = 3, nrow = length(fuels)))
colnames(ercot_fuels) <- c("fuel","co2_intensity","upstream_co2_intensity")
# Fill in data
ercot_fuels$fuel <- fuels
# Fill in emissions info by averaging ercot data by fuel type
for(i in 1:dim(ercot_fuels)[1]){
  ercot_fuels$co2_intensity[i] <- mean(ercot_data$CO2.lb.MMBtu[ercot_data$Fuel == ercot_fuels$fuel[i]])/2204.62
  ercot_fuels$upstream_co2_intensity[i] <- ercot_fuels$co2_intensity[i]/10 # this is just an estimate based on trend in fce data
}
# Export .tab
write.table(ercot_fuels, paste(c(SaveTo,"fuels.tab"), collapse = ""), sep="\t",row.names = F, quote = F)




# periods.tab -------------------------------------------------------------UNCHANGED
# Create empty data frame
periods <- data.frame(matrix(ncol = 3, nrow = 1))
names(periods) <- c("INVESTMENT_PERIOD","period_start","period_end")
# Fill in data
periods[1,] <- 2017
# Export .tab
write.table(periods, paste(c(SaveTo,"periods.tab"), collapse = ""), sep="\t",row.names = F, quote = F)








##########################################################################################
#       Create remaining files by copying January or creating time-dependent files
##########################################################################################

# Define useful time arrays
num_days = c(31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
hours = as.character(c("00","01","02","03","04","05","06","07","08","09",10:23))
years = 2017
# months = as.character(c("01")) # you can uncomment this and comment the line below if you just want to make a January test model
months = as.character(c("01","02","03","04","05","06","07","08","09",10,11,12))
days_max = as.character(c("01","02","03","04","05","06","07","08","09",10:31))


############################ Already ran this. Doing it again will output an error
# create directories for each month
# for(m in 1:length(months)){
#   SaveTo <- paste(c("./2017_",months[m],"/inputs/"), collapse = "")
#   dir.create(paste(c("2017_",months[m]), collapse = ""))
#   dir.create(SaveTo) 
# }


# Loop through months and create Switch input files
for(m in 1:length(months)){
  
  # define directories for each month
  SaveTo <- paste(c("./2017_",months[m],"/inputs/"), collapse = "")
  print(SaveTo)
  
  ########################################################### 
  # These are copied because they don't change between months
  ###########################################################
  # Copy the .tabs generated for January model above
  write.table(ercot_gen_info, paste(c(SaveTo,"generation_projects_info.tab"), collapse = ""), sep="\t",row.names = F, quote = F)
  write.table(ercot_predet, paste(c(SaveTo,"gen_build_predetermined.tab"), collapse = ""), sep="\t",row.names = F, quote = F)
  write.table(ercot_build, paste(c(SaveTo,"gen_build_costs.tab"), collapse = ""), sep="\t",row.names = F, quote = F)
  write.table(ercot_zones, paste(c(SaveTo,"load_zones.tab"), collapse = ""), sep="\t",row.names = F, quote = F)
  write.table(ercot_fuels, paste(c(SaveTo,"fuels.tab"), collapse = ""), sep="\t",row.names = F, quote = F)
  write.table(periods, paste(c(SaveTo,"periods.tab"), collapse = ""), sep="\t",row.names = F, quote = F)
  file.copy('modules.txt', SaveTo)
  file.copy('switch_inputs_version.txt', SaveTo)
  file.copy('financials.dat', SaveTo)
  file.copy("./2017_01/inputs/variable_capacity_factors.tab", SaveTo) # There are no renewables in Sam's 2017 model, so all variable capacity factor columns are empty so I'm just copying that into the other months
  
  
  
  ########################################################### 
  # These are month-dependent
  ###########################################################
  
  # non_fuel_energy_sources.tab ---------------------------------------------
  # Get list of non-fuels
  nonfuels <- unique(ercot_gen_info$gen_energy_source[!(ercot_gen_info$gen_energy_source %in% fuels )])
  # Create empty data frame
  ercot_nonfuels <- data.frame(matrix(ncol = 1, nrow = length(nonfuels)))
  colnames(ercot_nonfuels) <- c("energy_source")
  # Fill in data
  ercot_nonfuels$energy_source <- nonfuels
  # Export .tab
  write.table(ercot_nonfuels, paste(c(SaveTo,"non_fuel_energy_sources.tab"), collapse = ""), sep="\t",row.names = F, quote = F)

  # timeseries.tab ---------------------------------------------------------- 
  # Create empty data frame
  t_series <- data.frame(matrix(ncol = 5, nrow = 1))
  names(t_series) <- c("TIMESERIES","ts_period","ts_duration_of_tp","ts_num_tps","ts_scale_to_period")
  # Fill in data
  t_series$ts_duration_of_tp <- as.integer(1)     # duration, in hours, of each timepoint within a timeseries
  t_series$TIMESERIES <- as.factor(paste(c("2017_",months[m]), collapse = ""))
  t_series$ts_period <- as.integer(2017)
  t_series$ts_num_tps <- as.integer(24*num_days[m]) # number of timepoints in a series
  t_series$ts_scale_to_period <- 8766/(24*num_days[m])
  # Export .tab
  write.table(t_series, paste(c(SaveTo,"timeseries.tab"), collapse = ""), sep="\t",row.names = F, quote = F)
  
  
  
  # timepoints.tab ---------------------------------------------------------- 
  # Create empty data frame
  t_points <- data.frame(matrix(ncol = 3, nrow = num_days[m]*length(hours)))
  colnames(t_points) <- c("timepoint_id","timestamp","timeseries")
  # Fill in data
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
  # Export .tab
  write.table(t_points, paste(c(SaveTo,"timepoints.tab"), collapse = ""), sep="\t",row.names = F, quote = F)
  
  
  
  # loads.tab ---------------------------------------------------------------
  # Create empty data frame
  ercot_loads <- data.frame(matrix(ncol = 3, nrow = dim(ercot_zones)[1]*dim(t_points)[1]))
  colnames(ercot_loads) <- c("LOAD_ZONE","TIMEPOINT","zone_demand_mw")
  # Fill in data
  row_count = 0
  for(k in 1:dim(ercot_zones)[1]){ # loop through load zones
    for(j in 1:dim(t_points)[1]){ # loop through timepoints
      row_count = row_count+1
      ercot_loads$LOAD_ZONE[row_count] <- as.character(ercot_zones$LOAD_ZONE[k])
      ercot_loads$TIMEPOINT[row_count] <- t_points$timepoint_id[j]
      ercot_loads$zone_demand_mw[row_count] <- as.numeric(.2*PLEXOS_zone_data[j,k+4])
    }
  }
  # Export .tab
  write.table(ercot_loads, paste(c(SaveTo,"loads.tab"), collapse = ""), sep="\t",row.names = F, quote = F)
  
  }


