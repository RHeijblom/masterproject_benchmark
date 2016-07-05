#!/bin/bash
# HARDCODED CONTROL PARAMETERS

# Flag to force each file to be checked if produced by $LTSMIN_BIN; files failing this condition will be notified to the user
CHECK_NATURE_FLAG=true

# Fixed values during testing
ADD_FIXED_PROP=false
# Header
FIXED_HEADER='"save-sat-levels","next-union",'
# Values
FIXED_VALUES='"true","false",'
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
  >&2 echo "Usage: $0 <outputdirectory> <ltsmin_binary> <result>.csv [<sat-gran>]"
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

# Use $4 as sat-granularity instead of extracting this value from the file
SAT_GRAN_VALUE=0
if [ $# -gt 3 ]; then
	SAT_GRAN_VALUE=$4
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
>"$OUTPUT_FILE" echo -n '"type","status","status-spec","order","saturation","sat-granularity",'
if $ADD_FIXED_PROP; then
	>>"$OUTPUT_FILE" echo -n "$FIXED_HEADER"
fi
>>"$OUTPUT_FILE" echo -n '"filename","filetype","regroup-strategy","regroup-time",'
>>"$OUTPUT_FILE" echo -n '"bandwidth","profile","span","average-wavefront","RMS-wavefront",'
>>"$OUTPUT_FILE" echo -n '"state-vector-length","groups","group-checks","next-state-calls","reachability-time",'
>>"$OUTPUT_FILE" echo -n '"statespace-states","statespace-nodes","group-next","group-explored-nodes","group-explored-vectors",'
>>"$OUTPUT_FILE" echo -n '"time","memory",'
>>"$OUTPUT_FILE" echo '"peak-nodes","LDDop-union","LDDop-minus","LDDop-relProd","LDDop-satCount","LDDop-satCountL","LDDop-zip","LDDop-relProdUnion","LDDop-projectMinus",'

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
		# TYPE (STATISTICS OR PERFORMANCE)
		
		type="?"
		basename $file | grep "^0__$LTSMIN_BIN" > /dev/null
		if [ $? -eq 0 ]; then
			type="\"statistics\","
		else
			type="\"performance\"," # May falsely mark files as PERFORMANCE if CHECK_NATURE_FLAG is false 
		fi
		>>"$OUTPUT_FILE" echo -n "$type"
		
		# STATUS and STATUS-SPEC
		
		has_found_status=false
		status="?"
		status_spec="?"
		# Common cases
		# Check Exit[0]
		grep "Exit \[0\]" "$file" > /dev/null
		if [ $? -eq 0 ]; then 
			status="\"done\","
			status_spec="\"\","
			has_found_status=true
		fi
		# Check Killed[24]
		if ! $has_found_status; then
			grep "Killed \[24\]" "$file" > /dev/null
			if [ $? -eq 0 ]; then 
				status=$OOTIME_VALUE
				grep "Regrouping took" "$file" > /dev/null
				if [ $? -eq 0 ]; then
					status_spec="\"explore\","
				else
					status_spec="\"regroup\","
				fi
				has_found_status=true
				
			fi
		fi
		# Uncommon cases
		# Check Exit[1]
		if ! $has_found_status; then
			grep "Exit \[1\]" "$file" > /dev/null
			if [ $? -eq 0 ]; then 
				status=$OOMEM_VALUE
				grep "cache: Unable to allocate memory!" "$file" > /dev/null # LEGACY?
				if [ $? -eq 0 ]; then 
					status_spec="\"cache\","
					has_found_status=true
				fi
				if ! $has_found_status; then # Prevents chaining if else statements
					grep "MDD Unique table full" "$file" > /dev/null
					if [ $? -eq 0 ]; then 
						status_spec="\"mddtable\","
						has_found_status=true
					fi
				fi
				if ! $has_found_status; then # Prevents chaining if else statements
					grep "Unable to allocate memory: Cannot allocate memory!" "$file" > /dev/null
					if [ $? -eq 0 ]; then 
						status_spec="\"alloc\","
						has_found_status=true
					fi
				fi
			fi
		fi
		# Check Exit[255]
		if ! $has_found_status; then
			grep "Exit \[255\]" "$file" > /dev/null
			if [ $? -eq 0 ]; then 
				grep "\*\* error \*\*: Got invalid permutation from boost." "$file" > /dev/null
				if [ $? -eq 0 ]; then 
					status=$ERROR_VALUE
					status_spec="\"boostperm\","
					has_found_status=true
				fi
				if ! $has_found_status; then # Prevents chaining if else statements
					grep "*\* error \*\*: missing place" "$file" > /dev/null
					if [ $? -eq 0 ]; then 
						status=$ERROR_VALUE
						status_spec="\"badmodel\","
						has_found_status=true
					fi
				fi
				if ! $has_found_status; then # Prevents chaining if else statements
					grep "*\* error \*\*: out of memory trying to get" "$file" > /dev/null
					if [ $? -eq 0 ]; then 
						status=$OOMEM_VALUE
						status_spec="\"regroup\","
						has_found_status=true
					fi
				fi
				if ! $has_found_status; then # Prevents chaining if else statements
					grep "Please send information on how to reproduce this problem to:" "$file" > /dev/null
					if [ $? -eq 0 ]; then 
						status=$ERROR_VALUE
						status_spec="\"sigsegfault\","
						has_found_status=true
					fi
				fi
			fi
		fi
		# Check Killed[6]
		if ! $has_found_status; then
			grep "Killed \[6\]" "$file" > /dev/null
			if [ $? -eq 0 ]; then 
				status=$ERROR_VALUE
				grep "lddmc_makenode: Assertion" "$file" > /dev/null
				if [ $? -eq 0 ]; then
					status_spec="\"makenode\","
					has_found_status=true
				fi
				if ! $has_found_status; then
					grep "lddmc_relprod_WORK: Assertion" "$file" > /dev/null
					if [ $? -eq 0 ]; then
						status_spec="\"relprodwork\","
						has_found_status=true
					fi
				fi
				if ! $has_found_status; then
					grep "lddmc_union_WORK: Assertion" "$file" > /dev/null
					if [ $? -eq 0 ]; then
						status_spec="\"unionwork\","
						has_found_status=true
					fi
				fi
			fi
		fi
		# Check Killed[9]
		if ! $has_found_status; then
			grep "Killed \[9\]" "$file" > /dev/null
			if [ $? -eq 0 ]; then 
				status=$OOTIME_VALUE
				status_spec="\"killed9\","
				has_found_status=true
			fi
		fi
		# Check Killed[11]
		if ! $has_found_status; then
			grep "Killed \[11\]" "$file" > /dev/null
			if [ $? -eq 0 ]; then 
				status=$ERROR_VALUE
				grep "Please send information on how to reproduce this problem to:" "$file" > /dev/null
				if [ $? -eq 0 ]; then
					status_spec="\"sigsegfault\","
					has_found_status=true
				else
					status_spec="\"\","
				fi
				has_found_status=true
			fi
		fi
		# Check Killed[15]
		if ! $has_found_status; then
			grep "Killed \[15\]" "$file" > /dev/null
			if [ $? -eq 0 ]; then 
				status=$OOTIME_VALUE
				status_spec="\"killed15\","
				has_found_status=true
			fi
		fi
		# No response; check last line
		# Check last line during regrouping
		if ! $has_found_status; then
			tail -n1 "$file" | grep "Regroup Boost's Sloan\|: bandwidth:\|: profile:\|: span:\|: average wavefront:\|: RMS wavefront:\|: Regrouping:" > /dev/null
			if [ $? -eq 0 ]; then 
				status=$OOTIME_VALUE
				status_spec="\"regroup\","
				has_memstats=false
				has_found_status=true
			fi
		fi
		# Check last line during initialisation of symbolic backend
		if ! $has_found_status; then
			tail -n1 "$file" | grep "Creating a multi-core ListDD domain.\|Using GBgetTransitionsShortR2W as next-state function\|got initial state\|vrel_add_act not supported; falling back to vrel_add_cpy" > /dev/null
			if [ $? -eq 0 ]; then 
				status=$OOTIME_VALUE
				status_spec="\"explore\","
				has_memstats=false
				has_found_status=true
			fi
		fi
		# Last resort: use dummy value
		if ! $has_found_status; then
			>&2 echo "$file: could not determine a status." # Notify user
			status=$UNKNOWN_VALUE
			status_spec=$UNKNOWN_VALUE
		fi
		>>"$OUTPUT_FILE" echo -n "$status$status_spec"
		
		# ORDER
		
		grep ": Exploration order is " "$file" > /dev/null
		if [ $? -eq 0 ]; then 
			awk '{
				if ($3" "$4" "$5 == "Exploration order is") printf "\"%s\",", $6
    		}' "$file" >>"$OUTPUT_FILE"
		else
			>>"$OUTPUT_FILE" echo -n "$UNKNOWN_VALUE"
		fi
		
		# SATURATION
		
		grep ": Saturation strategy is " "$file" > /dev/null
		if [ $? -eq 0 ]; then 
			awk '{
				if ($3" "$4" "$5 == "Saturation strategy is") printf "\"%s\",", $6
    		}' "$file" >>"$OUTPUT_FILE"
		else
			>>"$OUTPUT_FILE" echo -n "$UNKNOWN_VALUE"
		fi
		
		# SAT-GRANULARITY
		
		if [ $SAT_GRAN_VALUE -eq 0 ]; then
			# Read sat-granularity from file name
			basename "$file" | grep "\-\-sat\-granularity=" > /dev/null
			if [ $? -eq 0 ]; then
				sat=$(basename "$file" | grep -o "\-\-sat\-granularity=[[:digit:]]*")
				sat="${sat##*=}"
				>>"$OUTPUT_FILE" echo -n "\"$sat\","
			else
				>>"$OUTPUT_FILE" echo -n "$EMPTY_VALUE"
			fi
		else
			# Use given fixed value for sat-granularity
			>>"$OUTPUT_FILE" echo -n "\"$SAT_GRAN_VALUE\","
		fi
		
		# FIXED VALUES
		
		if $ADD_FIXED_PROP; then
			>>"$OUTPUT_FILE" echo -n "$FIXED_VALUES"
		fi
		
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
		
		# REGROUP-STRATEGY
		
		has_regroup=false
		grep ": Regroup specification: " "$file" > /dev/null
		if [ $? -eq 0 ]; then 
			awk '{
				if ($3" "$4 == "Regroup specification:") printf "\"%s\",", $5
			}' "$file" >>"$OUTPUT_FILE"
			has_regroup=true
		else
			# No regroup strategy
			padvalue "$OUTPUT_FILE"
		fi
		
		# REGROUP TIME
		
		if $has_regroup; then
			grep ": Regrouping took " "$file" > /dev/null
			if [ $? -eq 0 ]; then 
				awk '{
					if ($3" "$4 == "Regrouping took") printf "\"%s\",", $7
				}' "$file" >>"$OUTPUT_FILE"
			else
				# No regroup time
				padvalue "$OUTPUT_FILE"
			fi
		else
			# Regroup time cannot exist
			padvalue "$OUTPUT_FILE"
		fi
			
		# REGROUP STATISTICS
		
		basename $file | grep "\-\-graph\-metrics" > /dev/null
		if [ $? -eq 0 ]; then
			# Regroup stats may be present; not guaranteed if run stopped responding
			# BANDWIDTH
			grep ": bandwidth: " "$file" > /dev/null
			if [ $? -eq 0 ]; then 
				awk '{
					if ($3 == "bandwidth:") printf "\"%s\",", $4
				}' "$file" >>"$OUTPUT_FILE"
			else
				padvalue "$OUTPUT_FILE"
			fi
			# PROFILE
			grep ": profile: " "$file" > /dev/null
			if [ $? -eq 0 ]; then 
				awk '{
					if ($3 == "profile:") printf "\"%s\",", $4
				}' "$file" >>"$OUTPUT_FILE"
			else
				padvalue "$OUTPUT_FILE"
			fi
			# SPAN
			grep ": span: " "$file" > /dev/null
			if [ $? -eq 0 ]; then 
				awk '{
					if ($3 == "span:") printf "\"%s\",", $4
				}' "$file" >>"$OUTPUT_FILE"
			else
				padvalue "$OUTPUT_FILE"
			fi
			# AVERAGE WAVEFRONT
			grep ": average wavefront: " "$file" > /dev/null
			if [ $? -eq 0 ]; then 
				awk '{
					if ($3" "$4 == "average wavefront:") printf "\"%s\",", $5
				}' "$file" >>"$OUTPUT_FILE"
			else
				padvalue "$OUTPUT_FILE"
			fi
			# RMS WAVEFRONT
			grep ": RMS wavefront: " "$file" > /dev/null
			if [ $? -eq 0 ]; then 
				awk '{
					if ($3" "$4 == "RMS wavefront:") printf "\"%s\",", $5
				}' "$file" >>"$OUTPUT_FILE"
			else
				padvalue "$OUTPUT_FILE"
			fi
		else
			# No regroup statistics
			padvalue "$OUTPUT_FILE" 5
		fi
		
		# STATE-VECTOR-LENGTH and GROUPS
		
		grep ": state vector length is " "$file" > /dev/null
		if [ $? -eq 0 ]; then 
			awk '{
				if ($3" "$4" "$5" "$6 == "state vector length is") printf "\"%s\",\"%s\",", substr($7, 1, length($7)-1), $10
			}' "$file" >>"$OUTPUT_FILE"
		else
			# No dependency matrix size
			padvalue "$OUTPUT_FILE" 2
		fi
		
		# GROUP-CHECKS and NEXT-STATE-CALLS
		
		grep ": Exploration took " "$file" > /dev/null
		if [ $? -eq 0 ]; then 
			awk '{
				if ($3" "$4 == "Exploration took") printf "\"%s\",\"%s\",", $5, $9
			}' "$file" >>"$OUTPUT_FILE"
		else
			padvalue "$OUTPUT_FILE" 2
		fi
		
		# REACHABILITY-TIME
		
		grep ": reachability took " "$file" > /dev/null
		if [ $? -eq 0 ]; then 
			awk '{
				if ($3" "$4 == "reachability took") printf "\"%s\",", $7
			}' "$file" >>"$OUTPUT_FILE"
		else
			padvalue "$OUTPUT_FILE"
		fi
		
		# STATESPACE-STATES and -NODES
		
		grep ": state space has " "$file" > /dev/null
		if [ $? -eq 0 ]; then 
			awk '{
				if ($3" "$4" "$5 == "state space has") printf "\"%s\",\"%s\",", $6, $8
			}' "$file" >>"$OUTPUT_FILE"
		else
			padvalue "$OUTPUT_FILE" 2
		fi
		
		# GROUP-NEXT
		
		grep ": group_next: " "$file" > /dev/null
		if [ $? -eq 0 ]; then 
			awk '{
				if ($3 == "group_next:") printf "\"%s\",", $4
			}' "$file" >>"$OUTPUT_FILE"
		else
			padvalue "$OUTPUT_FILE"
		fi
		
		# GROUP-EXPLORED-NODES and -VECTORS
		
		grep ": group_explored: " "$file" > /dev/null
		if [ $? -eq 0 ]; then 
			awk '{
				if ($3 == "group_explored:") printf "\"%s\",\"%s\",", $4, $6
			}' "$file" >>"$OUTPUT_FILE"
		else
			padvalue "$OUTPUT_FILE" 2
		fi
		
		# MEMTIME STATISTICS
		
		cat "$file" | tail -n1 | grep " elapsed -- Max VSize = " > /dev/null
		if [ $? -eq 0 ]; then
			awk '{
				# RUNTIME and MEMORY FOOTPRINT
				if ($2 == "user," && $4 == "system," && $6 == "elapsed") printf "\"%s\",\"%s\",", $1, substr($15, 1, length($15) - 2)
	    	}' "$file" >>"$OUTPUT_FILE"
		else
			padvalue "$OUTPUT_FILE" 2
		fi
		
		# PEAK-NODES
		
		grep " final BDD nodes; " "$file" > /dev/null
		if [ $? -eq 0 ]; then 
			awk '{
				if ($5" "$6" "$7 == "final BDD nodes;" && $9" "$10 == "peak nodes;") printf "\"%s\",", $8
			}' "$file" >>"$OUTPUT_FILE"
		else
			padvalue "$OUTPUT_FILE"
		fi
		
		# SYLVAN STATISTICS
		
		grep "LDD operations count (cache reuse, cache put)" "$file" > /dev/null
		if [ $? -eq 0 ]; then 
			# UNION
			grep "Union: " "$file" > /dev/null
			if [ $? -eq 0 ]; then 
				awk '{
					if ($1 == "Union:") printf "\"%s\",",  $2
				}' "$file" >>"$OUTPUT_FILE"
			else
				padvalue "$OUTPUT_FILE"
			fi
			# MINUS
			grep "Minus: " "$file" > /dev/null
			if [ $? -eq 0 ]; then 
				awk '{
					if ($1 == "Minus:") printf "\"%s\",",  $2
				}' "$file" >>"$OUTPUT_FILE"
			else
				padvalue "$OUTPUT_FILE"
			fi
			# RELPROD
			grep "RelProd: " "$file" > /dev/null
			if [ $? -eq 0 ]; then 
				awk '{
					if ($1 == "RelProd:") printf "\"%s\",",  $2
				}' "$file" >>"$OUTPUT_FILE"
			else
				padvalue "$OUTPUT_FILE"
			fi
			# SATCOUNT
			grep "SatCount: " "$file" > /dev/null
			if [ $? -eq 0 ]; then 
				awk '{
					if ($1 == "SatCount:") printf "\"%s\",",  $2
				}' "$file" >>"$OUTPUT_FILE"
			else
				padvalue "$OUTPUT_FILE"
			fi
			# SATCOUNTL
			grep "SatCountL: " "$file" > /dev/null
			if [ $? -eq 0 ]; then 
				awk '{
					if ($1 == "SatCountL:") printf "\"%s\",",  $2
				}' "$file" >>"$OUTPUT_FILE"
			else
				padvalue "$OUTPUT_FILE"
			fi
			# ZIP
			grep "Zip: " "$file" > /dev/null
			if [ $? -eq 0 ]; then 
				awk '{
					if ($1 == "Zip:") printf "\"%s\",",  $2
				}' "$file" >>"$OUTPUT_FILE"
			else
				padvalue "$OUTPUT_FILE"
			fi
			# RELPRODUNION
			grep "RelProdUnion: " "$file" > /dev/null
			if [ $? -eq 0 ]; then 
				awk '{
					if ($1 == "RelProdUnion:") printf "\"%s\",",  $2
				}' "$file" >>"$OUTPUT_FILE"
			else
				padvalue "$OUTPUT_FILE"
			fi
			# POJECTMINUS
			grep "ProjectMinus: " "$file" > /dev/null
			if [ $? -eq 0 ]; then 
				awk '{
					if ($1 == "ProjectMinus:") printf "\"%s\",",  $2
				}' "$file" >>"$OUTPUT_FILE"
			else
				padvalue "$OUTPUT_FILE"
			fi
		else
			padvalue "$OUTPUT_FILE" 7
		fi
		
		# New line in order to finish current row
		>>"$OUTPUT_FILE" echo ""
	fi
done
