#!/bin/bash
# Name of the binary of LTSmin used for simulation. This var determines the identification of result produced by ltsminStat
LTSMIN_BIN="pnml2lts-sym"

# Flag to force each file to be checked if produced by $LTSMIN_BIN; files failing this condition will be notified to the user
CHECK_NATURE_FLAG=true

# Fixed values during testing
# Header
FIXED_HEADER='"sat-granularity","save-sat-levels","next-union",'
# Values
FIXED_VALUES='"40","true","true",'
# Regroup is fixed during experiment and MAY not be extracted from filename
has_regroup=true

# If usage is incorrect, print script use and exit
if [ "$#" -ne 2 ]; then
  >&2 echo "Combines the outputfiles in a directory into a single csv file"
  >&2 echo "Usage: $0 <outputdirectory> <result>.csv"
  exit 1
fi

# Validate input directory
INPUT_DIR=$1
if [ ! -d "$INPUT_DIR" ]; then
	>&2 echo "$INPUT_DIR does not exists or is not a directory."
	exit 1
fi

# Validate output_file
OUTPUT_FILE=$2
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
		>>"$1" echo -n "\"\","
	done
}

# Print csv header
>"$OUTPUT_FILE" echo -n '"type","status","status-spec","order","saturation",'
>>"$OUTPUT_FILE" echo -n "$FIXED_HEADER"
>>"$OUTPUT_FILE" echo -n '"filename","PT-places","PT-transitions","PT-arcs","PT-safeplaces","regroup-strategy","regroup-time",'
>>"$OUTPUT_FILE" echo -n '"state_vector_length","groups","group-checks","next-state-calls","reachability-time",'
>>"$OUTPUT_FILE" echo -n '"statespace-states","statespace-nodes","group-next","group-explored-nodes","group-explored-vectors",'
>>"$OUTPUT_FILE" echo -n '"time","memory",'
>>"$OUTPUT_FILE" echo '"peak-nodes","BDD-relProd","BDD-satCount","BDD-satCountL","BDD-relProdUnion","BDD-projectMinus"'

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
		# Bookkeeping vars to indicate which information is available in the file
		has_memstats=true
		has_sylvanstat=false
		# 1 - Till safe places (failure parsing PT)
		# 2 - Till regroup (failure during regrouping; regroup strategy is known)
		# 3 - Till reachability analysis (model cannot be solved, but statespace definition is made)
		# 4 - Model is succesfully analyzed
		info_reachability=0
	
		# TYPE (STATISTICS OR PERFORMANCE)
		type="?"
		basename $file | grep "^0__$LTSMIN_BIN" > /dev/null
		if [ $? -eq 0 ]; then
			type="\"statistics\","
			has_sylvanstat=true
		else
			type="\"performance\"," # May falsely mark files as PERFORMANCE if CHECK_NATURE_FLAG is false 
			has_sylvanstat=false
		fi
		>>"$OUTPUT_FILE" echo -n "$type"
		
		# Determine status
		has_found_status=false
		status="?"
		status_spec="?"
		# Common cases
		# Check Exit[0]
		grep "Exit \[0\]" "$file" > /dev/null
		if [ $? -eq 0 ]; then 
			status="\"done\","
			status_spec="\"\","
			info_reachability=4
			has_found_status=true
		fi
		# Check Killed[24]
		if ! $has_found_status; then
			grep "Killed \[24\]" "$file" > /dev/null
			if [ $? -eq 0 ]; then 
				status="\"ootime\","
				grep "Regrouping took" "$file" > /dev/null
				if [ $? -eq 0 ]; then
					status_spec="\"explore\","
					info_reachability=3
				else
					status_spec="\"regroup\","
					info_reachability=2
				fi
				has_found_status=true
				
			fi
		fi
		# Uncommon cases
		# Check Exit[1]
		if ! $has_found_status; then
			grep "Exit \[1\]" "$file" > /dev/null
			if [ $? -eq 0 ]; then 
				grep "cache: Unable to allocate memory!" "$file" > /dev/null
				if [ $? -eq 0 ]; then 
					status="\"oomem\","
					status_spec="\"cache\","
					info_reachability=3
					has_found_status=true
				fi
				if ! $has_found_status; then
					grep "MDD Unique table full" "$file" > /dev/null
					if [ $? -eq 0 ]; then 
						status="\"oomem\","
						status_spec="\"mddtable\","
						info_reachability=3
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
					status="\"error\","
					status_spec="\"boostperm\","
					info_reachability=2
					has_found_status=true
				fi
				if ! $has_found_status; then
					grep "*\* error \*\*: missing place" "$file" > /dev/null
					if [ $? -eq 0 ]; then 
						status="\"error\","
						status_spec="\"badmodel\","
						info_reachability=1
						has_found_status=true
					fi
				fi
				if ! $has_found_status; then
					grep "*\* error \*\*: out of memory trying to get" "$file" > /dev/null
					if [ $? -eq 0 ]; then 
						status="\"oomem\","
						status_spec="\"regroup\","
						info_reachability=2
						has_found_status=true
					fi
				fi
				if ! $has_found_status; then
					grep "Please send information on how to reproduce this problem to:" "$file" > /dev/null
					if [ $? -eq 0 ]; then 
						status="\"sigsegfault\","
						status_spec="\"sendinfo\","
						info_reachability=3
						has_found_status=true
					fi
				fi
			fi
		fi
		# Check Killed[6]
		if ! $has_found_status; then
			grep "Killed \[6\]" "$file" > /dev/null
			if [ $? -eq 0 ]; then 
				grep "lddmc_makenode: Assertion" "$file" > /dev/null
				if [ $? -eq 0 ]; then
					status="\"runerror\","
					status_spec="\"makenode\","
					has_found_status=true
				fi
				if ! $has_found_status; then
					grep "lddmc_relprod_WORK: Assertion" "$file" > /dev/null
					if [ $? -eq 0 ]; then 
						status="\"runerror\","
						status_spec="\"relprodwork\","
						has_found_status=true
					fi
				fi
				if ! $has_found_status; then
					grep "lddmc_union_WORK: Assertion" "$file" > /dev/null
					if [ $? -eq 0 ]; then 
						status="\"runerror\","
						status_spec="\"unionwork\","
						has_found_status=true
					fi
				fi
				info_reachability=3
			fi
		fi
		# Check Killed[11]
		if ! $has_found_status; then
			grep "Killed \[11\]" "$file" > /dev/null
			if [ $? -eq 0 ]; then 
				status="\"sigsegfault\","
				grep "Please send information on how to reproduce this problem to:" "$file" > /dev/null
				if [ $? -eq 0 ]; then
					status_spec="\"sendinfo\","
					info_reachability=2
				else
					status_spec="\"\","
					info_reachability=3
				fi
				has_found_status=true
			fi
		fi
		# Check last line "vrel_add_act not supported; falling back to vrel_add_cpy"
		if ! $has_found_status; then
			tail -n1 "$file" | grep "vrel_add_act not supported; falling back to vrel_add_cpy" > /dev/null
			if [ $? -eq 0 ]; then 
				status="\"ootime\","
				status_spec="\"noresponse\","
				has_memstats=false
				info_reachability=3
				has_found_status=true
			fi
		fi
		# Last resort: use dummy value
		if ! $has_found_status; then
			>&2 echo "$file: could not determine a status." # Notify user
			status="\"unknown\","
			status_spec="\"\","
		fi
		>>"$OUTPUT_FILE" echo -n "$status$status_spec"
		
		# INFO REACHABILITY >= 1
		
		awk '{
			# ORDER
			if ($3" "$4" "$5 == "Exploration order is") printf "\"%s\",", $6
			# SATURATION
			else if ($3" "$4" "$5 == "Saturation strategy is") printf "\"%s\",", $6
    	}' "$file" >>"$OUTPUT_FILE"
		
		# Fixed values during testing which CANNOT be extracted from the outputfiles
		>>"$OUTPUT_FILE" echo -n "$FIXED_VALUES"
		
		awk '{
			# FILENAME
			if ($3 == "opening") { "basename "$4 | getline name ; printf "\"%s\",", name }
			# PETRI NET (PLACES, TRANSITIONS, ARCS)
			else if ($3" "$4" "$5 == "Petri net has" && $7 == "places," && $9 == "transitions" && $12 == "arcs") printf "\"%s\",\"%s\",\"%s\",", $6, $8, $11
    	}' "$file" >>"$OUTPUT_FILE"
		
		# INFO REACHABILITY >= 2
		
		# Extract if regroup is used from file name
		# echo "$file" | grep "\-\-r" > /dev/null
		# has_regroup=true `[ "$?" -eq 0 ]` 
		
		if [ $info_reachability -ge 2 ]; then
			awk '{
				# PETRI NET (SAFE PLACES)
				if ($3" "$4 == "There are" && $6" "$7 == "safe places") printf "\"%s\",", $5
    		}' "$file" >>"$OUTPUT_FILE"
			# REGROUP STRATEGY
			if $has_regroup; then
				awk '{
					if ($3" "$4 == "Regroup specification:") printf "\"%s\",", $5
				}' "$file" >>"$OUTPUT_FILE"
			else
				>>"$OUTPUT_FILE" echo -n "\"none\","
			fi
		else
			# Pad missing info
			padvalue "$OUTPUT_FILE" 2
		fi
		
		# INFO REACHABILITY >= 3
		
		if [ $info_reachability -ge 3 ]; then
			# REGROUP TIME
			if $has_regroup; then
				awk '{
					if ($3" "$4 == "Regrouping took") printf "\"%s\",", $7
				}' "$file" >>"$OUTPUT_FILE"
			else
				# Regroup time cannot exist
				padvalue "$OUTPUT_FILE"
			fi
			awk '{
				# STATE VECTOR LENGTH and GROUPS
				if ($3" "$4" "$5" "$6 == "state vector length is") printf "\"%s\",\"%s\",", substr($7, 1, length($7)-1), $10
			}' "$file" >>"$OUTPUT_FILE"
		else
			# Pad missing info
			padvalue "$OUTPUT_FILE" 3
		fi
		
		# INFO REACHABILITY >= 4
		
		if [ $info_reachability -ge 4 ]; then
			awk '{
				# GROUP CHECKS and NEXT STATE CALLS
				if ($3" "$4 == "Exploration took") printf "\"%s\",\"%s\",", $5, $9
				# REACHABILITY TIME
				else if ($3" "$4 == "reachability took") printf "\"%s\",", $7
				# STATESPACE STATES and NODES
				else if ($3" "$4" "$5 == "state space has") printf "\"%s\",\"%s\",", $6, $8
				# GROUP NEXT
				else if ($3 == "group_next:") printf "\"%s\",", $4
				# GROUP EXPLORED NODES and VECTORS
				else if ($3 == "group_explored:") printf "\"%s\",\"%s\",", $4, $6
	    	}' "$file" >>"$OUTPUT_FILE"
		else
			padvalue "$OUTPUT_FILE" 8
		fi
		
		# MEMTIME STATISTICS
		
		if $has_memstats; then
			awk '{
				# RUNTIME and MEMORY FOOTPRINT
				if ($2 == "user," && $4 == "system," && $6 == "elapsed") printf "\"%s\",\"%s\",", $1, substr($15, 1, length($15) - 2)
	    	}' "$file" >>"$OUTPUT_FILE"
		else
			padvalue "$OUTPUT_FILE" 2
		fi
		
		# SYLVAN STATISTICS
		
		if $has_sylvanstats && [ $info_reachability -ge 4 ]; then
			awk '{
				# PEAKNODES
				if ($5" "$6" "$7 == "final BDD nodes;") printf "\"%s\",", $8
				# BDD OPERATIONS (rel prod, sat count, sat count l, rel prod union, project minus)
				else if ($1 == "RelProd:") printf "\"%s\",",  $2
				else if ($1 == "SatCount:") printf "\"%s\",",  $2
				else if ($1 == "SatCountL:") printf "\"%s\",",  $2
				else if ($1 == "RelProdUnion:") printf "\"%s\",",  $2
				else if ($1 == "ProjectMinus:") printf "\"%s\",",  $2
	    	}' "$file" >>"$OUTPUT_FILE"
		else
			padvalue "$OUTPUT_FILE" 6
		fi
		
		# New line
		>>"$OUTPUT_FILE" echo ""
	fi
done
