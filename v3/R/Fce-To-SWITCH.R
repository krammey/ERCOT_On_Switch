setwd("~/GoogleDrive/1UT/2_Research/3_Switch/Fce_R_Development/v3/R/")
load(".RData")

# Author: Katrina Ramirez-Meyers
# This code was written to help transferring PLEXOS FCe Data to .tab format for SWITCH
# List of switch core modules' required input files and required columns is in 'modules.txt'


# Define some useful variables to shorten code later
dot = as.factor('.')
SaveTo = "../FCe_Model/inputs/"
ExampleFiles = "/Users/trins/switch/examples/copperplate0/inputs/"

#######################################################################################################
#                   Importing Data
######################################################################################################## F

# FCe power plant data from 2015
fce_file = '/Users/trins/Box/Energy\ Storage/T4\ Thermo\ Model/Switch\ ERCOT\ Model/R_Development/FCe_data_2015.csv' # Import FCe Plexos Data from /Users/trins/Box/Energy Storage/Archive/FCe dispatch modeling/Reports/
fce_data <- read.csv(file = fce_file, stringsAsFactors = F, na.strings="NA",row.names=NULL, header = T, sep = ",")

# ERCOT load data from 2018
folder = "../../../20190126_SCJ_Data/"

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
########################################################################################################
# Need to see what Neal has come up with for this


# periods.tab ------------------------------------------------------------- 
ExamplePeriods = paste(c(ExampleFiles,"periods.tab"), collapse = "")
periods <- read.delim(file = ExamplePeriods, header = T, sep = "\t")
periods$INVESTMENT_PERIOD <- 2018
periods$period_start <- 2018
periods$period_end <- 2018
write.table(periods, paste(c(SaveTo,"periods.tab"), collapse = ""), sep="\t", row.names = F, quote = F)


# timeseries.tab ---------------------------------------------------------- 
ExampleTimeseries = paste(c(ExampleFiles,"timeseries.tab"), collapse = "")
t_series <- read.delim(file = ExampleTimeseries, header = T, sep = "\t")

t_series$ts_period = 2018
t_series$ts_num_tps = dim(Z1_data)[1]  # number of timepoints in a series
t_series$ts_duration_of_tp = 1 # duration, in hours, of each timepoint within a timeseries
t_series$ts_scale_to_period = 1 # number of timeseries per period
t_series$TIMESERIES <- '2018_all'

write.table(t_series, paste(c(SaveTo,"timeseries.tab"), collapse = ""), sep="\t",row.names = F, quote = F)


# timepoints.tab ---------------------------------------------------------- 
ExampleTimepoints = paste(c(ExampleFiles,"timepoints.tab"), collapse = "")

t_points <- read.delim(file = ExampleTimepoints, header = T, sep = "\t")
number_tps = dim(Z1_data)[1]*dim(t_series)[1]
t_points <- as.data.frame(t_points[1:number_tps,], row.names = 1:number_tps) # redefine new dataframe of with correct size

t_points$timepoint_id <- 1:number_tps
levels(t_points$timeseries) <- t_series$TIMESERIES # have to redefine levels to put new timeseries
t_points$timeseries <- t_series$TIMESERIES[1]

