#!/bin/bash

# Script to create swapfile
# Usage:
# bash swapfile.sh [size]
# 
# size: size (GB) of swapfile, default = 1GB

if [ $# -gt 0 ]
then
    SIZE=$1
else
    SIZE=1
fi

echo "Start create ${SIZE}G swapfile"
sudo fallocate -l ${SIZE}G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
sudo cp /etc/fstab /etc/fstab.bak
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

sudo sysctl vm.swappiness=10
sudo sysctl vm.vfs_cache_pressure=50

echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
echo 'vm.vfs_cache_pressure=50' | sudo tee -a /etc/sysctl.conf
