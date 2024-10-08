#!/bin/bash

# Check if the required arguments are provided
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <app_name> <duration_in_minutes>"
  exit 1
fi

app_name="$1"
duration_in_minutes="$2"
output_file="heroku_postgres_metrics.txt"

# Convert bytes to gigabytes (GB)
convert_bytes_to_gb() {
  local bytes=$1
  echo "scale=2; $bytes / 1000000000" | bc
}

# Convert kilobytes to gigabytes (GB)
convert_kb_to_gb() {
  local kb=$1
  echo "scale=2; $kb / 1000000" | bc
}

# Convert percentage to percent
convert_percentage_to_percent() {
  local percentage=$1
  echo "scale=2; $percentage * 100" | bc
}

# Determine the source type based on the source name
get_source_type() {
  local source="$1"
  if [[ "$source" == "HEROKU_POSTGRESQL_GRAY" ]]; then
    echo "PROD-FOLLOWER"
  else
    echo "PROD-PRIMARY"
  fi
}

# Parse the logs and format the output
format_metrics() {
  local line="$1"
  local metric_name="$2"
  local metric_value="$3"
  echo "- $metric_name: $metric_value" >> "$output_file"
}

# Run the script continuously for the specified duration
start_time=$(date +%s)
end_time=$((start_time + (duration_in_minutes * 60)))

while [ "$(date +%s)" -lt $end_time ]; do
  if ! logs=$(heroku logs -p heroku-postgres -a "$app_name" 2>&1); then
    echo "Error fetching Heroku Postgres logs for app '$app_name':"
    echo "$logs"
    exit 1
  fi

  if [ -z "$logs" ]; then
    echo "No Heroku Postgres logs found for app '$app_name'. Trying again."
  else
    while read -r line; do
      if [[ "$line" == *"sample#"* ]]; then
        source=$(echo "$line" | grep -o 'source=\([^[:space:]]*\)' | cut -d'=' -f2)
        source_type=$(get_source_type "$source")
        format_metrics "$line" "Source" "$source_type"
        format_metrics "$line" "Active Connections" "$(echo "$line" | grep -o 'sample#active-connections=\([0-9]*\)' | cut -d'=' -f2)"
        format_metrics "$line" "Waiting Connections" "$(echo "$line" | grep -o 'sample#waiting-connections=\([0-9]*\)' | cut -d'=' -f2)"
        format_metrics "$line" "Max Connections" "$(echo "$line" | grep -o 'sample#max-connections=\([0-9]*\)' | cut -d'=' -f2)"
        format_metrics "$line" "Connections Percentage Used" "$(convert_percentage_to_percent "$(echo "$line" | grep -o 'sample#connections-percentage-used=\([0-9.]*\)' | cut -d'=' -f2)")%"

        echo "" >> "$output_file"
        format_metrics "$line" "Load Average (1m)" "$(echo "$line" | grep -o 'sample#load-avg-1m=\([0-9.]*\)' | cut -d'=' -f2)"
        format_metrics "$line" "Load Average (5m)" "$(echo "$line" | grep -o 'sample#load-avg-5m=\([0-9.]*\)' | cut -d'=' -f2)"
        format_metrics "$line" "Load Average (15m)" "$(echo "$line" | grep -o 'sample#load-avg-15m=\([0-9.]*\)' | cut -d'=' -f2)"

        echo "" >> "$output_file"
        format_metrics "$line" "Read IOPS" "$(echo "$line" | grep -o 'sample#read-iops=\([0-9.]*\)' | cut -d'=' -f2)"
        format_metrics "$line" "Write IOPS" "$(echo "$line" | grep -o 'sample#write-iops=\([0-9.]*\)' | cut -d'=' -f2)"
        format_metrics "$line" "Max IOPS" "$(echo "$line" | grep -o 'sample#max-iops=\([0-9]*\)' | cut -d'=' -f2)"
        format_metrics "$line" "IOPS Percentage Used" "$(convert_percentage_to_percent "$(echo "$line" | grep -o 'sample#iops-percentage-used=\([0-9.]*\)' | cut -d'=' -f2)")%"

        echo "" >> "$output_file"
        format_metrics "$line" "Temporary Disk Used" "$(convert_bytes_to_gb "$(echo "$line" | grep -o 'sample#tmp-disk-used=\([0-9]*\)' | cut -d'=' -f2)") GB"
        format_metrics "$line" "Temporary Disk Available" "$(convert_bytes_to_gb "$(echo "$line" | grep -o 'sample#tmp-disk-available=\([0-9]*\)' | cut -d'=' -f2)") GB"

        echo "" >> "$output_file"
        format_metrics "$line" "Memory Total" "$(convert_kb_to_gb "$(echo "$line" | grep -o 'sample#memory-total=\([0-9]*\)' | cut -d'=' -f2)") GB"
        format_metrics "$line" "Memory Free" "$(convert_kb_to_gb "$(echo "$line" | grep -o 'sample#memory-free=\([0-9]*\)' | cut -d'=' -f2)") GB"
        format_metrics "$line" "Memory Percentage Used" "$(convert_percentage_to_percent "$(echo "$line" | grep -o 'sample#memory-percentage-used=\([0-9.]*\)' | cut -d'=' -f2)")%"
        format_metrics "$line" "Memory Cached" "$(convert_kb_to_gb "$(echo "$line" | grep -o 'sample#memory-cached=\([0-9]*\)' | cut -d'=' -f2)") GB"
        format_metrics "$line" "Memory Postgres" "$(convert_kb_to_gb "$(echo "$line" | grep -o 'sample#memory-postgres=\([0-9]*\)' | cut -d'=' -f2)") GB"
        echo "" >> "$output_file"
      fi
    done <<< "$logs"
  fi

  sleep 10  # Wait for 10 seconds before fetching logs again
done

echo "Heroku Postgres metrics have been saved to '$output_file'."
