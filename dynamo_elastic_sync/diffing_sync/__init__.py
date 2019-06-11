from utils.lambda_decorators import async_handler
from . import diffing_sync

_syncer = diffing_sync.DiffingDynamoDbSync()


@async_handler()
def forward_record(event, context):
    return _syncer.forward_record(event, context)
