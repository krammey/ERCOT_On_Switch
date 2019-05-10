This model will take annual (8760) ERCOT model and break it into 12 hourly models (one for each month).

Runtime (s) 
TOTAL: 2813.051482 (47m)
01-January: 228.683803
02-February: 197.236726
03-March: 233.387627
04-April: 218.248048
05-May: 286.122828
06-June: 247.604695
07-July: 227.751813
08-Aug: 238.370986
09-Sept: 234.346847
10-Oct: 237.796264
11-Nov: 227.724686
12-Dec: 235.777159

To run all models, enter the following in Terminal:

for d in */ ; do
	cd ./$d
    switch solve --verbose --log-run --solver cplex
    cd ../
done
