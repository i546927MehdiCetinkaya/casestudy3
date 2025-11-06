# DynamoDB Table for Employee Data

resource "aws_dynamodb_table" "employees" {
  name           = var.table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "employeeId"
  
  attribute {
    name = "employeeId"
    type = "S"
  }

  attribute {
    name = "email"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  global_secondary_index {
    name            = "EmailIndex"
    hash_key        = "email"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "StatusIndex"
    hash_key        = "status"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name        = var.table_name
    Environment = var.environment
  }
}

# DynamoDB Table for Workspace Metadata
resource "aws_dynamodb_table" "workspaces" {
  name           = "${var.table_name}-workspaces"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "workspaceId"
  
  attribute {
    name = "workspaceId"
    type = "S"
  }

  attribute {
    name = "employeeId"
    type = "S"
  }

  global_secondary_index {
    name            = "EmployeeIndex"
    hash_key        = "employeeId"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name        = "${var.table_name}-workspaces"
    Environment = var.environment
  }
}
