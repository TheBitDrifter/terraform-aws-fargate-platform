# --- 1. Networking Outputs (Corrected references to module.vpc) ---

output "vpc_id" {
  description = "The ID of the provisioned VPC."
  value       = module.vpc.vpc_id 
}

output "private_subnet_ids" {
  description = "A list of private subnet IDs where Fargate tasks and the Internal ALB are placed."
  value       = module.vpc.private_subnets 
}

output "default_security_group_id" {
  description = "The ID of the VPC's default security group. Used for task/ALB communication."
  value       = module.vpc.default_security_group_id 
}

# --- 2. ECS and Load Balancing Outputs ---

output "ecs_cluster_id" {
  description = "The ID of the central ECS cluster."
  value       = aws_ecs_cluster.this.name
}

output "alb_listener_arn" {
  description = "The ARN of the main internal ALB listener (Port 80/HTTP). Used by service modules to attach routing rules."
  value       = aws_lb_listener.internal_http.arn
}

# --- 3. API Gateway Outputs ---

output "api_gateway_id" {
  description = "The ID of the shared HTTP API Gateway."
  value       = aws_apigatewayv2_api.this.id
}

output "vpc_link_id" {
  description = "The ID of the VPC Link, used for secure routing into the private network."
  value       = aws_apigatewayv2_vpc_link.this.id
}

output "api_gateway_url" {
  description = "The public invocation URL for the API Gateway."
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "ecs_tasks_security_group_id" {
  description = "The ID of the Security Group for ECS Tasks."
  value       = aws_security_group.ecs_tasks_sg.id
}
