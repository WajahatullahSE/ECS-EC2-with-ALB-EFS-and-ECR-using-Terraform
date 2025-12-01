module "vpc" {
  source         = "./modules/vpc"
  vpc_cidr       = var.vpc_cidr
  public_subnets = var.public_subnets
  private_subnets = var.private_subnets
  region         = var.region
}

module "security" {
  source = "./modules/security"
  vpc_id = module.vpc.vpc_id
  my_ip  = var.my_ip
}

module "efs" {
  source             = "./modules/efs"
  private_subnet_ids = module.vpc.private_subnet_ids
  efs_sg_id          = module.security.efs_sg_id
}

module "ecr" {
  source    = "./modules/ecr"
  repo_name = var.ecr_repo_name
}

module "alb" {
  source            = "./modules/alb"
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id         = module.security.alb_sg_id
  vpc_id            = module.vpc.vpc_id
}

module "ecs" {
  source             = "./modules/ecs"
  cluster_name       = var.cluster_name
  private_subnet_ids = module.vpc.private_subnet_ids
  ecs_sg_id          = module.security.ecs_sg_id
  efs_id             = module.efs.efs_id
  efs_access_point_id = module.efs.efs_access_point_id
  repo_url           = module.ecr.repo_url
  task_log_group     = var.task_log_group
  desired_capacity   = var.ec2_desired_count
  asg_min            = var.ec2_asg_min
  asg_max            = var.ec2_asg_max
  instance_type      = var.ec2_instance_type
  vpc_id             = module.vpc.vpc_id
  alb_tg_arn         = module.alb.tg_arn
  # pass region to module (used in userdata template)
  aws_region         = var.region
}
