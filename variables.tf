
variable "region" { default = "us-west-2" }
variable "vpc_cidr" { default = "10.44.0.0/16" }
variable "public_subnets" { 
    type = list(string) 
    default = ["10.44.1.0/24","10.44.2.0/24"] 
    }
variable "private_subnets" { 
    type = list(string) 
    default = ["10.44.11.0/24","10.44.12.0/24"] 
    }
variable "my_ip" { 
    type = string 
    default = "182.188.90.199/32" 
    } 
variable "ecr_repo_name" { default = "wu-nginx-custom" }
variable "cluster_name" { default = "wu-nginx-ecs-cluster" }
variable "task_log_group" { default = "/ecs/nginx" }
variable "ec2_desired_count" { 
    type = number 
    default = 2 
    }
variable "ec2_asg_min" {
     type = number 
     default = 1 
     }
variable "ec2_asg_max" {
     type = number 
     default = 2 
     }
variable "ec2_instance_type" { 
    type = string 
    default = "t3.medium" 
    }
