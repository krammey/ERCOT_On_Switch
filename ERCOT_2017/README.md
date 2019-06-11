Author: Katrina Ramirez-Meyers
Last Updated June 11, 2019
Model version history available at https://github.com/krammey/ERCOT_On_Switch

This model will run an ERCOT model as 12 hourly models (one for each month). 
This is currently run at 20% load (see line 263 in ERCOT_2017_Cleaning.R) to make everything feasible.

The following files are included in the parent directory for easy copying into each month's folder:
[1] 'modules.txt'
[2] 'switch_inputs_version.txt'
[3] 'financials.dat'

Runtime (s) - as of 06/11/2019
TOTAL: 2813 (47m)
01-January: 228.7
02-February: 197.2
03-March: 233.4
04-April: 218.2
05-May: 286.1
06-June: 247.6
07-July: 227.7
08-Aug: 238.4
09-Sept: 234.3
10-Oct: 237.8
11-Nov: 227.7
12-Dec: 235.8

To run all models, enter the following in Terminal:

for d in */ ; do
	cd ./$d
    switch solve --verbose --log-run --solver cplex
    cd ../
done
