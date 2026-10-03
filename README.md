# mongo

### After installing a new ssd

sudo parted -s /dev/nvme0n1 mklabel gpt mkpart primary ext4 0% 100%
sudo mkfs.ext4 -L ssd /dev/nvme0n1p1
sudo mkdir -p /mnt/ssd
echo "UUID=$(sudo blkid -s UUID -o value /dev/nvme0n1p1) /mnt/ssd ext4 defaults,noatime,nofail 0 2" | sudo tee -a /etc/fstab
sudo systemctl daemon-reload
sudo mount -a
sudo mkdir -p /mnt/ssd/mongo/db /mnt/ssd/mongo/configdb
sudo chown -R 999:999 /mnt/ssd/mongo