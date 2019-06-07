output "es_endpoint" {
  value = aws_elasticsearch_domain.es.endpoint
}

output "kibana_endpoint" {
  value = aws_elasticsearch_domain.es.kibana_endpoint
}

output "num_azs" {
  value = data.aws_ssm_parameter.num_azs.value
}

output "ingest_queue" {
  value = aws_sqs_queue.ingestion_queue.arn
}

