# Route53 Private Hosted Zone for Internal Access

resource "aws_route53_zone" "private" {
  name = var.domain_name

  vpc {
    vpc_id = var.vpc_id
  }

  tags = {
    Name        = "${var.cluster_name}-private-zone"
    Environment = var.environment
  }
}
