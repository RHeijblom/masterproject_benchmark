#!/bin/bash
pwd=$(pwd)
#$1 = directory
function selectRandomFile() {
	cd "./$1/out"
	ls | shuf -n 1 | xargs -I model cp ./model ~/Project/masterproject_benchmark/Runs/Sample/model
	cd "$pwd"
}

# Start script
selectRandomFile 'Experiment_3/5-11-1125'
selectRandomFile 'Experiment_3/5-12-1045'
selectRandomFile 'Experiment_3/5-17-1505'
selectRandomFile 'Experiment_3/5-18-1345'
selectRandomFile 'Experiment_3/5-19-1245'
selectRandomFile 'Experiment_3/5-23-1235'
selectRandomFile 'Experiment_3/5-24-1030'

selectRandomFile 'Experiment_3/6-07-1030'
selectRandomFile 'Experiment_3/6-07-1640'
selectRandomFile 'Experiment_3/6-08-1240'
selectRandomFile 'Experiment_3/6-09-1140'
selectRandomFile 'Experiment_3/6-09-1600'
selectRandomFile 'Experiment_3/6-13-1220'
selectRandomFile 'Experiment_3/6-13-1650'

selectRandomFile 'Experiment_4/5-25-1030'
selectRandomFile 'Experiment_4/5-26-1325' 
selectRandomFile 'Experiment_4/5-27-1255'
selectRandomFile 'Experiment_4/5-30-1040'
selectRandomFile 'Experiment_4/5-31-1030'
selectRandomFile 'Experiment_4/6-02-1140'
selectRandomFile 'Experiment_4/6-03-1240'

selectRandomFile 'Experiment_4/6-14-1025'
selectRandomFile 'Experiment_4/6-16-1325'
selectRandomFile 'Experiment_4/6-17-1135'
selectRandomFile 'Experiment_4/6-20-1035'
selectRandomFile 'Experiment_4/6-21-1240'
selectRandomFile 'Experiment_4/6-22-1050'
selectRandomFile 'Experiment_4/6-28-1150'

selectRandomFile 'Experiment_5/6-04-1235'
selectRandomFile 'Experiment_5/6-29-1105'

selectRandomFile 'Experiment_7'


