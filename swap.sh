#!/bin/bash
part='sdb'
device_name="/dev/${part}"
count=`lsblk | grep $part | grep -v "$part "  | cut -d"a" -f2 | wc -l`
block_number=`expr $count + 1`
get_part=`parted $device_name print | tail -n 2 | awk '{{ print $3 }}' | cut -d"M" -f1`
part_start=`expr $get_part + 1` 
vg='centos'
lv_size='400' unit='m'
swap_name='swap'

if [ $count -eq "0" ]
then
   
   #This block of code will run  to partition a device and add to swap and works only when there is no existing partition on an existing block device 
   echo "There is no existing partition on this device, $$device_name"
   part_start='1'
   part_end='500'
   parted $device_name mkpart primary linux-swap  $part_start $(expr $part_start + $part_end)
   partprobe $device_name 
   pvcreate $device_name${block_number}
   vgextend $vg ${device_name}${block_number} 
   lvresize -L +${lv_size}${unit} /dev/$vg/$swap_name
   swapoff -a 
   mkswap /dev/$vg/$swap_name
   swapon /dev/$vg/$swap_name
   free -m 
else
   # This block of code will run to partition a device and add to swap and only works when there already exists partitions on the block device  
   echo "There is/are existing parttions on this device"
   echo "Creating an additional partition to increase swap space"
   part_end='500'
 
   parted $device_name mkpart primary linux-swap  $part_start $(expr $part_start + $part_end)
   partprobe $device_name
   pvcreate $device_name${block_number}
   vgextend $vg ${device_name}${block_number}
   lvresize -L +${lv_size}${unit} /dev/$vg/$swap_name
   swapoff -a
   mkswap /dev/$vg/$swap_name
   swapon /dev/$vg/$swap_name
   free -m
fi    

