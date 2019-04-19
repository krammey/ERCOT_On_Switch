# This script will transfer data for a Switch model from an excel spreadsheet to .tab files

cd /Users/trins/GoogleDrive/1UT/0_Research/3_Switch/Test_Model/
import pandas

#------- Loading data from spreadsheet for Test Model

# switch_model.timescales 
periods = pandas.read_excel(io = './R/20190218_FCe_Switch_Inputs.xlsx', sheet_name = 'periods.tab')
timeseries = pandas.read_excel(io = './R/20190218_FCe_Switch_Inputs.xlsx', sheet_name = 'timeseries.tab')
timepoints = pandas.read_excel(io = './R/20190218_FCe_Switch_Inputs.xlsx', sheet_name = 'timepoints.tab')


# switch_model.financials
# financials = pandas.read_excel(io = './R/20190218_FCe_Switch_Inputs.xlsx', sheet_name = 'financials.dat')


# switch_model.balancing.load_zones 
load_zones = pandas.read_excel(io = './R/20190218_FCe_Switch_Inputs.xlsx', sheet_name = 'load_zones.tab')
loads = pandas.read_excel(io = './R/20190218_FCe_Switch_Inputs.xlsx', sheet_name = 'loads.tab')


# switch_model.energy_sources.properties
non_fuel_energy_sources = pandas.read_excel(io = './R/20190218_FCe_Switch_Inputs.xlsx', sheet_name = 'non_fuel_energy_sources.tab')
fuels = pandas.read_excel(io = './R/20190218_FCe_Switch_Inputs.xlsx', sheet_name = 'fuels.tab')


# switch_model.generators.core.build
generation_projects_info = pandas.read_excel(io = './R/20190218_FCe_Switch_Inputs.xlsx', sheet_name = 'generation_projects_info.tab')
generation_projects_info['gen_full_load_heat_rate'] = generation_projects_info['gen_full_load_heat_rate'].astype(str)
gen_build_predetermined = pandas.read_excel(io = './R/20190218_FCe_Switch_Inputs.xlsx', sheet_name = 'gen_build_predetermined.tab')
gen_build_costs = pandas.read_excel(io = './R/20190218_FCe_Switch_Inputs.xlsx', sheet_name = 'gen_build_costs.tab')


# switch_model.generators.core.dispatch
variable_capacity_factors = pandas.read_excel(io = './R/20190218_FCe_Switch_Inputs.xlsx', sheet_name = 'variable_capacity_factors.tab')


