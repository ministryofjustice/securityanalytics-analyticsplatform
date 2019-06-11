locals {
  sync_zip = "../.generated/${var.app_name}_dynamo_elastic_sync.zip"
}

data "external" "sync_zip" {
  program = ["python", "../shared_code/python/package_lambda.py", "-x", local.sync_zip, "${path.module}/packaging.config.json", "../Pipfile.lock"]
}

resource "aws_lambda_layer_version" "dynamo_elastic_sync_layer" {
  description         = "Layer containing a lambda template with hash ${data.external.sync_zip.result.hash}"
  filename            = local.sync_zip
  layer_name          = "${terraform.workspace}-${var.app_name}-dynamo-elastic-sync"
  compatible_runtimes = ["python3.7"]
}