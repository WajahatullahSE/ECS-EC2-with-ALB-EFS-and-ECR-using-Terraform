variable "aws_region" {
  type = string
}

variable "cluster_name" {
  type    = string
  default = "wu-nginx-ecs-cluster"
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "ecs_sg_id" {
  type = string
}

variable "efs_id" {
  type = string
}

variable "efs_access_point_id" {
  type = string
}

variable "efs_mount_point" {
  type    = string
  default = "/mnt/efs"
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "desired_capacity" {
  type    = number
  default = 2
}

variable "asg_min" {
  type    = number
  default = 1
}

variable "asg_max" {
  type    = number
  default = 2
}

variable "repo_url" {
  type = string
} # full ECR repo URL (e.g., 1234.dkr.ecr.us-west-2.amazonaws.com/nginx-custom)

variable "task_log_group" {
  type    = string
  default = "/ecs/nginx"
}

variable "vpc_id" {
  type = string
}

variable "alb_tg_arn" {
  type = string
}


