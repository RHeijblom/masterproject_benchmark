#!/bin/bash
# HARDCODED CONTROL PARAMETERS

# Flag to force each file to be checked if produced by $LTSMIN_BIN; files failing this condition will be notified to the user
CHECK_NATURE_FLAG=true

UNKNOWN_VALUE='"unknown",'
EMPTY_VALUE='"",'
OOTIME_VALUE='"ootime",'
OOMEM_VALUE='"oomem",'
ERROR_VALUE='"error",'
# Regroup is fixed during experiment and MAY not be extracted from filename
has_regroup=true

# VERIFY CORRECT USAGE

# If usage is incorrect, print script use and exit
if [ $# -lt 3 ]; then
  >&2 echo "Combines the outputfiles in a directory into a single csv file"
  >&2 echo "Usage: $0 <outputdirectory> <ltsmin_binary> <result>.csv"
  exit 1
fi

# VERIFY PROGRAM ARGUMENTS

# Validate input directory
INPUT_DIR=$1
if [ ! -d "$INPUT_DIR" ]; then
	>&2 echo "$INPUT_DIR does not exists or is not a directory."
	exit 1
fi

# Name of the binary of LTSmin used for simulation. This var determines the identification of result produced by ltsminStat
LTSMIN_BIN=$2

# Validate output_file
OUTPUT_FILE=$3
touch "$OUTPUT_FILE"
if [ $? -ne 0 ]; then
	>&2 echo "Cannot create or modify $OUTPUT_FILE."
	exit 1
fi

# Helper method to add empty values
# $1 = file which needs to be padded
# $2 = number of values which needs to be padded (optional, default 1) 
function padvalue() {
	repeat=1
	if [ $# -ge 2 ]; then
		repeat=$2
	fi
	for v in `seq 1 $repeat`; do
		>>"$1" echo -n "$EMPTY_VALUE"
	done
}

# START CSV FILE CREATION

# Print csv header
>"$OUTPUT_FILE" echo '"filename","filetype","event-span","event-span-norm","weigthed-event-span","weighted-event-span-norm",'

# Analyse all files
for file in $(find "$INPUT_DIR" -type f); do

	do_analyse_file=true
	# FILE FORMAT CHECK
	if [ CHECK_NATURE_FLAG ]; then
		echo "$file" | grep "$LTSMIN_BIN" > /dev/null
		if [ $? -ne 0 ]; then
			# File violates format
			>&2 echo "$file: violates format and is skipped for analysis." # Notify user
			do_analyse_file=false
		fi
	fi
	
	if $do_analyse_file; then
				
		# FILENAME and FILETYPE
		
		grep ": opening " "$file" > /dev/null
		if [ $? -eq 0 ]; then 
			filename=$(awk '{ if ($3 == "opening") { "basename "$4 | getline name ; printf "%s", name } }' "$file")
			# 'Magic' snatched from http://stackoverflow.com/questions/965053/extract-filename-and-extension-in-bash
			model="${filename%.*}"
			extension="${filename##*.}"
			>>"$OUTPUT_FILE" echo -n "\"$model\",\"$extension\","
		else
			# No file found
			>>"$OUTPUT_FILE" echo -n "$UNKNOWN_VALUE"
			padvalue "$OUTPUT_FILE"
		fi

		# EVENT SPAN
		
		grep "Event Span: " "$file" > /dev/null
		if [ $? -eq 0 ]; then 
			awk '{
				if ($1" "$2 == "Event Span:") printf "\"%s\",", $3
			}' "$file" >>"$OUTPUT_FILE"
		else
			padvalue "$OUTPUT_FILE"
		fi
		
		grep "Normalized Event Span: " "$file" > /dev/null
		if [ $? -eq 0 ]; then 
			awk '{
				if ($1" "$2" "$3 == "Normalized Event Span:") printf "\"%s\",", $4
			}' "$file" >>"$OUTPUT_FILE"
		else
			padvalue "$OUTPUT_FILE"
		fi
		
		# WEIGHTED EVENT SPAN
		
		grep "Weighted Event Span, " "$file" > /dev/null
		if [ $? -eq 0 ]; then 
			awk '{
				if ($1" "$2" "$3 == "Weighted Event Span,") printf "\"%s\",", $7
			}' "$file" >>"$OUTPUT_FILE"
		else
			padvalue "$OUTPUT_FILE"
		fi
		
		grep "Normalized Weighted Event Span, " "$file" > /dev/null
		if [ $? -eq 0 ]; then 
			awk '{
				if ($1" "$2" "$3" "$4 == "Normalized Weighted Event Span,") printf "\"%s\",", $7
			}' "$file" >>"$OUTPUT_FILE"
		else
			padvalue "$OUTPUT_FILE"
		fi
		
		# New line in order to finish current row
		>>"$OUTPUT_FILE" echo ""
	fi
done
