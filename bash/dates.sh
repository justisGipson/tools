#!/bin/bash

# help w/ debugging if it's not working right
set -x

# start from today - 90 days
NOW=$(date +%s)
UPLOADS_PATH="uploads/"
CYBERDYNE_PATH="uploads/cyberdyne/"

# check 'uploads/' for files
for file in $(find $UPLOADS_PATH -type f); do
  # regex pattern for date in YYYY-MM-DD format
  FILE_DATE=$(echo $file | grep -o '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}')
  FILE_EPOCH=$(date -d "$FILE_DATE" +%s)

  # if older than 90 days, delete it

  if (( ($NOW - $FILE_EPOCH) >= 7776000)); then
    rm -f $file
  fi
done

# check 'uploads/cyberdyne' for files
for file in $(find $CYBERDYNE_PATH -type f); do
  FILE_DATE=$(echo $file | grep -o '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}')
  FILE_EPOCH=$(date -d "$FILE_DATE" +%s)

   # if older than 90 days, delete it
  if (( ($NOW - $FILE_EPOCH) >= 7776000)); then
    rm -f $file
  fi
done

