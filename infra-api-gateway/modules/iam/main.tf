# IAM Role para API Gateway invocar o backend
resource "aws_iam_role" "api_gateway_role" {
  name = "${var.api_gateway_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Policy para CloudWatch Logs
resource "aws_iam_role_policy" "api_gateway_cloudwatch_policy" {
  name = "${var.api_gateway_name}-cloudwatch-policy"
  role = aws_iam_role.api_gateway_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:CreateServiceLinkedRole"
        ]
        Resource = "arn:aws:iam::*:role/aws-service-role/apigateway.amazonaws.com/*"
        Condition = {
          StringEquals = {
            "iam:AWSServiceName" = "apigateway.amazonaws.com"
          }
        }
      }
    ]
  })
}

# Policy para invocar o backend (NLB)
resource "aws_iam_role_policy" "api_gateway_invoke_policy" {
  name = "${var.api_gateway_name}-invoke-policy"
  role = aws_iam_role.api_gateway_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetHealth"
        ]
        Resource = "*"
      }
    ]
  })
}
