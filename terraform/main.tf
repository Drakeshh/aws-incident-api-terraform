# DynamoDB table for storing incidents
resource "aws_dynamodb_table" "incidents" {
  name         = "incidents"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# IAM role for Lambda execution
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy - Lambda can read/write DynamoDB and write logs
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan"
        ]
        Resource = aws_dynamodb_table.incidents.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Package Lambda function as zip
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../src/lambda_function.py"
  output_path = "${path.module}/../src/lambda_function.zip"
}

# Lambda function
resource "aws_lambda_function" "incident_handler" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-handler"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# API Gateway REST API
resource "aws_api_gateway_rest_api" "incident_api" {
  name        = "${var.project_name}-api"
  description = "Incident management REST API"

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# /incidents resource
resource "aws_api_gateway_resource" "incidents" {
  rest_api_id = aws_api_gateway_rest_api.incident_api.id
  parent_id   = aws_api_gateway_rest_api.incident_api.root_resource_id
  path_part   = "incidents"
}

# /incidents/{id} resource
resource "aws_api_gateway_resource" "incident_id" {
  rest_api_id = aws_api_gateway_rest_api.incident_api.id
  parent_id   = aws_api_gateway_resource.incidents.id
  path_part   = "{id}"
}

# POST /incidents
resource "aws_api_gateway_method" "post_incident" {
  rest_api_id   = aws_api_gateway_rest_api.incident_api.id
  resource_id   = aws_api_gateway_resource.incidents.id
  http_method   = "POST"
  authorization = "NONE"
}

# GET /incidents
resource "aws_api_gateway_method" "get_incidents" {
  rest_api_id   = aws_api_gateway_rest_api.incident_api.id
  resource_id   = aws_api_gateway_resource.incidents.id
  http_method   = "GET"
  authorization = "NONE"
}

# GET /incidents/{id}
resource "aws_api_gateway_method" "get_incident" {
  rest_api_id   = aws_api_gateway_rest_api.incident_api.id
  resource_id   = aws_api_gateway_resource.incident_id.id
  http_method   = "GET"
  authorization = "NONE"
}

# PUT /incidents/{id}
resource "aws_api_gateway_method" "put_incident" {
  rest_api_id   = aws_api_gateway_rest_api.incident_api.id
  resource_id   = aws_api_gateway_resource.incident_id.id
  http_method   = "PUT"
  authorization = "NONE"
}

# DELETE /incidents/{id}
resource "aws_api_gateway_method" "delete_incident" {
  rest_api_id   = aws_api_gateway_rest_api.incident_api.id
  resource_id   = aws_api_gateway_resource.incident_id.id
  http_method   = "DELETE"
  authorization = "NONE"
}

# Lambda integrations for each method
resource "aws_api_gateway_integration" "post_incident" {
  rest_api_id             = aws_api_gateway_rest_api.incident_api.id
  resource_id             = aws_api_gateway_resource.incidents.id
  http_method             = aws_api_gateway_method.post_incident.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.incident_handler.invoke_arn
}

resource "aws_api_gateway_integration" "get_incidents" {
  rest_api_id             = aws_api_gateway_rest_api.incident_api.id
  resource_id             = aws_api_gateway_resource.incidents.id
  http_method             = aws_api_gateway_method.get_incidents.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.incident_handler.invoke_arn
}

resource "aws_api_gateway_integration" "get_incident" {
  rest_api_id             = aws_api_gateway_rest_api.incident_api.id
  resource_id             = aws_api_gateway_resource.incident_id.id
  http_method             = aws_api_gateway_method.get_incident.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.incident_handler.invoke_arn
}

resource "aws_api_gateway_integration" "put_incident" {
  rest_api_id             = aws_api_gateway_rest_api.incident_api.id
  resource_id             = aws_api_gateway_resource.incident_id.id
  http_method             = aws_api_gateway_method.put_incident.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.incident_handler.invoke_arn
}

resource "aws_api_gateway_integration" "delete_incident" {
  rest_api_id             = aws_api_gateway_rest_api.incident_api.id
  resource_id             = aws_api_gateway_resource.incident_id.id
  http_method             = aws_api_gateway_method.delete_incident.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.incident_handler.invoke_arn
}

# Permission for API Gateway to invoke Lambda
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.incident_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.incident_api.execution_arn}/*/*"
}

# Deploy the API
resource "aws_api_gateway_deployment" "prod" {
  rest_api_id = aws_api_gateway_rest_api.incident_api.id

  depends_on = [
    aws_api_gateway_integration.post_incident,
    aws_api_gateway_integration.get_incidents,
    aws_api_gateway_integration.get_incident,
    aws_api_gateway_integration.put_incident,
    aws_api_gateway_integration.delete_incident
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway stage
resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.prod.id
  rest_api_id   = aws_api_gateway_rest_api.incident_api.id
  stage_name    = "prod"

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# ACM certificate for custom domain
resource "aws_acm_certificate" "api" {
  domain_name       = "api.project2.sergipratmerin.com"
  validation_method = "DNS"

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }

  lifecycle {
    create_before_destroy = true
  }
}

# DNS validation record in Route 53
resource "aws_route53_record" "api_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.api.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = "Z0947520WDN1EWGENS8T"
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

# Wait for certificate validation
resource "aws_acm_certificate_validation" "api" {
  certificate_arn         = aws_acm_certificate.api.arn
  validation_record_fqdns = [for record in aws_route53_record.api_cert_validation : record.fqdn]
}

# API Gateway custom domain
resource "aws_api_gateway_domain_name" "api" {
  domain_name              = "api.project2.sergipratmerin.com"
  regional_certificate_arn = aws_acm_certificate_validation.api.certificate_arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Map custom domain to API stage
resource "aws_api_gateway_base_path_mapping" "api" {
  api_id      = aws_api_gateway_rest_api.incident_api.id
  stage_name  = aws_api_gateway_stage.prod.stage_name
  domain_name = aws_api_gateway_domain_name.api.domain_name
}

# Route 53 record pointing subdomain to API Gateway
resource "aws_route53_record" "api" {
  zone_id = "Z0947520WDN1EWGENS8T"
  name    = "api.project2.sergipratmerin.com"
  type    = "A"

  alias {
    name                   = aws_api_gateway_domain_name.api.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.api.regional_zone_id
    evaluate_target_health = false
  }
}