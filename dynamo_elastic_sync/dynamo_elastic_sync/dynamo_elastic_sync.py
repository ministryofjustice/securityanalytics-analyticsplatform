from utils.lambda_decorators import ssm_parameters
from utils.json_serialisation import dumps
from boto3.dynamodb.types import TypeDeserializer
import os
import aioboto3
from asyncio import gather
from datetime import datetime
import pytz

# env vars
region = os.environ["REGION"]
stage = os.environ["STAGE"]
app_name = os.environ["APP_NAME"]
index_name = os.environ["ES_INDEX_NAME"]
dlq = os.environ["DLQ"]

# ssm params
ssm_prefix = f"/{app_name}/{stage}"
ES_SQS = f"{ssm_prefix}/analytics/elastic/ingest_queue/id"

ssm_client = aioboto3.client("ssm", region_name=region)
sqs_client = aioboto3.client("sqs", region_name=region)


class DynamoElasticSync:
    def __init__(self):
        self.deserialiser = TypeDeserializer()
        self.sqs_client = sqs_client

    # This base class does no transformation, but others will
    def transform_record(self, new_record, old_record):
        return new_record

    # This base class does nothing but others might
    def construct_msg_attributes(self, transformed_record):
        return {}

    @ssm_parameters(
        ssm_client,
        ES_SQS
    )
    async def forward_record(self, event, _):
        es_queue = event['ssm_params'][ES_SQS]

        writes = []
        for record in event["Records"]:
            print(f"Forwarding {record} to {index_name}")
            dynamo_data = record["dynamodb"]
            new_record = self._deserialise_image(dynamo_data, "NewImage")
            old_record = self._deserialise_image(dynamo_data, "OldImage")

            transformed_data = self.transform_record(new_record, old_record)
            msg_attributes = self.construct_msg_attributes(transformed_data)

            # N.B. Normally SNS notifiers that are the output of a scan feed the SQS queue
            # When amazon copies the meta data from the SNS to SQS, it moves the message attributes
            # to the message body. We replicate that here.
            message_like_from_sns = {
                "Subject": f"{index_name}:data:write",
                "Message": dumps(transformed_data),
                "MessageAttributes": msg_attributes
            }

            writes.append(
                self.sqs_client.send_message(
                    QueueUrl=es_queue,
                    MessageBody=dumps(message_like_from_sns)
                )
            )
        await gather(*writes)

    def _deserialise_image(self, dynamodb_section, image_name):
        result = {}
        if image_name in dynamodb_section:
            for k, v in dynamodb_section[image_name].items():
                deserialised_value = self.deserialiser.deserialize(v)
                if k.endswith("Time"):
                    deserialised_value = \
                        datetime.fromtimestamp(int(deserialised_value), pytz.utc).isoformat()
                    deserialised_value = deserialised_value.replace('+00:00', 'Z')
                result[k] = deserialised_value
        return result
