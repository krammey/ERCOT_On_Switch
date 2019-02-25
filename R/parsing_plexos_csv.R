setwd("~/GoogleDrive/1UT/0_Research/3_Switch/Test_Model/R/")
load("./20190222.RData")

# This code was written to help transferring PLEXOS FCe Data to .tab format for SWITCH
# List of switch core modules' required input files and required columns is in 'modules.txt'
gen_info <- read.delim(file = "/Users/trins/switch/examples/3zone_toy/inputs/generation_projects_info.tab", header = T, sep = "\t")
fce_file = './FCe_data_2015.csv' # Import FCe Plexos Data from /Users/trins/Box/Energy Storage/Archive/FCe dispatch modeling/Reports/
fce_data <- read.csv(file = fce_file, stringsAsFactors = F, na.strings="NA",row.names=NULL, header = T, sep = ",")
dot <- gen_info[dim(gen_info)[1],dim(gen_info)[2]]


#######################################################################################################
#                   Creating inputs for switch_model.timescales
########################################################################################################
# Need to see what Neal has come up with for this


# periods.tab ------------------------------------------------------------- DONE - copied from 3zone_toy
periods <- read.delim(file = "/Users/trins/switch/examples/copperplate0/inputs/periods.tab", header = T, sep = "\t")
# write.table(periods,"../FCe_Model/inputs/periods.tab",sep="\t", row.names = F, quote = F) # if quote = T, column names are with quotation marks and SWITCH doesn't process them 


# timeseries.tab ---------------------------------------------------------- DONE - copied from 3zone_toy
t_series <- read.delim(file = "/Users/trins/switch/examples/copperplate0/inputs/timeseries.tab", header = T, sep = "\t")
# write.table(t_series,"../FCe_Model/inputs/timeseries.tab",sep="\t",row.names = F, quote = F)


# timepoints.tab ---------------------------------------------------------- DONE - copied from 3zone_toy
t_points <- read.delim(file = "/Users/trins/switch/examples/copperplate0/inputs/timepoints.tab", header = T, sep = "\t")
# write.table(t_points,"../FCe_Model/inputs/timepoints.tab",sep="\t",row.names = F, quote = F)




#######################################################################################################
#                   Creating inputs for switch_model.financials
########################################################################################################


# financials.dat ----------------------------------------------------------DONE?
financials <- read.table(file = "/Users/trins/switch/examples/3zone_toy/inputs/financials.dat", header = T)
# I just copied this file into our folder





########################################################################################################
#                       Creating inputs for switch_model.generators.core.build
########################################################################################################


# generation_projects_info.tab --------------------------------------------DONE       (no gen_connect_cost_per_mw)

gen_info <- read.delim(file = "/Users/trins/switch/examples/3zone_toy/inputs/generation_projects_info.tab", header = T, sep = "\t")
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
write.table(fce_fuels,"../FCe_Model/inputs/fuels.tab",sep="\t",row.names = F, quote = F)



########################################################################################################
#                       Creating inputs for switch_model.generators.core.dispatch
########################################################################################################



# variable_capacity_factors.tab -------------------------------------------DONE
var_cfs <- read.delim(file = "/Users/trins/switch/examples/3zone_toy/inputs/variable_capacity_factors.tab", header = T, sep = "\t")
test <- gen_info[gen_info$gen_is_variable==1,]

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
# write.table(fce_cfs,"../FCe_Model/inputs/variable_capacity_factors.tab",sep="\t",row.names = F, quote = F)





#*******************************************************************************************************
#*******************************************************************************************************
#*******************************************************************************************************

#                                     Extensions from core module - not really developed yet

#*******************************************************************************************************
#*******************************************************************************************************
#*******************************************************************************************************




#######################################################################################################
#                   Creating inputs for switch_model.generators.extensions.storage
########################################################################################################


# generation_projects_info.tab ----------------------------------------------------------Need to add storage projects
# fce_gen_info$gen_storage_efficiency <- dot
# fce_gen_info$gen_store_to_release_ratio <- dot


# gen_build_costs.tab ---------------------------------------------------------------Need to add storage projects
# fce_build$gen_storage_energy_overnight_cost <- dot



#######################################################################################################
#                   Creating inputs for switch_model.transmission.local_td
########################################################################################################


# load_zones.tab ----------------------------------------------------------Need to add storage projects
# fce_load_zones$existing_local_td <- dot # local T&D capacity in MW that has already been built.




# Our plexos model will have:
# hourly load (possibly split up by zone), pre-determined wind & solar power output,





