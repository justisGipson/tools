#!/bin/bash

# Clean up package caches and logs
echo "Cleaning up package caches and logs..."
sudo apt-get clean
sudo apt-get autoclean
sudo journalctl --vacuum-size=50M

# Remove unused packages
echo "Removing unused packages..."
sudo apt-get autoremove --purge -y

# Clean up Docker
echo "Cleaning up Docker..."
sudo docker system prune -a -f

# Remove old kernel images
echo "Removing old kernel images..."
sudo apt-get purge "$(dpkg -l 'linux-image-*' | awk '/^ii/ && !/'"$(uname -r)"'/ {print $2}')" -y

# Update the system
echo "Updating the system..."
sudo apt-get update
sudo apt-get upgrade -y

# Clean up Yarn/NPM caches
if command -v yarn >/dev/null 2>&1; then
    echo "Cleaning up Yarn cache..."
    yarn cache clean
fi

if command -v npm >/dev/null 2>&1; then
    echo "Cleaning up NPM cache..."
    npm cache clean --force
fi

# Print the difference in disk usage
echo "Checking disk usage..."
df -h /
