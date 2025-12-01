output "cluster_id" {
  value = aws_ecs_cluster.this.id
}

output "task_def_arn" {
  value = aws_ecs_task_definition.nginx_task.arn
}

output "service_name" {
  value = aws_ecs_service.nginx_svc.name
}
