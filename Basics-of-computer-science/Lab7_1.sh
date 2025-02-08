#!/bin/bash

program_path=$1
t=$2

while true; do
    if pgrep -x "$(basename "$program_path")" > /dev/null; then
        echo "program is running"
    else
        echo "program is not running"
        output_file="output_$(date +'%Y%m%d_%H%M%S').txt"
        error_file="error_$(date +'%Y%m%d_%H%M%S').txt"
        
        "$program_path" > "$output_file" 2> "$error_file" &
    fi
    
    sleep "${t}m"
done
