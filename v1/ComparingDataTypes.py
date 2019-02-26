
# Comparing tabs

generation_projects_info = pandas.read_excel(io = './R/20190218_FCe_Switch_Inputs.xlsx', sheet_name = 'generation_projects_info.tab')
gen_info_Fce_tab = pandas.read_table('./FCe_Model/inputs/generation_projects_info.tab')
gen_info_3zonetoy = pandas.read_table('/Users/trins/switch/examples/3zone_toy/inputs/generation_projects_info.tab')

print type(generation_projects_info.loc[1,"GENERATION_PROJECT"]) 		# unicode
print type(generation_projects_info.loc[1,"gen_tech"]) 					# unicode
print type(generation_projects_info.loc[1,"gen_load_zone"]) 			# unicode
print type(generation_projects_info.loc[1,"gen_connect_cost_per_mw"]) 	# unicode
print type(generation_projects_info.loc[1,"gen_full_load_heat_rate"]) 	# numpy.float64 ###################
print type(generation_projects_info.loc[1,"gen_variable_om"]) 			# numpy.float64
print type(generation_projects_info.loc[1,"gen_max_age"]) 				# numpy.int64
print type(generation_projects_info.loc[1,"gen_is_variable"]) 			# numpy.int64
print type(generation_projects_info.loc[1,"gen_is_baseload"]) 			# numpy.int64
print type(generation_projects_info.loc[1,"gen_energy_source"]) 		# unicode

print type(gen_info_Fce_tab.loc[1,"GENERATION_PROJECT"]) 		# str
print type(gen_info_Fce_tab.loc[1,"gen_tech"]) 					# str
print type(gen_info_Fce_tab.loc[1,"gen_load_zone"]) 			# str
print type(gen_info_Fce_tab.loc[1,"gen_connect_cost_per_mw"]) 	# str ###################
print type(gen_info_Fce_tab.loc[1,"gen_full_load_heat_rate"]) 	# numpy.float64 ###################
print type(gen_info_Fce_tab.loc[1,"gen_variable_om"]) 			# numpy.float64
print type(gen_info_Fce_tab.loc[1,"gen_max_age"]) 				# numpy.int64
print type(gen_info_Fce_tab.loc[1,"gen_is_variable"]) 			# numpy.int64
print type(gen_info_Fce_tab.loc[1,"gen_is_baseload"]) 			# numpy.int64
print type(gen_info_Fce_tab.loc[1,"gen_energy_source"]) 		# str

# THIS IS THE ONE THAT WORKS
print type(gen_info_3zonetoy.loc[1,"GENERATION_PROJECT"]) 		# str
print type(gen_info_3zonetoy.loc[1,"gen_tech"]) 				# str
print type(gen_info_3zonetoy.loc[1,"gen_load_zone"]) 			# str
print type(gen_info_3zonetoy.loc[1,"gen_connect_cost_per_mw"]) 	# numpy.float64 ###################
print type(gen_info_3zonetoy.loc[1,"gen_full_load_heat_rate"]) 	# str ###################. NOTE: Switch doesn't want numbers for variable plants
print type(gen_info_3zonetoy.loc[1,"gen_variable_om"]) 			# numpy.float64
print type(gen_info_3zonetoy.loc[1,"gen_max_age"]) 				# numpy.int64
print type(gen_info_3zonetoy.loc[1,"gen_is_variable"]) 			# numpy.int64
print type(gen_info_3zonetoy.loc[1,"gen_is_baseload"]) 			# numpy.int64
print type(gen_info_3zonetoy.loc[1,"gen_energy_source"]) 		# str
