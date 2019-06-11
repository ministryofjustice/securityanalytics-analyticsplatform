from utils.lambda_decorators import async_handler
from . import dynamo_elastic_sync

_syncer = dynamo_elastic_sync.DynamoElasticSync()


@async_handler()
def forward_record(event, context):
    return _syncer.forward_record(event, context)