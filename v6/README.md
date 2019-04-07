This model will take annual (8760) ERCOT model and break it into 12 hourly models (one for each month).

To run all models, enter the following in Terminal:

for d in */ ; do
	cd ./$d
    switch solve --verbose --log-run --solver cplex
    cd ../
done
