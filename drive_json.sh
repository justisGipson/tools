#!/bin/bash

# Check if two file paths are provided as arguments
if [ $# -ne 2 ]; then
    echo "Usage: $0 supps_from_db.json drive_supplementals.json"
    exit 1
fi

# Assign file paths to variables
supps_from_db_file="$1"
drive_supplementals_file="$2"

# Check if the files exist
if [ ! -f "$supps_from_db_file" ] || [ ! -f "$drive_supplementals_file" ]; then
    echo "One or both of the provided files does not exist."
    exit 1
fi

# Parse drive_supplementals.json and create an associative array with "name" as key
declare -A drive_supplementals
while IFS= read -r line; do
    name=$(echo "$line" | jq -r '.name')
    drive_supplementals["$name"]=1
done < <(jq -c '.[]' "$drive_supplementals_file")

# Process supps_from_db.json and generate the final JSON output
while IFS= read -r line; do
    record_id=$(echo "$line" | jq -r '.record_id')
    record_name=$(echo "$line" | jq -r '.supplementals.name')
    record_number=$(echo "$line" | jq -r '.supplementals.number')
    record_link=$(echo "$line" | jq -r '.record_link')

    drive_id="${drive_supplementals["$record_name"]}"
    duplicate=false
    if [ "$drive_id" == "" ]; then
        duplicate=true
    fi

    # Generate the final JSON output
    echo "{\"record_id\":$record_id,\"record_name\":\"$record_name\",\"record_number\":\"$record_number\",\"record_link\":\"$record_link\",\"name\":\"$record_name\",\"id\":\"$drive_id\",\"duplicate\":$duplicate}"
done < <(jq -c '.' "$supps_from_db_file")
