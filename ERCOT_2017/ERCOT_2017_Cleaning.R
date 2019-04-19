

# Author: Katrina Ramirez-Meyers
# This code was written to convert a full-year 8760 model to 12 hourly models


# Define useful paths
AnnualModel2015 = "../Fce_R_Development/v5/FCe_Model/inputs/"
ERCOT2017_file = "../2017_Master_Gen_Fleet.csv"

# Import ERCOT data
ercot_data_orig <- read.csv(file = ERCOT2017_file, stringsAsFactors = F, na.strings="NA",row.names=NULL, header = T, sep = ",")
# Take out unneeded columns
ercot_data <- ercot_data_orig[,!(names(ercot_data_orig) %in% c(
                                     "ORIS..",
                                     "Plant.List..",
                                     "Cooling.Type.Name",
                                     "CHP.Flag",
                                     "Exist.2014.Flag",
                                     "X.For.CHP..2009.eGrid.Capacity..MW.",
                                     "X.For.CHP..Capacity.Participation.Fraction",
                                     "Rounded.Modeled.Max.Capacity..MW.",
                                     "Rounded.Min.Stable.Level..MW.",
                                     "X..Generic...2011.VOM.Cost....MWh.",
                                     "X..Generic...2011.Startup.Cost....MW.start.",
                                     "X2011.Startup.Cost....start.",
                                     "PLEXOS.AHRs..MMBtu.MWh.",
                                     "Poly.Heat.Rate...Incr..BTU.kWh.",
                                     "Poly.Heat.Rate...Incr2..BTU.kWh.2..",
                                     "Polynomial.HR.Example.Calc..at.MaxCap.for.1.hr.",
                                     "Polynomial.HR.Example.Calc..at.MinCap.for.1.hr.",
                                     "SO2..lb.MMBtu.",
                                     "NOx..lb.MMBtu.",
                                     "SO2...MaxCap..lb.MWh.",
                                     "NOx...MaxCap..lb.MWh.",
                                     "Water.Consumption..lb.MWh."  ,
                                     "Water.Withdrawal..lb.MWh.",
                                     "Water.Consumption..gal.MWh.",
                                     "Water.Withdrawal..gal.MWh.",
                                     "X",
                                     "X2010.VOM.Cost....MWh.",
                                     "X2010.Startup.Cost....start.",
                                     "X2020.VOM.Cost....MWh.",
                                     "X2020.Startup.Cost....start."))]
names(ercot_data) <- c('Name','Fuel',
                       'Tech','Zone',
                       'County','Build.Year',
                       'Rated.Cap.MW','Max.Cap.MW',
                       'Min.Cap.Fraction','Min.Cap.MW',
                       'Min.Down.Time.hr','Min.Up.Time.hr',
                       'Max.Ramp.Rate.Fraction','Max.Ramp.Rate.MW.min',
                       'Reserves.VOM.MW','Poly.Heat.Rate.MMBtu.hr',
                       'CO2.lb.MMBtu','CO2.Max.Cap.lb.MWh',
                       'VOM.MWh','StartupCost.start')




############################ These reference FCe data in '../Fce_R_Development/20190405_Fce-To-SWITCH.R/
# generation_projects_info.tab --------------------------------------------
FCeGenInfoTab = paste(c(AnnualModel2015,"generation_projects_info.tab"), collapse = "")
fce_gen_info <- read.delim(file = FCeGenInfoTab, header = T, sep = "\t")

ercot_gen_info <- fce_gen_info[1:dim(ercot_data)[1],]
ercot_gen_info$GENERATION_PROJECT <- as.factor(gsub(' ','_',ercot_data$Name))
ercot_gen_info$gen_tech <- ercot_data$Tech #ercot_data
ercot_gen_info$gen_load_zone <- ercot_data$Zone
ercot_gen_info$gen_connect_cost_per_mw <- 0
ercot_gen_info$gen_variable_om <- ercot_data$VOM.MWh # Need to make sure the units are right
ercot_gen_info$gen_max_age <- 100
ercot_gen_info$gen_is_variable <- 0#[fce_gen_info$gen_energy_source %in% c("Solar","Wind","Wind-C")] <- 1
ercot_gen_info$gen_is_baseload <- 0
ercot_gen_info$gen_energy_source <- ercot_data$Fuel # where are the non-fuels?
ercot_gen_info$gen_full_load_heat_rate <- ercot_data$Poly.Heat.Rate.MMBtu.hr # these units are supposed to be in MMBTU/MWh
# Save to January model for now
write.table(ercot_gen_info, paste(c("./2017_01/inputs/","generation_projects_info.tab"), collapse = ""), sep="\t",row.names = F, quote = F)




# gen_build_predetermined.tab ---------------------------------------------
FCePredetTab = paste(c(AnnualModel2015,"gen_build_predetermined.tab"), collapse = "")
fce_predet <- read.delim(file = FCePredetTab, header = T, sep = "\t")

ercot_predet <- fce_predet[1:dim(ercot_data)[1],]
ercot_predet$GENERATION_PROJECT <- ercot_gen_info$GENERATION_PROJECT
ercot_predet$build_year <- ercot_data$Build.Year
ercot_predet$gen_predetermined_cap <- ercot_data$Max.Cap.MW
write.table(ercot_predet, paste(c("./2017_01/inputs/","gen_build_predetermined.tab"), collapse = ""), sep="\t",row.names = F, quote = F)




# gen_build_costs.tab -----------------------------------------------------
FCeBuildTab = paste(c(AnnualModel2015,"gen_build_costs.tab"), collapse = "")
fce_build <- read.delim(file = FCeBuildTab, header = T, sep = "\t")

ercot_build <- fce_build[1:dim(ercot_data)[1],]

