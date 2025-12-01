# Create EFS Filesystem
resource "aws_efs_file_system" "this" {
  creation_token = "efs-nginx"
}

# Mount targets in each private subnet
resource "aws_efs_mount_target" "mt" {
  count          = length(var.private_subnet_ids)
  file_system_id = aws_efs_file_system.this.id
  subnet_id      = var.private_subnet_ids[count.index]
  security_groups = [var.efs_sg_id]
}

resource "aws_efs_access_point" "this" {
  file_system_id = aws_efs_file_system.this.id

  posix_user {
    uid = 101         # match user inside container (adjust as per nginx uid)
    gid = 101
  }

  root_directory {
    path = "/"
    creation_info {
      owner_gid = 101
      owner_uid = 101
      permissions = "0755"
    }
  }

  tags = {
    Name = "efs-access-point-wu"
  }
}