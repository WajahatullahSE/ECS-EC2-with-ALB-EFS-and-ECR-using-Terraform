#!/bin/bash
# Register instance with ECS cluster and mount EFS
echo "ECS_CLUSTER=${cluster_name}" >> /etc/ecs/ecs.config

/ '
dnf install -y amazon-efs-utils
mkdir -p ${efs_mount_point}
# Retry loop for mounting EFS (prevent race conditions)
for i in {1..10}; do
  mount -t efs -o tls ${efs_id}:/ ${efs_mount_point} && break
  sleep 5
done

# Persist in fstab
echo "${efs_id}:/ ${efs_mount_point} efs defaults,_netdev 0 0" >> /etc/fstab

'/

