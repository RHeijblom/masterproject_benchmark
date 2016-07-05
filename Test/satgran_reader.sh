#!/bin/bash
if [ $# -lt 1 ]; then
	echo "Usage: $0 <string>"
	exit 1
fi
echo "$1" | grep "\-\-sat\-gran=" > /dev/null
if [ $? -eq 0 ]; then
	sat=$(echo "$1" | grep -o "\-\-sat\-gran=[[:digit:]]*")
	echo "Raw sat-granularity: $sat"
	sat="${sat##*=}"
	echo "Found sat-granularity: $sat"
else
	echo "No sat-granularity in given input"
fi