num_days = c(31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
hours = as.character(c("00","01","02","03","04","05","06","07","08","09",10:23))
years = 2018
months = as.character(c("01","02","03","04","05","06","07","08","09",10,11,12))
days_max = as.character(c("01","02","03","04","05","06","07","08","09",10:31))

count = 0
for(y in 1:length(years)){
  for(m in 1:12){
    for(d in 1:num_days[m]){
      for(h in 1:length(hours)){
        count = count + 1
        t_points$timestamp[count] <- paste(c(years[y], as.character(months[m]), as.character(days_max[d]), as.character(hours[h])), collapse = "")
      }
    }
  }
}


write.table(t_points, paste(c(SaveTo,"timepoints.tab"), collapse = ""), sep="\t",row.names = F, quote = F)



#######################################################################################################
#                   Creating inputs for switch_model.financials
########################################################################################################


# financials.dat ----------------------------------------------------------DONE?
ExampleFinancials = paste(c(ExampleFiles,"financials.dat"), collapse = "")
file.copy(ExampleFinancials, SaveTo)
# I just copied this file into our folder





########################################################################################################
#                       Creating inputs for switch_model.generators.core.build
########################################################################################################


# generation_projects_info.tab --------------------------------------------DONE       (no gen_connect_cost_per_mw)
ExampleGenInfo = paste(c(ExampleFiles,"generation_projects_info.tab"), collapse = "")

gen_info <- read.delim(file = ExampleGenInfo, header = T, sep = "\t")
num_gens <- length(fce_data$Generator)
mandatory_gen_info_cols <- c("GENERATION_PROJECT","gen_tech","gen_load_zone","gen_connect_cost_per_mw","gen_full_load_heat_rate","gen_variable_om","gen_max_age","gen_is_variable","gen_is_baseload","gen_energy_source")
fce_gen_info <- gen_info[1:num_gens, names(gen_info) %in% mandatory_gen_info_cols]
# NOTE: if there's a bug, try naming columns in order of 'mandatory_gen_info_cols'

fce_gen_info$gen_connect_cost_per_mw <- 0 # cost of grid upgrades to support a new project, in $/peakMW --- possibly from https://energy.utexas.edu/sites/default/files/UTAustin_FCe_Exe_Summary_2018.pdf   NOTE: maybe we can leave this blank since we're not building new transmission? just storage? PULL these from other switch examples
fce_gen_info$gen_max_age <- 100  # NOT in fce_data
fce_gen_info$GENERATION_PROJECT <- as.factor(gsub(' ','_',fce_data$Generator)) # replaces spaces with underscores
fce_gen_info$gen_energy_source <- fce_data$Fuel
fce_gen_info$gen_energy_source[fce_gen_info$gen_energy_source=="Hydro"] <- "Water"
#
fce_gen_info$gen_load_zone <- fce_data$Load.Zone
# Need to edit FCe zones (2015) to match Sam's Plexos data
fce_zones_archive <- fce_gen_info$gen_load_zone
fce_gen_info$gen_load_zone[ fce_gen_info$gen_load_zone == "AEN"] <- "South" # (16 gens) Austin Energy North
fce_gen_info$gen_load_zone[ fce_gen_info$gen_load_zone == "North"] <- "Northeast" 
fce_gen_info$gen_load_zone[ fce_gen_info$gen_load_zone == "Houston"] <- "Coastal"
fce_gen_info$gen_load_zone[ fce_gen_info$gen_load_zone == "CPS"] <- "South" # (5 gens) (San Antonio area)
fce_gen_info$gen_load_zone[ fce_gen_info$gen_load_zone == "LCRA"] <- "South" # (17 gens) Lower Colorado River Authority
fce_gen_info$gen_load_zone[ fce_gen_info$gen_load_zone == "RCEC"] <- "Northeast" # (1 gen) Rayburn County Electric Cooperative load zone
#
fce_gen_info$gen_is_baseload <- 0 # not in fce data. so set for zero...
fce_gen_info$gen_variable_om <- fce_data$Variable.O.M.Charge.USD.per.MWh  # Need to make sure the units are right
fce_gen_info$gen_variable_om[is.na(fce_gen_info$gen_variable_om)] <- 0
#
fce_gen_info$gen_full_load_heat_rate <- as.numeric(fce_data$Average.Heat.Rate.Btu.per.kWh)/1000 # MMBTU/MWh
fce_gen_info$gen_full_load_heat_rate[is.na(fce_gen_info$gen_full_load_heat_rate)==TRUE] <- '.'
#
fce_gen_info$gen_is_variable <- 0
fce_gen_info$gen_is_variable[fce_gen_info$gen_energy_source %in% c("Solar","Wind","Wind-C")] <- 1
#
fce_tech_list <- fce_data[,c("Generator","Fuel","Prime.Mover")]
for(k in 1:dim(fce_tech_list)[1]){
  fce_tech_list$gen_tech[k] <- paste(fce_tech_list$Fuel[k],fce_tech_list$Prime.Mover[k],sep="_")
  }
fce_gen_info$gen_tech <- fce_tech_list$gen_tech # NOTE: gen_tech can be anything but must be consistent for generation_projects_info.tab, gen_build_costs.tab, and gen_build_predetermined.tab

# Export .tab
write.table(fce_gen_info, paste(c(SaveTo,"generation_projects_info.tab"), collapse = ""), sep="\t",row.names = F, quote = F)


# gen_build_predetermined.tab ---------------------------------------------
ExampleBuild = paste(c(ExampleFiles,"gen_build_predetermined.tab"), collapse = "")

gen_predetermined <- read.delim(file = ExampleBuild, header = T, sep = "\t")
fce_predetermined <- fce_data[,1:length(gen_predetermined)] # Copy data frame to get the right size set up
names(fce_predetermined) <- names(gen_predetermined)
fce_predetermined$GENERATION_PROJECT <- as.factor(gsub(' ','_',fce_predetermined$GENERATION_PROJECT)) # projects that exist or could be built, gsub replaces spaces with underscores
fce_predetermined$build_year <- fce_data$Online
fce_predetermined$gen_predetermined_cap <- fce_data$Net.Capacity.MW # how much capacity was built, or is planned to be built
# Export .tab
write.table(fce_predetermined,paste(c(SaveTo,"gen_build_predetermined.tab"), collapse = ""), sep="\t",row.names = F, quote = F)



# gen_build_costs.tab -----------------------------------------------------
ExampleCosts = paste(c(ExampleFiles,"gen_build_costs.tab"), collapse = "")

gen_build <- read.delim(file = ExampleCosts, header = T, sep = "\t")
fce_build <- fce_data[,1:length(gen_build)] # Copy data frame to get the right size set up.
names(fce_build) <- names(gen_build)
fce_build$GENERATION_PROJECT <- as.factor(gsub(' ','_',fce_build$GENERATION_PROJECT)) # replace spaces with underscores
fce_build$build_year <- fce_data$Online
fce_build$gen_overnight_cost <- 100 # test value
fce_build$gen_fixed_om <- fce_data$Fixed.OM.Charge.USD.per.kWyr
fce_build$gen_fixed_om[is.na(fce_build$gen_fixed_om)] <- 0

# Export .tab
write.table(fce_predetermined, paste(c(SaveTo,"gen_build_costs.tab"), collapse = ""), sep="\t",row.names = F, quote = F)



#######################################################################################################
#                   Creating inputs for switch_model.balancing.load_zones
########################################################################################################


# load_zones.tab ----------------------------------------------------------
ExampleZones = paste(c(ExampleFiles,"load_zones.tab"), collapse = "")
load_zones <- read.delim(file = ExampleZones, header = T, sep = "\t")
fce_load_zones <- as.data.frame(unique(fce_gen_info$gen_load_zone))
names(fce_load_zones) <- names(load_zones)[1]
# Export .tab
write.table(fce_load_zones, paste(c(SaveTo,"load_zones.tab"), collapse = ""), sep="\t",row.names = F, quote = F)


# loads.tab ---------------------------------------------------------------
ExampleLoads = paste(c(ExampleFiles,"loads.tab"), collapse = "")
PLEXOS_zone_data <- cbind.data.frame(Z1_data, Z2_data[5], Z3_data[5], Z4_data[5])
loads <- read.delim(file = ExampleLoads, header = T, sep = "\t")
load_rows = dim(fce_load_zones)[1]*dim(t_points)[1]
fce_loads <- fce_data[1:load_rows,1:length(loads)] # Copy data frame to get the right size set up.
names(fce_loads) <- names(loads)
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
write.table(fce_loads, paste(c(SaveTo,"loads.tab"), collapse = ""), sep="\t",row.names = F, quote = F)



########################################################################################################
#                           Creating inputs for switch_model.energy_sources.properties
########################################################################################################

# non_fuel_energy_sources.tab ---------------------------------------------DONE
ExampleNonFuels = paste(c(ExampleFiles,"non_fuel_energy_sources.tab"), collapse = "")
non_fuels <- read.delim(file = ExampleNonFuels, header = T, sep = "\t")
fce_non_fuels <- c("Wind","Wind-C","Solar","Geothermal","Water","Storage","Electricity")
fce_non_fuels2 <- as.data.frame(non_fuels[1:length(fce_non_fuels),])
names(fce_non_fuels2) <- names(non_fuels)
fce_non_fuels2$energy_source <- fce_non_fuels
# Export .tab
write.table(fce_non_fuels2, paste(c(SaveTo,"non_fuel_energy_sources.tab"), collapse = ""), sep="\t",row.names = F, quote = F)


# fuels.tab ---------------------------------------------------------------Neal will send biogas CO2 info
ExampleFuels = paste(c(ExampleFiles,"fuels.tab"), collapse = "")
fuels <- read.delim(file = ExampleFuels, header = T, sep = "\t")
fce_fuel_list <- unique(c(fce_gen_info$gen_energy_source,"Electricity","Geothermal"))
fce_fuels <- fuels[1:length(fce_fuel_list),]
row.names(fce_fuels) <- 1:length(fce_fuel_list)
#
fce_fuels$fuel <- fce_fuel_list
fce_fuels$co2_intensity <- 0 # metric tonnes CO2 per MMBtu - SOURCE https://www.eia.gov/environment/emissions/co2_vol_mass.php
fce_fuels$co2_intensity[fce_fuels$fuel == "Coal-Lig"] <- 215.40/2204.62 # tCO2/MMBTU NOTE: converting lb to tonne
fce_fuels$co2_intensity[fce_fuels$fuel == "Coal-Sub"] <- 214.30/2204.62 # tCO2/MMBTU 
fce_fuels$co2_intensity[fce_fuels$fuel == "Geothermal"] <- 16.99/2204.62 # tCO2/MMBTU
fce_fuels$co2_intensity[fce_fuels$fuel == "NG"] <- 117/2204.62 # tCO2/MMBTU  
#
fce_fuels$upstream_co2_intensity <- 0 # metric tonnes CO2 per MMBtu - SOURCE  http://mpaenvironment.ei.columbia.edu/files/2014/06/UpstreamEmissionsReport_SIPA_REVISED.pdf
fce_fuels$upstream_co2_intensity[fce_fuels$fuel == "Coal-Lig"] <- 13.02/1000 # tCO2/MMBTU  NOTE: converting kg to tonne
fce_fuels$upstream_co2_intensity[fce_fuels$fuel == "Coal-Sub"] <- 13.02/1000 # tCO2/MMBTU
fce_fuels$upstream_co2_intensity[fce_fuels$fuel == "NG"] <- 24.69/1000 # tCO2/MMBTU
# TAKE OUT NON-FUELS
fce_fuels <- fce_fuels[!(fce_fuels$fuel %in% c(fce_non_fuels,"Hydro")),]

# Export .tab
write.table(fce_fuels, paste(c(SaveTo,"fuels.tab"), collapse = ""), sep="\t",row.names = F, quote = F)



########################################################################################################
#                       Creating inputs for switch_model.generators.core.dispatch
########################################################################################################



# variable_capacity_factors.tab -------------------------------------------DONE
ExampleVarCfs = paste(c(ExampleFiles,"variable_capacity_factors.tab"), collapse = "")
var_cfs <- read.delim(file = ExampleVarCfs, header = T, sep = "\t")

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





