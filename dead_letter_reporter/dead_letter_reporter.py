import os
import aioboto3
from utils.lambda_decorators import ssm_parameters, async_handler
from utils.objectify_dict import objectify
from urllib.parse import unquote_plus
from asyncio import gather
from utils.json_serialisation import dumps

region = os.environ["REGION"]
stage = os.environ["STAGE"]
app_name = os.environ["APP_NAME"]

ssm_client = aioboto3.client("ssm", region_name=region)
s3_client = aioboto3.client("s3", region_name=region)
sqs_client = aioboto3.client("sqs", region_name=region)

ssm_prefix = f"/{app_name}/{stage}"
ES_SQS = f"{ssm_prefix}/analytics/elastic/ingest_queue/id"


@ssm_parameters(
    ssm_client,
    ES_SQS
)
@async_handler()
async def report_letters(event, _):
    es_queue = event['ssm_params'][ES_SQS]
    writes = []
    for record in event["Records"]:
        s3_object = objectify(record["s3"])
        bucket = s3_object.bucket.name
        key = unquote_plus(s3_object.object.key)

        print(f"Reporting new dead letter file: {(bucket, key)}")
        obj = await s3_client.get_object(Bucket=bucket, Key=key)
        dead_letter_details = obj["Metadata"]

        # N.B. Normally SNS notifiers that are the output of a scan feed the SQS queue
        # When amazon copies the meta data from the SNS to SQS, it moves the message attributes
        # to the message body. We replicate that here.
        message_like_from_sns = {
            "Subject": "dead_letter:data",
            "Message": dumps(dead_letter_details),
            "MessageAttributes": {
                "NonTemporalKey": {
                    # N.B. messageid not messageId because S3 attributes are made lower
                    # case so that they can be used as headers in HTTP requests
                    "Value": dead_letter_details["messageid"],
                    "DataType": "string"
                },
                # TODO rename scan end time in elastic ingestor to more general name
                "ScanEndTime": {
                    "Value": dead_letter_details["deadlettersenttime"],
                    "DataType": "string"
                }
            }

        }

        writes.append(
            sqs_client.send_message(
                QueueUrl=es_queue,
                MessageBody=dumps(message_like_from_sns)
            )
        )
    await gather(*writes)
