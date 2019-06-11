resource "aws_ssm_parameter" "sync_layer" {
  name        = "/${var.app_name}/${terraform.workspace}/lambda/layers/dynamo_elastic_sync/arn"
  description = "The arn of the synamo elastic sync lambda layer"
  type        = "String"
  value       = aws_lambda_layer_version.dynamo_elastic_sync_layer.arn
  overwrite   = "true"

  tags = {
    app_name  = var.app_name
    workspace = terraform.workspace
  }
}