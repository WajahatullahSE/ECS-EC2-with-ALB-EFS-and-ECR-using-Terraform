output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}

output "ecs_sg_id" {
  value = aws_security_group.ecs_sg.id
}

output "efs_sg_id" {
  value = aws_security_group.efs_sg.id
}
