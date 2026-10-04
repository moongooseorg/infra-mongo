#!/usr/bin/env bash
set -euo pipefail

MOUNT_POINT=/mnt/ssd
LABEL=ssd
DATA_DIR="$MOUNT_POINT/mongo"

[[ $EUID -eq 0 ]] || exec sudo "$0" "$@"

root_disk=$(lsblk -no PKNAME "$(findmnt -no SOURCE /)" | head -n1)

candidates() {
  lsblk -dpno NAME,TYPE,RM | while read -r name type rm; do
    [[ $type == disk && $rm == 0 ]] || continue
    [[ $(basename "$name") == "$root_disk" ]] && continue
    [[ $name == /dev/zram* || $name == /dev/loop* ]] && continue
    [[ $(lsblk -no NAME "$name" | wc -l) -eq 1 ]] || continue
    [[ -z $(blkid -p "$name" 2>/dev/null) ]] || continue
    echo "$name"
  done
}

if [[ $# -ge 1 ]]; then
  device=$1
else
  mapfile -t found < <(candidates)
  if [[ ${#found[@]} -ne 1 ]]; then
    echo "Found ${#found[@]} blank non-root disks. Specify one: $0 /dev/<disk>" >&2
    lsblk -dpo NAME,SIZE,MODEL,TYPE
    exit 1
  fi
  device=${found[0]}
fi

[[ -b $device && $(lsblk -dno TYPE "$device") == disk ]] || { echo "$device is not a disk" >&2; exit 1; }
[[ $(basename "$device") != "$root_disk" ]] || { echo "$device is the root disk" >&2; exit 1; }

if mountpoint -q "$MOUNT_POINT"; then
  echo "$MOUNT_POINT is already mounted" >&2
  exit 1
fi

lsblk -po NAME,SIZE,MODEL,FSTYPE,MOUNTPOINT "$device"
read -rp "ALL DATA on $device will be erased. Type 'yes' to continue: " answer
[[ $answer == yes ]] || exit 1

wipefs -a "$device"
parted -s "$device" mklabel gpt mkpart primary ext4 0% 100%
partprobe "$device"
udevadm settle

partition=$(lsblk -lnpo NAME,TYPE "$device" | awk '$2=="part"{print $1; exit}')
[[ -n $partition ]] || { echo "Partition not found on $device" >&2; exit 1; }

mkfs.ext4 -F -L "$LABEL" "$partition"
uuid=$(blkid -s UUID -o value "$partition")

mkdir -p "$MOUNT_POINT"
sed -i "\#[[:space:]]$MOUNT_POINT[[:space:]]#d" /etc/fstab
echo "UUID=$uuid $MOUNT_POINT ext4 defaults,noatime,nofail 0 2" >> /etc/fstab
systemctl daemon-reload
mount "$MOUNT_POINT"

mkdir -p "$DATA_DIR/db" "$DATA_DIR/configdb"
chown -R 999:999 "$DATA_DIR"

echo "Mounted $partition at $MOUNT_POINT (UUID=$uuid)"
