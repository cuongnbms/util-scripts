#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Colors for logging
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Display usage helper
usage() {
    echo "Usage: $0 <device> <mount_path> [options]"
    echo "Options:"
    echo "  --no-fstab    Do not update /etc/fstab (Skip persistent mount)"
    echo ""
    echo "Examples:"
    echo "  Default (Update fstab):   $0 /dev/sdc /mnt/data"
    echo "  Skip fstab update:        $0 /dev/sdc /mnt/data --no-fstab"
    exit 1
}

# 1. Check for root privileges
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: This script must be run as root (sudo).${NC}"
   exit 1
fi

# 2. Check inputs
DEVICE=$1
MOUNT_PATH=$2
OPTION_FLAG=$3

# Default behavior: Update fstab = true
UPDATE_FSTAB=true

# Check for the optional flag
if [[ "$OPTION_FLAG" == "--no-fstab" ]]; then
    UPDATE_FSTAB=false
    echo -e "${YELLOW}Notice: '--no-fstab' detected. /etc/fstab will NOT be updated.${NC}"
fi

if [[ -z "$DEVICE" || -z "$MOUNT_PATH" ]]; then
    usage
fi

if [[ ! -b "$DEVICE" ]]; then
    echo -e "${RED}Error: Device $DEVICE does not exist.${NC}"
    exit 1
fi

echo -e "${YELLOW}--- Starting XFS Partition Setup for $DEVICE ---${NC}"

# 3. Safety Check: Warn about data loss
echo -e "${RED}WARNING: This will create a new GPT label on $DEVICE.${NC}"
echo -e "${RED}ALL DATA on $DEVICE will be LOST.${NC}"
read -p "Are you sure you want to proceed? (y/n): " confirm < /dev/tty
if [[ "$confirm" != "y" ]]; then
    echo "Operation aborted."
    exit 0
fi

# 4. Create Partition Table and Partition using 'parted'
echo "Creating GPT label and partition..."
parted "$DEVICE" --script mklabel gpt mkpart xfspart xfs 0% 100%

# 5. Inform the kernel about partition changes
echo "Probing partitions..."
partprobe "$DEVICE"
sleep 2

# 6. Determine Partition Name (Handle /dev/sdc1 vs /dev/nvme0n1p1)
if [[ "$DEVICE" =~ [0-9]$ ]]; then
    PARTITION="${DEVICE}p1"
else
    PARTITION="${DEVICE}1"
fi

echo -e "${YELLOW}Target Partition is: $PARTITION${NC}"

if [[ ! -b "$PARTITION" ]]; then
    echo -e "${RED}Error: Partition $PARTITION was not created successfully.${NC}"
    exit 1
fi

# 7. Format the PARTITION with XFS
echo "Formatting $PARTITION with XFS..."
mkfs.xfs -f "$PARTITION"

# 8. Create mount directory
if [[ ! -d "$MOUNT_PATH" ]]; then
    echo "Creating directory $MOUNT_PATH..."
    mkdir -p "$MOUNT_PATH"
fi

# 9. Mount
echo "Mounting $PARTITION to $MOUNT_PATH..."
mount "$PARTITION" "$MOUNT_PATH"

# 10. Configure fstab (Conditional)
if [ "$UPDATE_FSTAB" = true ]; then
    # Get UUID
    UUID=$(blkid -s UUID -o value "$PARTITION")
    
    if [[ -z "$UUID" ]]; then
        echo -e "${RED}Error: Failed to retrieve UUID for $PARTITION.${NC}"
        exit 1
    fi

    # Check fstab to avoid duplicates
    if grep -q "$UUID" /etc/fstab; then
        echo -e "${YELLOW}Entry for UUID=$UUID already exists in /etc/fstab. Skipping.${NC}"
    else
        echo "Adding entry to /etc/fstab..."
        echo "UUID=$UUID $MOUNT_PATH xfs defaults,nofail 0 2" >> /etc/fstab
        echo -e "${GREEN}fstab updated successfully.${NC}"
    fi
else
    echo -e "${YELLOW}Skipping /etc/fstab update as requested.${NC}"
fi

echo -e "${GREEN}Setup completed successfully!${NC}"
echo "Verification:"
lsblk -f "$DEVICE"
