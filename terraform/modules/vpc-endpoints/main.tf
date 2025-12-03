# VPC Endpoints for Private Connectivity - Zero Trust Architecture
# All AWS service communication stays within AWS network (no internet)

# =============================================================================
# GATEWAY ENDPOINTS (Free - no additional cost)
# =============================================================================

# DynamoDB VPC Endpoint (Gateway)
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.route_table_ids

  tags = {
    Name        = "dynamodb-endpoint"
    Environment = var.environment
  }
}

# S3 VPC Endpoint (Gateway) - Required for ECR
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.route_table_ids

  tags = {
    Name        = "s3-endpoint"
    Environment = var.environment
  }
}

# =============================================================================
# INTERFACE ENDPOINTS (For complete private connectivity)
# =============================================================================

# ECR API VPC Endpoint (Interface)
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "ecr-api-endpoint"
    Environment = var.environment
  }
}

# ECR DKR VPC Endpoint (Interface)
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "ecr-dkr-endpoint"
    Environment = var.environment
  }
}

# CloudWatch Logs VPC Endpoint (Interface)
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "logs-endpoint"
    Environment = var.environment
  }
}

# EC2 VPC Endpoint (Interface) - For EKS
resource "aws_vpc_endpoint" "ec2" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ec2"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "ec2-endpoint"
    Environment = var.environment
  }
}

# STS VPC Endpoint (Interface) - For IAM roles / IRSA
resource "aws_vpc_endpoint" "sts" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.sts"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "sts-endpoint"
    Environment = var.environment
  }
}

# =============================================================================
# SSM ENDPOINTS - For secure management without public internet
# =============================================================================

# SSM VPC Endpoint (Interface) - For Systems Manager
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "ssm-endpoint"
    Environment = var.environment
  }
}

# SSM Messages VPC Endpoint (Interface) - For Session Manager
resource "aws_vpc_endpoint" "ssm_messages" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "ssm-messages-endpoint"
    Environment = var.environment
  }
}

# EC2 Messages VPC Endpoint (Interface) - For SSM Agent
resource "aws_vpc_endpoint" "ec2_messages" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "ec2-messages-endpoint"
    Environment = var.environment
  }
}

# =============================================================================
# ADDITIONAL ENDPOINTS FOR ZERO TRUST
# =============================================================================

# KMS VPC Endpoint (Interface) - For encryption operations
resource "aws_vpc_endpoint" "kms" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.kms"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "kms-endpoint"
    Environment = var.environment
  }
}

# Secrets Manager VPC Endpoint (Interface) - For secrets retrieval
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "secretsmanager-endpoint"
    Environment = var.environment
  }
}

# EKS VPC Endpoint (Interface) - For EKS API
resource "aws_vpc_endpoint" "eks" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.eks"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "eks-endpoint"
    Environment = var.environment
  }
}

# Elastic Load Balancing VPC Endpoint (Interface)
resource "aws_vpc_endpoint" "elasticloadbalancing" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.elasticloadbalancing"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "elb-endpoint"
    Environment = var.environment
  }
}

# Auto Scaling VPC Endpoint (Interface)
resource "aws_vpc_endpoint" "autoscaling" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.autoscaling"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "autoscaling-endpoint"
    Environment = var.environment
  }
}

# CloudWatch Monitoring VPC Endpoint (Interface)
resource "aws_vpc_endpoint" "monitoring" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.monitoring"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "monitoring-endpoint"
    Environment = var.environment
  }
}

# =============================================================================
# COGNITO ENDPOINTS - For HR Portal Authentication
# =============================================================================

# Cognito Identity VPC Endpoint
resource "aws_vpc_endpoint" "cognito_identity" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.cognito-identity"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "cognito-identity-endpoint"
    Environment = var.environment
  }
}

# Cognito IDP VPC Endpoint (User Pools)
resource "aws_vpc_endpoint" "cognito_idp" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.cognito-idp"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "cognito-idp-endpoint"
    Environment = var.environment
  }
}

# =============================================================================
# SECURITY GROUP FOR VPC ENDPOINTS
# =============================================================================

resource "aws_security_group" "vpc_endpoints" {
  name        = "vpc-endpoints-sg"
  description = "Security group for VPC endpoints - Zero Trust"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
    description = "Allow HTTPS from VPC"
  }

  # No egress - endpoints don't initiate connections
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
    description = "Allow responses to VPC only"
  }

  tags = {
    Name        = "vpc-endpoints-sg"
    Environment = var.environment
  }
}

data "aws_region" "current" {}

data "aws_vpc" "main" {
  id = var.vpc_id
}
