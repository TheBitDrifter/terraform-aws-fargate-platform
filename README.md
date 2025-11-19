# terraform-aws-fargate-platform

## Purpose

This module provisions the **shared foundational infrastructure** required to run all microservices in the Fargate/VPC Link pattern. It defines the network and control plane, strictly adhering to governance standards.

This module is designed to be provisioned **once per environment** (e.g., staging, production) and its outputs are consumed by the service deployment modules (`terraform-aws-fargate-service`).

## 🛡️ Governance and Security Highlights

* **VPC and Subnets:** Creates a dedicated VPC with isolated Public (for NAT Gateway) and Private (for application tasks) subnets.
* **Internal Load Balancer:** The ALB is provisioned as **internal** and placed in **private subnets**, ensuring no direct public access.
* **API Gateway:** Serves as the single, public point of entry for all traffic.
* **VPC Link:** Establishes the secure, private bridge between the public API Gateway and the internal network.

```mermaid
graph TD
    subgraph "Platform Module Scope"
        subgraph VPC
            subgraph "Public Subnets"
                IGW[Internet Gateway]
                NAT[NAT Gateway]
                APIGW[API Gateway]
            end
            
            subgraph "Private Subnets"
                ALB[Internal ALB]
                Cluster[ECS Cluster]
                VPCLink[VPC Link]
            end
        end
    end
    
    APIGW -->|Secure Tunnel| VPCLink
    VPCLink -->|Traffic| ALB
    ALB -->|Load Balancing| Cluster
```

## 💡 Outputs (The Contract)

The primary function of this module is to generate the following outputs, which are mandatory inputs for the service module:

| Output Name | Purpose | Consumed by Service Module as... |
| :--- | :--- | :--- |
| `vpc_id`, `private_subnet_ids` | Networking context. | `vpc_id`, `private_subnet_ids` |
| `ecs_cluster_id` | Placement for Fargate tasks. | `ecs_cluster_id` |
| `alb_listener_arn` | Target for new service routing rules. | `alb_listener_arn` |
| `api_gateway_id`, `vpc_link_id` | Routing targets for public exposure. | `api_gateway_id`, `vpc_link_id` |

---

## ⚙️ Usage (For Reference)

This module should be called from your environment configuration (e.g., `prod-config/main.tf`):

```terraform
module "platform" {
  source  = "[github.com/your-org/terraform-aws-fargate-platform](https://github.com/your-org/terraform-aws-fargate-platform)"
  version = "v1.0.0"

  project_name        = "acme-widgets-prod"
  aws_region          = "us-east-1"
  vpc_cidr_block      = "10.0.0.0/16"
  availability_zones  = 2
}
