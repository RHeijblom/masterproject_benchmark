#!/bin/bash
if [ $# -lt 1 ]; then
	echo "Usage: $0 <filepath>"
	exit 1
fi
file=$1
filename=$(awk '{
			if ($3 == "opening") { "basename "$4 | getline name ; printf "%s", name }
    	}' "$file")
echo "File: $filename"
./filesplit.sh "$filename"