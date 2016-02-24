#!/bin/bash
# Model is written as <MODEL> = <PREFIX><NAME><SUFFIX>
# PREFIX and SUFFIX are defined in order to extract <NAME> from <MODEL>
PREFIX='/home/s1083392/experiments/in/ptAll/'
SUFFIX='.pnml'

INPUT_FILE=$1
TMP_FILE="./tmp_modelnames.txt"

if [[ -n $INPUT_FILE  && -f $INPUT_FILE ]]; then
	# Initialize temporary file to store intermediate collections
	if [[ -e $TMP_FILE ]]; then
		rm $TMP_FILE
	fi
	touch $TMP_FILE
	
	# Extract names of all models in file
	LEN_PRE=${#PREFIX}
	LEN_SUF=${#SUFFIX}
	awk '{
		# Last colums/field contains path to model
		if( substr($NF, 1, '"$LEN_PRE"') == "'"$PREFIX"'" && substr($NF, length($NF)+1-'"$LEN_SUF"', '"$LEN_SUF"') == "'"$SUFFIX"'")
			# Print name without PREFIX and SUFFIX
			print substr($NF,'"$LEN_PRE"'+1, length($NF)-'"$LEN_PRE"'-'"$LEN_SUF"')
		else
			# Model does not match; keep entire name
			print $NF
    }' "$INPUT_FILE" > "$TMP_FILE"
	
	# Sort and filter names to obtain unique set of names
	MODEL_IDS=$(sort "$TMP_FILE" | uniq | xargs)
	
	# Find and count occurrences of each model
	total=0
	totalUnique=0
	for name in $MODEL_IDS; do
		count=$(grep -r $PREFIX$name$SUFFIX $INPUT_FILE | wc -l)
		echo "$name: $count"
		total=$(($total + $count)) 
		totalUnique=$(($totalUnique + 1))
	done
	
	# Echo summary
	echo "Total number of models: $total"
	echo "Total number of unique models: $totalUnique"
	rm $TMP_FILE
else
	# Error; no suitable input file is given
	echo "No input file given to be analyzed"
	echo "Usage: $0 <file>"
fi
