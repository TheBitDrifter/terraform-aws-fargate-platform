# --- 1. NETWORKING (VPC, Subnets, NAT Gateway, IGW) ---
# Creates the necessary networking components and provides the subnet IDs.
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.19.0"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr_block

  azs                      = slice(data.aws_availability_zones.available.names, 0, var.availability_zones)
  public_subnets           = var.public_subnets
  private_subnets          = var.private_subnets
  enable_dns_hostnames     = true
  enable_nat_gateway       = true # Required for Fargate tasks to reach ECR/Internet
  single_nat_gateway       = true # Cost optimization
  create_igw               = true
}

data "aws_availability_zones" "available" {}

# --- 2. ECS CLUSTER ---
# The control plane for scheduling all Fargate tasks.
resource "aws_ecs_cluster" "this" {
  name = "${var.project_name}-${var.cluster_name}"
}

# --- 3. SECURITY GROUP (Shared Communication) ---
# Required for the ALB and VPC Link to securely access private subnets.
resource "aws_security_group" "alb_service_sg" {
  name        = "${var.project_name}-alb-service-sg"
  description = "Allows ingress from VPC Link and egress to ECS Tasks."
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow HTTP from VPC Link"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    self        = true # Allows traffic from resources with this same SG (i.e., the VPC Link)
  }

  # Allow all outbound traffic (default for most services)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- 4. INTERNAL APPLICATION LOAD BALANCER ---
# The shared, private entry point for all service traffic.
resource "aws_lb" "internal_alb" {
  name               = "${var.project_name}-int-alb"
  internal           = true # Critical: Ensures privacy
  load_balancer_type = "application"
  subnets            = module.vpc.private_subnets # Placed in private subnets
  security_groups    = [aws_security_group.alb_service_sg.id]
}

# Listener for the Internal ALB (Port 80 HTTP)
resource "aws_lb_listener" "internal_http" {
  load_balancer_arn = aws_lb.internal_alb.arn
  port              = 80
  protocol          = "HTTP"
  
  # Default action sends 404 until a service module attaches its own rule.
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404 Not Found - No service rule matched path."
      status_code  = "404"
    }
  }
}

# --- 5. API GATEWAY AND VPC LINK (Public Access Bridge) ---
# The public front door (API Gateway)
resource "aws_apigatewayv2_api" "this" {
  name          = "${var.project_name}-http-api"
  protocol_type = "HTTP"
}

# VPC Link (The secure tunnel)
resource "aws_apigatewayv2_vpc_link" "this" {
  name               = "${var.project_name}-vpc-link"
  subnet_ids         = module.vpc.private_subnets # Must live in the same private subnets as the ALB
  security_group_ids = [aws_security_group.alb_service_sg.id] # Shares SG access
}

# Default Deployment Stage
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true
}

# --- 6. SECURITY GROUP FOR ECS TASKS ---
# Dedicated SG for Fargate tasks, allowing traffic only from the ALB.
resource "aws_security_group" "ecs_tasks_sg" {
  name        = "${var.project_name}-ecs-tasks-sg"
  description = "Allow inbound access from the ALB only"
  vpc_id      = module.vpc.vpc_id

  # Ingress: Allow traffic from ALB on port 3000
  ingress {
    protocol        = "tcp"
    from_port       = 3000
    to_port         = 3000
    security_groups = [aws_security_group.alb_service_sg.id]
  }

  # Egress: Allow all outbound (for ECR, CloudWatch, etc.)
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}
