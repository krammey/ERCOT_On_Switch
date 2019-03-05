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

########################################################################################################
########################################################################################################
########################################################################################################
#                     Continue cleaning/merging code from here - March 5, 2019
########################################################################################################
########################################################################################################
########################################################################################################
########################################################################################################



fce_gen_info <- fce_data[,1:10] # Copy data frame to get the right size set up. 10 = number of mandatory columns
names(fce_gen_info) <- c("GENERATION_PROJECT","gen_tech","gen_load_zone","gen_connect_cost_per_mw","gen_full_load_heat_rate","gen_variable_om","gen_max_age","gen_is_variable","gen_is_baseload","gen_energy_source") # Rename columns - for now, mandatory columns only

# mandatory columns
fce_gen_info$gen_connect_cost_per_mw <- 0 # cost of grid upgrades to support a new project, in $/peakMW --- possibly from https://energy.utexas.edu/sites/default/files/UTAustin_FCe_Exe_Summary_2018.pdf   NOTE: maybe we can leave this blank since we're not building new transmission? just storage? PULL these from other switch examples
fce_gen_info$gen_max_age <- 100  # this is max lifetime of plant ---NOT in fce_data?
fce_gen_info$GENERATION_PROJECT <- as.factor(gsub(' ','_',fce_data$Generator)) # projects that exist or could be built, gsub replaces spaces with underscores
fce_gen_info$gen_energy_source <- fce_data$Fuel
fce_gen_info$gen_energy_source[fce_gen_info$gen_energy_source=="Hydro"] <- "Water"
fce_gen_info$gen_load_zone <- fce_data$Load.Zone
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
for(k in 1:dim(fce_tech_list)[1]){fce_tech_list$gen_tech[k] <- paste(fce_tech_list$Fuel[k],fce_tech_list$Prime.Mover[k],sep="_")}
fce_gen_info$gen_tech <- fce_tech_list$gen_tech # NOTE: gen_tech can be anything but must be consistent for generation_projects_info.tab, gen_build_costs.tab, and gen_build_predetermined.tab

# Export .tab
write.table(fce_gen_info,"../FCe_Model/inputs/generation_projects_info.tab",sep="\t",row.names = F, quote = F)



# gen_build_predetermined.tab ---------------------------------------------DONE
gen_predetermined <- read.delim(file = "/Users/trins/switch/examples/3zone_toy/inputs/gen_build_predetermined.tab", header = T, sep = "\t")
fce_predetermined <- fce_data[,1:length(gen_predetermined)] # Copy data frame to get the right size set up
names(fce_predetermined) <- names(gen_predetermined)
fce_predetermined$GENERATION_PROJECT <- as.factor(gsub(' ','_',fce_predetermined$GENERATION_PROJECT)) # projects that exist or could be built, gsub replaces spaces with underscores
fce_predetermined$build_year <- fce_data$Online
fce_predetermined$gen_predetermined_cap <- fce_data$Net.Capacity.MW # how much capacity was built, or is planned to be built
# Export .tab
# write.table(fce_predetermined,"../../FCe_Model/inputs/gen_build_predetermined.tab",sep="\t",row.names = F, quote = F)



# gen_build_costs.tab -----------------------------------------------------DONE
gen_build <- read.delim(file = "/Users/trins/switch/examples/3zone_toy/inputs/gen_build_costs.tab", header = T, sep = "\t")
fce_build <- fce_data[,1:length(gen_build)] # Copy data frame to get the right size set up.
names(fce_build) <- names(gen_build)
fce_build$GENERATION_PROJECT <- as.factor(gsub(' ','_',fce_build$GENERATION_PROJECT)) # replace spaces with underscores
fce_build$build_year <- fce_data$Online
fce_build$gen_overnight_cost <- 100 # test value
fce_build$gen_fixed_om <- fce_data$Fixed.OM.Charge.USD.per.kWyr
fce_build$gen_fixed_om[is.na(fce_build$gen_fixed_om)] <- 0

# Export .tab
# write.table(fce_build,"../FCe_Model/inputs/gen_build_costs.tab",sep="\t",row.names = F, quote = F)



