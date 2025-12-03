# Create swap
```
curl -sSL https://raw.githubusercontent.com/cuongnbms/util-scripts/refs/heads/main/swapfile.sh | bash -s 4
```

# Setup xfs disk
```
curl -sSL https://raw.githubusercontent.com/cuongnbms/util-scripts/refs/heads/main/setup_xfs_disk.sh | sudo bash -s -- /dev/sdc /mnt/data --no-fstab
```
