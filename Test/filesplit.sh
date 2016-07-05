#!/bin/bash
if [ $# -lt 1 ]; then
	echo "Usage: $0 <filepath>"
	exit 1
fi
filename=$(basename "$1")
extension="${filename##*.}"
filename="${filename%.*}"
echo "File: $filename"
echo "Ext:  $extension"