#######################################################################################################
#                   Creating inputs for switch_model.balancing.load_zones
########################################################################################################


# load_zones.tab ----------------------------------------------------------DONE

load_zones <- read.delim(file = "/Users/trins/switch/examples/3zone_toy/inputs/load_zones.tab", header = T, sep = "\t")
fce_load_zones <- fce_data[1:length(unique(fce_data$Load.Zone)),1:length(load_zones)]
names(fce_load_zones) <- names(load_zones)
fce_load_zones$LOAD_ZONE <- unique(fce_data$Load.Zone)
fce_load_zones[,2:length(fce_load_zones)] <- dot
fce_load_zones2 <- as.data.frame(fce_load_zones$LOAD_ZONE)
names(fce_load_zones2) <- names(load_zones)[1]
# Export .tab
write.table(fce_load_zones2,"../FCe_Model/inputs/load_zones.tab",sep="\t",row.names = F, quote = F)


# loads.tab ---------------------------------------------------------------DONE

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
# write.table(fce_loads,"../../FCe_Model/inputs/loads.tab",sep="\t",row.names = F, quote = F)




########################################################################################################
#                           Creating inputs for switch_model.energy_sources.properties
########################################################################################################

# non_fuel_energy_sources.tab ---------------------------------------------DONE

non_fuels <- read.delim(file = "/Users/trins/switch/examples/3zone_toy/inputs/non_fuel_energy_sources.tab", header = T, sep = "\t")
fce_non_fuels <- c("Wind","Wind-C","Solar","Geothermal","Water","Storage","Electricity")
# easier to just edit the .tab from the example


# fuels.tab ---------------------------------------------------------------Neal will send biogas CO2 info

fuels <- read.delim(file = "/Users/trins/switch/examples/3zone_toy/inputs/fuels.tab", header = T, sep = "\t")
fce_fuels <- fce_data[1:(3+length(unique(fce_data$Fuel))),1:length(fuels)]
names(fce_fuels) <- names(fuels)
fce_fuels$fuel <- unique(c(fce_data$Fuel,"Electricity","Water","Geothermal"))
#
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
# write.table(fce_fuels,"../FCe_Model/inputs/fuels.tab",sep="\t",row.names = F, quote = F)



########################################################################################################
#                       Creating inputs for switch_model.generators.core.dispatch
########################################################################################################



# variable_capacity_factors.tab -------------------------------------------DONE
var_cfs <- read.delim(file = "/Users/trins/switch/examples/3zone_toy/inputs/variable_capacity_factors.tab", header = T, sep = "\t")
fce_var_gens <- fce_gen_info$GENERATION_PROJECT[fce_gen_info$gen_is_variable==1] # isolate list of variable generators
cf_rows <- length(fce_var_gens)*dim(t_points)[1]
fce_cfs <- fce_data[1:cf_rows,1:length(var_cfs)] # Copy data frame to get the right size set up.
names(fce_cfs) <- names(var_cfs)
# loop through GENERATION_PROJECT and tps to create cfs
cf_gens <- fce_var_gens[ rep(seq_len(nrow(fce_var_gens)), each = length(t_points$timepoint_id)) ,]

row_count = 0
for(k in 1:length(fce_var_gens)){ # loop through variable generators
  for(j in 1:dim(t_points)[1]){ # loop through timepoints
    row_count = row_count+1
    fce_cfs$GENERATION_PROJECT[row_count] <- as.character.factor(fce_var_gens[k])
    fce_cfs$timepoint[row_count] <- t_points[j,1]
    
  }
}

fce_cfs$GENERATION_PROJECT <- rep(fce_var_gens, dim(t_points)[1])
fce_cfs$gen_max_capacity_factor <- 0.50 # setting all cap at 0.5 for now
fce_cfs$timepoint <- as.integer(fce_cfs$timepoint)


# Export .tab
# write.table(fce_cfs,"../FCe_Model/inputs/variable_capacity_factors.tab",sep="\t",row.names = F, quote = F)




