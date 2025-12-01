output "alb_dns" {
  value = module.alb.alb_dns
}

output "cluster_id" {
  value = module.ecs.cluster_id
}

output "ecs_service" {
  value = module.ecs.service_name
}

output "ecr_repo_url" {
  value = module.ecr.repo_url
}

output "efs_id" {
  value = module.efs.efs_id
}
