#!/bin/bash
NOW=$(date +"%Y-%m-%d")
DIR="./logs/"
FILE=$DIR"log-$NOW.php"

echo "Loading log data from $FILE file, please wait..."
tail -f $FILE | grep -v 'DEBUG' | grep -v 'ERROR'

#echo "Please module name to see the log: "
#read input
#tail -f "./module/$input_variable/log/"
#echo "./module/$input/log/"