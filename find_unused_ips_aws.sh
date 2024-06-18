#!/bin/bash

# List all subnets in your VPC and store the subnet IDs in an array
subnet_ids=("$(aws ec2 describe-subnets --query 'Subnets[*].SubnetId' --output text)")

# Function to find unused IP addresses in a given subnet
find_unused_ip_addresses() {
  local subnet_id=$1
  local used_ip_addresses=("$(aws ec2 describe-instances --filters "Name=subnet-id,Values=$subnet_id" --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)")
  local cidr_block=$(aws ec2 describe-subnets --subnet-ids "$subnet_id" --query 'Subnets[0].CidrBlock' --output text)

  # Calculate unused IP addresses
  local unused_ip_addresses=()
  for i in $(seq 1 254); do
    local ip="$cidr_block.$i"
    if ! [[ " ${used_ip_addresses[*]} " =~ ${ip} ]]; then
      unused_ip_addresses+=("$ip")
    fi
  done

  # Output the unused IP addresses for the subnet
  printf "Subnet ID: %s\n" "$subnet_id"
  printf "Unused IP Addresses: %s\n" "${unused_ip_addresses[*]}"
}

# Loop through each subnet and find unused IP addresses
for subnet_id in "${subnet_ids[@]}"; do
  find_unused_ip_addresses "$subnet_id"
done
