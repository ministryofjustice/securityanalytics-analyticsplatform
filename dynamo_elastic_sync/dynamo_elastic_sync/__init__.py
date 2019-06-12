from utils.lambda_decorators import async_handler, forward_exceptions_to_dlq
from .dynamo_elastic_sync import sqs_client, ssm_client, dlq, DynamoElasticSync

_syncer = DynamoElasticSync()

# N.B. DynamoDB streams call lambda synchronously, which means that setting the dead letter queue on
# the lambda has no effect. Instead we report the error AND throw the exception which will mean that
# dynamo will keep trying to resend until it is successful
@forward_exceptions_to_dlq(sqs_client, dlq)
@async_handler()
def forward_record(event, context):
    return _syncer.forward_record(event, context)
