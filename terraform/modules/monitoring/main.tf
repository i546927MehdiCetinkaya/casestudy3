# CloudWatch Monitoring and Logging

resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/aws/eks/${var.cluster_name}"
  retention_in_days = 30

  tags = {
    Name        = "${var.cluster_name}-logs"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.cluster_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EKS", "cluster_failed_node_count", { stat = "Average" }],
            [".", "cluster_node_count", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = "eu-west-1"
          title  = "EKS Cluster Nodes"
        }
      }
    ]
  })
}
