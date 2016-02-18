#!/bin/bash
# Name of the binary of LTSmin used for simulation. This var determines the identification of result produced by ltsminStat
LTSMIN_BIN="pmnl2lts-sym"

num_files=0
REDO=""

if [ "$#" -ne 1 ]; then
  >&2 echo "Usage: $0 <outputdirectory> > <result.csv>"
  exit 1
fi

echo '"type","status","order","saturation","filename","regroup","regroup_time","write_event_span","write_norm_event_span","write_weighted_event_span","read_event_span","read_norm_event_span","read_weighted_event_span","combined_event_span","combined_norm_event_span","combined_weighted_event_span","bandwidth","profile","span","avg_wavefront","RMS_wavefront","state_length","groups","group_checks","nextstate_calls","reach_time","states","state_nodes","group_nodes","group_explored_nodes","group_explored_states","time","RSS","peak_nodes",'

for i in $(find $1 -type f); do
	
	echo $i | grep "0__$LTSMIN_BIN" > /dev/null
	if [ $? -eq 0 ]; then
		echo -n "\"statistics\","
	else
		echo -n "\"performance\","
	fi
    
    grep "\*\*\* segmentation fault \*\*\*" $i > /dev/null
    if [ $? -eq 0 ]; then
        echo -n '"segfault",'
    else 
        grep "\*\* error \*\*" $i > /dev/null
        if [ $? -eq 0 ]; then
            echo -n '"error",'
        else
            grep "Killed \[24\]" $i > /dev/null
            if [ $? -eq 0 ]; then
                echo -n '"oot",'
            else
                grep "Exit \[0\]" $i > /dev/null
                if [ $? -eq 0 ]; then
                    echo -n '"done",'
                else
                    grep "MDD Unique table full" $i > /dev/null
                    if [ $? -eq 0 ]; then
                        echo -n '"oom",'
                    else
                        tail -n1 "$i" | grep "vrel_add_act not supported; falling back to vrel_add_cpy" > /dev/null
                        if [ $? -eq 0 ]; then
                            echo -n '"oot",'
                        else
                            grep "Killed \[11\]" $i > /dev/null
                            if [ $? -eq 0 ]; then
                                echo -n '"sigsegfault",'
                            else
                                grep "Killed \[9\]" $i >> /dev/null
                                if [ $? -eq 0 ]; then
                                    echo -n '"oot",'
                                else
                                    tail -n1 "$i" | grep "Regroup " > /dev/null
                                    if [ $? -eq 0 ]; then
                                        echo -n '"tolarge",'
                                    else 
                                        tail -n1 "$i" | grep "loading model PNML" > /dev/null
                                        if [ $? -eq 0 ]; then
                                            echo -n '"tolarge",'
                                        else    
	                                        grep "Lace error: Unable to allocate memory for the Lace worker!\|: out of memory" $i > /dev/null
	                                        if [ $? -eq 0 ]; then
	                                            >&2 echo "$(basename $i) failed, continuing..."
	                                            echo '"redo",'
	                                            REDO+="$i"
	                                            REDO+=$'\n'
	                                            continue
	                                        else
                                                grep "Killed \[15\]" $i >> /dev/null
                                                if [ $? -eq 0 ]; then
                                                    echo -n '"oot",'
                                                else  
                                                    grep "cache: Unable to allocate memory!" $i >> /dev/null
                                                    if [ $? -eq 0 ]; then
                                                        echo -n '"tolarge",'
                                                    else  
	                                                    tail -n1 "$i" | grep "Creating a multi-core ListDD domain." > /dev/null
	                                                    if [ $? -eq 0 ]; then
	                                                        echo -n '"tolarge",'
	                                                    else 
		                                                    grep "Unable to allocate memory!" $i >> /dev/null
		                                                    if [ $? -eq 0 ]; then
		                                                        echo -n '"tolarge",'
		                                                    else      
			                                                    tail -n1 "$i" | grep "wavefront:\|span:\|profile:\|bandwidth:\|: Regrouping:\|counting visited states" > /dev/null
			                                                    if [ $? -eq 0 ]; then
			                                                        echo -n '"tolarge",'
			                                                    else         
											                        >&2 echo "I don't know what to do with file $i"
											                        exit 1
										                    	fi
										                    fi
									                    fi
							                        fi
							                    fi
						                    fi
					                    fi
				                    fi
			                    fi
		                    fi
	                    fi
                    fi
                fi
            fi                
        fi
    fi
    
    awk '{
		if ($3" "$4" "$5 == "Exploration order is") printf "\"%s\",", $6
		else if ($3" "$4" "$5 == "Saturation strategy is") printf "\"%s\",", $6
		else if ($3 == "opening") { "basename "$4 | getline name ; printf "\"%s\",", name }
    }' $i

	echo $i | grep "\-\-r" > /dev/null
	
	if [ $? -eq 0 ]; then
		awk '{
			if ($3" "$4 == "Regroup specification:") printf "\"%s\",", $5
			else if ($3" "$4 == "Regrouping took") printf "\"%s\",", $7
    	}' $i
	else
		echo -n "\"none\",\"0\","
	fi
	
	echo $i | grep "0__$LTSMIN_BIN" > /dev/null
	is_stat=$?
	has_printed=$(grep "Weighted Event Span" $i | wc -l)	
	
	if [ $is_stat -eq 0 -a $has_printed -eq 3 ]; then
		# stats for asymmetric matrices
		awk '{
			#if (match($1, "[^U]+Union:") && $1 != "RelProdUnion:") printf "\"%s\",", $2
			#else if ($1 == "RelProd:") printf "\"%s\",",  $2
			#else if ($1 == "RelProdUnion:") printf "\"%s\",",  $2
			#else if ($1 == "ProjectMinus:") printf "\"%s\",",  $2
			if ($1" "$2 == "Event Span:") printf "\"%s\",", $3
	        else if ($1" "$2" "$3 == "Normalized Event Span:") printf "\"%s\",", $4
	        else if ($1" "$2" "$3 == "Weighted Event Span,") printf "\"%s\",", $7			
		}' $i

		# stats for symmetric matrices
		grep -A4 bandwidth $i | grep -A3 profile | grep -A2 span | grep -A1 "average wavefront" | grep "RMS wavefront" > /dev/null
		if [ $? -eq 0 ]; then
			awk '{
				if ($3 == "bandwidth:") printf "\"%s\",", $4
		        else if ($3 == "profile:") printf "\"%s\",", $4
		        else if ($3 == "span:") printf "\"%s\",", $4	
	            else if ($3" "$4 == "average wavefront:") printf "\"%s\",", $5	
	            else if ($3" "$4 == "RMS wavefront:") printf "\"%s\",", $5
			}' $i
		else
		    printf '"",%.0s' {1..5}
		fi
	else
		 printf '"",%.0s' {1..14}
	fi

	grep "Exit \[0\]" $i > /dev/null
	
	if [ $? -eq 0 ]; then		
	    awk '{
			if ($3" "$4" "$5" "$6 == "state vector length is") printf "\"%s\",\"%s\",", substr($7, 1, length($7)-1), $10
			else if ($3" "$4 == "Exploration took") printf "\"%s\",\"%s\",", $5, $9
			else if ($3" "$4 == "reachability took") printf "\"%s\",", $7
			else if ($3" "$4" "$5 == "state space has") printf "\"%s\",\"%s\",", $6, $8
			else if ($3 == "group_next:") printf "\"%s\",", $4
			else if ($3 == "group_explored:") printf "\"%s\",\"%s\",", $4, $6
			else if ($2 == "user," && $4 == "system," && $6 == "elapsed") printf "\"%s\",\"%s\",", $1, substr($15, 1, length($15) - 2)
	    }' $i
	
		if [ $is_stat -eq 0 ]; then
			awk '{
				if ($5" "$6" "$7 == "final BDD nodes;") printf "\"%s\",", $8
			}' $i
		fi
	fi
    
    echo ""
    ((num_files++))
    
	if [ $((num_files % 100)) -eq 0 ]; then
	    echo >&2 "Files done: $num_files"
	fi
	    
done

if [ $(echo "$REDO" | wc -l) -gt 1 ]; then
    >&2 echo "The following experiments need to be rerun:"
    >&2 echo "$REDO"
else
    >&2 echo "No experiment failed"
    >&2 echo "$REDO"
fi
