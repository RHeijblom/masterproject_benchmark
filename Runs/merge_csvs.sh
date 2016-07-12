#!/bin/bash
pwd=$(pwd)
output="$pwd/allResults.csv"
isFirst=true
#$1 = directory
function mergeCsv() {
	cd "./$1"
	# Find the one and only csv file
	file=$(ls | grep ".csv")
	# Add content to output file
	if $isFirst; then
		cp "./$file" "$output"
		isFirst=false
	else
		tail -n +2 "./$file" >> "$output"
	fi
	echo "$pwd/$1/$file succesfully merged." 
	cd "$pwd"
}

# Start script
mergeCsv 'Experiment_3/5-11-1125'
mergeCsv 'Experiment_3/5-12-1045'
mergeCsv 'Experiment_3/5-17-1505'
mergeCsv 'Experiment_3/5-18-1345'
mergeCsv 'Experiment_3/5-19-1245'
mergeCsv 'Experiment_3/5-23-1235'
mergeCsv 'Experiment_3/5-24-1030'

mergeCsv 'Experiment_3/6-07-1030'
mergeCsv 'Experiment_3/6-07-1640'
mergeCsv 'Experiment_3/6-08-1240'
mergeCsv 'Experiment_3/6-09-1140'
mergeCsv 'Experiment_3/6-09-1600'
mergeCsv 'Experiment_3/6-13-1220'
mergeCsv 'Experiment_3/6-13-1650'

mergeCsv 'Experiment_4/5-25-1030'
mergeCsv 'Experiment_4/5-26-1325' 
mergeCsv 'Experiment_4/5-27-1255'
mergeCsv 'Experiment_4/5-30-1040'
mergeCsv 'Experiment_4/5-31-1030'
mergeCsv 'Experiment_4/6-02-1140'
mergeCsv 'Experiment_4/6-03-1240'

mergeCsv 'Experiment_4/6-14-1025'
mergeCsv 'Experiment_4/6-16-1325'
mergeCsv 'Experiment_4/6-17-1135'
mergeCsv 'Experiment_4/6-20-1035'
mergeCsv 'Experiment_4/6-21-1240'
mergeCsv 'Experiment_4/6-22-1050'
mergeCsv 'Experiment_4/6-28-1150'

mergeCsv 'Experiment_5/6-04-1235'
mergeCsv 'Experiment_5/6-29-1105'

mergeCsv 'Experiment_7'