ercot_build$GENERATION_PROJECT <- ercot_gen_info$GENERATION_PROJECT
ercot_build$build_year <- ercot_data$Build.Year
ercot_build$gen_overnight_cost <- 100 # test value
ercot_build$gen_fixed_om <- 0 # test value. Actual values are in SCJ database
write.table(ercot_build, paste(c("./2017_01/inputs/","gen_build_costs.tab"), collapse = ""), sep="\t",row.names = F, quote = F)


############################ These reference generation_projects_info
# load_zones.tab ----------------------------------------------------------***
FCeZonesTab = paste(c(AnnualModel2015,"load_zones.tab"), collapse = "")
fce_zones <- read.delim(file = FCeZonesTab, header = T, sep = "\t")

ercot_zones <- as.data.frame(unique(ercot_gen_info$gen_load_zone))
names(ercot_zones) <- names(fce_zones)[1]
write.table(ercot_zones, paste(c("./2017_01/inputs/","load_zones.tab"), collapse = ""), sep="\t",row.names = F, quote = F)

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
write.table(ercot_fuels, paste(c("./2017_01/inputs/","fuels.tab"), collapse = ""), sep="\t",row.names = F, quote = F)
# file.copy(AnnualFuels, SaveTo)


# variable_capacity_factors.tab ------------------------------------------- # NEED TO SAVE ANNUAL CFS, THEN RUN LOOP
AnnualCFs = paste(c(AnnualModel2015,"variable_capacity_factors.tab"), collapse = "")
annual_cfs <- read.delim(file = AnnualCFs, header = T, sep = "\t")
cfs <- annual_cfs[annual_cfs$timepoint %in% t_points$timepoint_id,]

write.table(cfs, paste(c(SaveTo,"variable_capacity_factors.tab"), collapse = ""), sep="\t",row.names = F, quote = F)








# Define useful time arrays
num_days = c(31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
hours = as.character(c("00","01","02","03","04","05","06","07","08","09",10:23))
years = 2018
months = as.character(c("01","02","03","04","05","06","07","08","09",10,11,12)) # to expand the for-loops to do all twelve months, remove ))#
days_max = as.character(c("01","02","03","04","05","06","07","08","09",10:31))

for(m in 1:length(months)){
  
  
  # create directories for each month
  SaveTo <- paste(c("./2017_",months[m],"/inputs/"), collapse = "")
  # dir.create(paste(c("2017_",months[m]), collapse = ""))
  # dir.create(SaveTo)############################ Already ran this. Doing it again will output an error
  
  # timeseries.tab ---------------------------------------------------------- 
  AnnualTimeseries = paste(c(AnnualModel2015,"timeseries.tab"), collapse = "")
  t_series <- read.delim(file = AnnualTimeseries, header = T, sep = "\t")
  # Unchanged columns in this .tab are:
  # ts_period = 2018
  # ts_duration_of_tp = 1     duration, in hours, of each timepoint within a timeseries
  t_series$TIMESERIES <- paste(c("2017_",months[m]), collapse = "")
  t_series$ts_num_tps <- 24*num_days[m] # number of timepoints in a series
  t_series$ts_scale_to_period <- 8766/(24*num_days[m])
  write.table(t_series, paste(c(SaveTo,"timeseries.tab"), collapse = ""), sep="\t",row.names = F, quote = F)
  
  
  
  # timepoints.tab ---------------------------------------------------------- 
  AnnualTimepoints = paste(c(AnnualModel2015,"timepoints.tab"), collapse = "")
  annual_tps <- read.delim(file = AnnualTimepoints, header = T, sep = "\t")
  tp_start <- 24*sum(num_days[1:m-1]) + 1 # skip all previous months
  tp_end <- tp_start + 24*num_days[m] - 1
  t_points <- as.data.frame(annual_tps[tp_start:tp_end,])
  t_points$timeseries <- t_series$TIMESERIES
  write.table(t_points, paste(c(SaveTo,"timepoints.tab"), collapse = ""), sep="\t",row.names = F, quote = F)
  
  
  # loads.tab ---------------------------------------------------------------
  AnnualLoads = paste(c(AnnualModel2015,"loads.tab"), collapse = "")
  annual_loads <- read.delim(file = AnnualLoads, header = T, sep = "\t")
  loads <- annual_loads[annual_loads$TIMEPOINT %in% t_points$timepoint_id,]
  write.table(loads, paste(c(SaveTo,"loads.tab"), collapse = ""), sep="\t",row.names = F, quote = F)
  
  
  ############################ NEED TO CONFIRM if these remain unchanged
  # modules.txt ----------------------------------------------------------UNCHANGED
  modules = paste(c(AnnualModel2015,"modules.txt"), collapse = "")
  file.copy(modules, SaveTo)
  
  # switch_inputs_version.txt ----------------------------------------------------------UNCHANGED
  version = paste(c(AnnualModel2015,"switch_inputs_version.txt"), collapse = "")
  file.copy(version, SaveTo)
  
  # periods.tab -------------------------------------------------------------UNCHANGED
  AnnualPeriods = paste(c(AnnualModel2015,"periods.tab"), collapse = "")
  periods <- read.delim(file = AnnualPeriods, header = T, sep = "\t")
  file.copy(AnnualPeriods, SaveTo)
  
  # financials.dat ----------------------------------------------------------UNCHANGED
  AnnualFinancials = paste(c(AnnualModel2015,"financials.dat"), collapse = "")
  file.copy(AnnualFinancials, SaveTo)
  
  
  # non_fuel_energy_sources.tab ---------------------------------------------UNCHANGED
  AnnualNonFuels = paste(c(AnnualModel2015,"non_fuel_energy_sources.tab"), collapse = "")
  file.copy(AnnualNonFuels, SaveTo)
  
  }


