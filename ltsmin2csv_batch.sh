#!/bin/bash
pwd=$(pwd)
# Perform a single run with ltsmin2csv.sh
# $1 = directory
# $2 = ltsmin binary
# $3 = name of output.
# $4 = sat-granularity (optional)
function parse() {
	input="$pwd/$1/out/"
	output="$pwd/$1/$3.csv"
	echo ""
	date '+"%T"'
	echo "Start parsing \"$pwd/$1/\"..."
	if [ $# -ge 4 ]; then
		./ltsmin2csv.sh "$input" $2 "$output" $4
	else 
		./ltsmin2csv.sh "$input" $2 "$output"
	fi
	echo "Finished parsing \"$pwd/$1/\"."
}

date '+"%T"'
echo 'Start processing batches...'
# Batches
parse 'Runs/Experiment_3/5-11-1125' 'pnml2lts-sym' 'result-p1' 1
parse 'Runs/Experiment_3/5-12-1045' 'pnml2lts-sym' 'result-p5' 5
parse 'Runs/Experiment_3/5-17-1505' 'pnml2lts-sym' 'result-p10' 10
parse 'Runs/Experiment_3/5-18-1345' 'pnml2lts-sym' 'result-p20' 20
parse 'Runs/Experiment_3/5-19-1245' 'pnml2lts-sym' 'result-p40' 40
parse 'Runs/Experiment_3/5-23-1235' 'pnml2lts-sym' 'result-p80' 80
parse 'Runs/Experiment_3/5-24-1030' 'pnml2lts-sym' 'result-pmax' 'max-int'

parse 'Runs/Experiment_3/6-07-1030' 'dve2lts-sym' 'result-d1' 1
parse 'Runs/Experiment_3/6-07-1640' 'dve2lts-sym' 'result-d5' 5
parse 'Runs/Experiment_3/6-08-1240' 'dve2lts-sym' 'result-d10' 10
parse 'Runs/Experiment_3/6-09-1140' 'dve2lts-sym' 'result-d20' 20
parse 'Runs/Experiment_3/6-09-1600' 'dve2lts-sym' 'result-d40' 40
parse 'Runs/Experiment_3/6-13-1220' 'dve2lts-sym' 'result-d80' 80
parse 'Runs/Experiment_3/6-13-1650' 'dve2lts-sym' 'result-dmax' 'max-int'

parse 'Runs/Experiment_4/5-25-1030' 'pnml2lts-sym' 'result-p1' 1
parse 'Runs/Experiment_4/5-26-1325' 'pnml2lts-sym' 'result-p5' 5
parse 'Runs/Experiment_4/5-27-1255' 'pnml2lts-sym' 'result-p10' 10
parse 'Runs/Experiment_4/5-30-1040' 'pnml2lts-sym' 'result-p20' 20
parse 'Runs/Experiment_4/5-31-1030' 'pnml2lts-sym' 'result-p40' 40
parse 'Runs/Experiment_4/6-02-1140' 'pnml2lts-sym' 'result-p80' 80
parse 'Runs/Experiment_4/6-03-1240' 'pnml2lts-sym' 'result-pmax' 'max-int'

parse 'Runs/Experiment_4/6-14-1025' 'dve2lts-sym' 'result-d1' 1
parse 'Runs/Experiment_4/6-16-1325' 'dve2lts-sym' 'result-d5' 5
parse 'Runs/Experiment_4/6-17-1135' 'dve2lts-sym' 'result-d10' 10
parse 'Runs/Experiment_4/6-20-1035' 'dve2lts-sym' 'result-d20' 20
parse 'Runs/Experiment_4/6-21-1240' 'dve2lts-sym' 'result-d40' 40
parse 'Runs/Experiment_4/6-22-1050' 'dve2lts-sym' 'result-d80' 80
parse 'Runs/Experiment_4/6-28-1150' 'dve2lts-sym' 'result-dmax' 'max-int'

parse 'Runs/Experiment_5/6-04-1235' 'pnml2lts-sym' 'result-pnone'
parse 'Runs/Experiment_5/6-29-1105' 'dve2lts-sym' 'result-dnone'

parse 'Runs/Experiment_6' 'pnml2lts-sym' 'result-pmix'

echo ""
date '+"%T"'
echo "Finished processing all batches."
