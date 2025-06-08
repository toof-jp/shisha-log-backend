resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-cluster"
    Environment = var.environment
  }
}

resource "aws_ecs_service" "main" {
  name            = "${var.project_name}-${var.environment}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.public_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  # Add load balancer configuration if target group is provided
  dynamic "load_balancer" {
    for_each = var.target_group_arn != null ? [1] : []
    content {
      target_group_arn = var.target_group_arn
      container_name   = "${var.project_name}-${var.environment}"
      container_port   = var.container_port
    }
  }

  # Ensure load balancer is ready before service deployment
  depends_on = [var.target_group_arn]

  tags = {
    Name        = "${var.project_name}-${var.environment}-service"
    Environment = var.environment
  }
}

resource "aws_ecs_task_definition" "main" {
  family                   = "${var.project_name}-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name  = "${var.project_name}-${var.environment}"
    image = var.container_image
    
    portMappings = [{
      containerPort = var.container_port
      protocol      = "tcp"
    }]

    environment = [
      for key, value in var.environment_variables : {
        name  = key
        value = tostring(value)
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.main.name
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = {
    Name        = "${var.project_name}-${var.environment}-task"
    Environment = var.environment
  }
}


resource "aws_cloudwatch_log_group" "main" {
  name              = "/ecs/${var.project_name}-${var.environment}"
  retention_in_days = 30

  tags = {
    Name        = "${var.project_name}-${var.environment}-logs"
    Environment = var.environment
  }
}

resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project_name}-${var.environment}-ecs-tasks-sg"
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id

  # Allow traffic from ALB if ALB security group is provided, otherwise allow from anywhere
  ingress {
    protocol        = "tcp"
    from_port       = var.container_port
    to_port         = var.container_port
    security_groups = var.alb_security_group_id != null ? [var.alb_security_group_id] : null
    cidr_blocks     = var.alb_security_group_id == null ? ["0.0.0.0/0"] : null
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-ecs-tasks-sg"
    Environment = var.environment
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-${var.environment}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-ecs-task-execution-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-${var.environment}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-ecs-task-role"
    Environment = var.environment
  }
}

data "aws_region" "current" {}

