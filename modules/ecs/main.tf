# ECS cluster
resource "aws_ecs_cluster" "this" {
  name = var.cluster_name
}


# IAM role & instance profile for EC2 instances
resource "aws_iam_role" "ec2_role" {
  name = "${var.cluster_name}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Attach managed policies necessary for ECS EC2 host
resource "aws_iam_role_policy_attachment" "ecs_managed" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "cw_agent" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.cluster_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}


# CloudWatch Log Group for tasks
resource "aws_cloudwatch_log_group" "task_log" {
  name              = var.task_log_group
  retention_in_days = 14
}

# Use SSM parameter for Amazon Linux 3 ECS optimized AMI
data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id"
}

# Launch Template (EC2 user-data will mount EFS and configure ECS cluster)

data "template_file" "user_data" {
  template = file("${path.module}/userdata.tpl")

  vars = {
    cluster_name     = var.cluster_name
    efs_id           = var.efs_id
    efs_mount_point  = var.efs_mount_point
    region           = var.aws_region
  }
}

resource "aws_launch_template" "this" {
  name_prefix   = "${var.cluster_name}-lt-"
  image_id      = data.aws_ssm_parameter.ecs_ami.value
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.ecs_sg_id]
  }

  user_data = base64encode(data.template_file.user_data.rendered)
  lifecycle {
    create_before_destroy = true
  }
}


# ASG - place instances in private subnets (use numbers)

resource "aws_autoscaling_group" "asg" {
  name                      = "${var.cluster_name}-asg"
  desired_capacity          = var.desired_capacity
  min_size                  = var.asg_min
  max_size                  = var.asg_max
  health_check_type         = "EC2"
  vpc_zone_identifier       = var.private_subnet_ids
  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }
  tag  {
      key                 = "Name"
      value               = "${var.cluster_name}-instance"
      propagate_at_launch = true
    }
  
}


# ECS Task Definition (EC2 launch type)

resource "aws_ecs_task_definition" "nginx_task" {
  family                   = "${var.cluster_name}-nginx"
  network_mode             = "bridge" # EC2 launch mode
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "256"
  execution_role_arn       = aws_iam_role.task_exec_role.arn
  task_role_arn            = aws_iam_role.task_role.arn

volume {
  name = "efs_data"

  efs_volume_configuration {
    file_system_id     = var.efs_id
    transit_encryption = "ENABLED"

    authorization_config {
      access_point_id = var.efs_access_point_id
      iam             = "ENABLED"
    }
  }
}


  container_definitions = jsonencode([
    {
      name      = "nginx"
      image     = "504649076991.dkr.ecr.us-west-2.amazonaws.com/wu-nginx-custom:latest"
      essential = true
      memory    = 256
      cpu       = 256
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      mountPoints = [
        {
          sourceVolume  = "efs_data"
          containerPath = "/usr/share/nginx/html"
          readOnly      = false
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.task_log_group
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "nginx"
        }
      }
    }
  ])
}


# ECS Task/Execution Roles

data "aws_iam_policy_document" "task_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_exec_role" {
  name               = "${var.cluster_name}-task-exec-role"
  assume_role_policy = data.aws_iam_policy_document.task_assume_role.json
}

resource "aws_iam_role" "task_role" {
  name               = "${var.cluster_name}-task-role"
  assume_role_policy = data.aws_iam_policy_document.task_assume_role.json
}

# Attach managed policies to execution role
resource "aws_iam_role_policy_attachment" "exec_ecr" {
  role       = aws_iam_role.task_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Allow task role minimal access to CloudWatch Logs (if needed)
resource "aws_iam_role_policy_attachment" "task_cloudwatch" {
  role       = aws_iam_role.task_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}


# ECS Service (register with ALB target group)
resource "aws_ecs_service" "nginx_svc" {
  name            = "${var.cluster_name}-svc"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.nginx_task.arn
  desired_count   = var.desired_capacity
  launch_type     = "EC2"

  load_balancer {
    target_group_arn = var.alb_tg_arn
    container_name   = "nginx"
    container_port   = 80
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  depends_on = [aws_autoscaling_group.asg]
}
