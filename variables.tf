# --- REGIONAL AND GLOBAL SETTINGS ---

variable "aws_region" {
  description = "The AWS region where the platform infrastructure will be deployed."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Base name for all resources (e.g., 'acme-prod'). Used for tagging and resource naming."
  type        = string
}

# --- VPC NETWORK CONFIGURATION ---

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC (e.g., '10.0.0.0/16')."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks for NAT Gateway placement."
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks for Fargate and Internal ALB placement."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "availability_zones" {
  description = "The number of Availability Zones to deploy resources across."
  type        = number
  default     = 2
}

# --- FARGATE/ECS CONFIGURATION ---

variable "cluster_name" {
  description = "Name for the ECS Cluster."
  type        = string
  default     = "application-cluster"
}

