#!/usr/bin/env bash

GH_TOKEN=""

# For GitHub Enterprise, change this to "https://<your_domain>/api/v3"
GH_DOMAIN="https://api.github.com"

# The source repository whose labels to copy.
SRC_GH_USER=""
SRC_GH_REPO=""

# The target repository to add or update labels.
TGT_GH_USER=""
TGT_GH_REPO=""

# ---------------------------------------------------------

# Check if the required tools are installed
if ! command -v jq &> /dev/null; then
  echo "js is not installed. please install jq"
  read -p "Do you want to install jq? (y/n) " install_jq
  if [[ "$install_jq" == "y" ]]; then
    if command -v apt-get &> /dev/null; then
      sudo apt-get install jq
    elif command -v brew &> /dev/null; then
      brew install jq
    elif command -v yum &> /dev/null; then
      sudo yum install -y jq
    else
      echo "unable to determine package manager, install jq manually"
      exit 1
    fi
  else
    echo "exiting script. please install jq and try again"
    exit 1
  fi
fi

# Headers used in curl commands
GH_ACCEPT_HEADER="Accept: application/vnd.github.symmetra-preview+json"
GH_AUTH_HEADER="Authorization: Bearer $GH_TOKEN"

# loop over JSON array with jq
# https://starkandwayne.com/blog/bash-for-loop-over-json-array-using-jq/
sourceLabelsJson64=$(curl --silent -H "$GH_ACCEPT_HEADER" -H "$GH_AUTH_HEADER" ${GH_DOMAIN}/repos/${SRC_GH_USER}/${SRC_GH_REPO}/labels?per_page=100 | jq '[ .[] | { "name": .name, "color": .color, "description": .description } ]' | jq -r '.[] | @base64')

# for each label from source repo,
# invoke github api to create or update
# the label in the target repo
for sourceLabelJson64 in $sourceLabelsJson64; do

  # base64 decode the json
  sourceLabelJson=$(echo "${sourceLabelJson64}" | base64 --decode | jq -r '.')

  # try to create the label
  # POST /repos/:owner/:repo/labels { name, color, description }
  # https://developer.github.com/v3/issues/labels/#create-a-label
  createLabelResponse=$(echo "$sourceLabelJson" | curl --silent -X POST -d @- -H "$GH_ACCEPT_HEADER" -H "$GH_AUTH_HEADER" ${GH_DOMAIN}/repos/${TGT_GH_USER}/${TGT_GH_REPO}/labels)

  # if creation failed then the response doesn't include an id and jq returns 'null'
  createdLabelId=$(echo "$createLabelResponse" | jq -r '.id')

  # if label wasn't created maybe it's because it already exists, try to update it
  if [ "$createdLabelId" == "null" ]; then
    updateLabelResponse=$(echo "$sourceLabelJson" | curl --silent -X PATCH -d @- -H "$GH_ACCEPT_HEADER" -H "$GH_AUTH_HEADER" "${GH_DOMAIN}/repos/${TGT_GH_USER}/${TGT_GH_REPO}/labels/$(echo "$sourceLabelJson" | jq -r '.name | @uri')")
    printf 'Update label response:\n%c\n' "$updateLabelResponse"
  else
    printf 'Create label response:\n%c\n' "$createLabelResponse"
  fi
done
