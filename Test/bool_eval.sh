#!/bin/bash
# Case distinction for booleans
bool=false

if $bool; then
	echo '$bool; evals true'
else
	echo '$bool; evals false'
fi

if [ $bool ]; then
	echo '[ $bool ]; evals true'
else
	echo '[ $bool ]; evals false'
fi

if [[ $bool ]]; then
	echo '[[ $bool ]]; evals true'
else
	echo '[[ $bool ]]; evals false'
fi