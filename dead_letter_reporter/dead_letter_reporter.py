import os
import aioboto3
from utils.lambda_decorators import ssm_parameters, async_handler
from utils.objectify_dict import objectify
from urllib.parse import unquote_plus
from asyncio import gather
from utils.json_serialisation import dumps
from utils.time_utils import iso_date_string_from_timestamp
from datetime import datetime

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

        print(f"Loading new dead letter file: {(bucket, key)}")
        obj = await s3_client.get_object(Bucket=bucket, Key=key)
        dead_letter_details = obj["Metadata"]
        print(f"Wring new dead letter with metadata: {dead_letter_details}")

        ensure_essential_metadata(
            dead_letter_details,
            [
                ("deadletterqueuename", "Metadata missing"),
                ("deadletterkey", "Metadata missing"),
                ("deadlettersenttime", str(iso_date_string_from_timestamp(datetime.now().timestamp())))
            ]
        )

        writes.append(
            sqs_client.send_message(
                QueueUrl=es_queue,
                MessageBody=dumps({
                    "Subject": "dead_letter:data:write",
                    "Message": dumps(dead_letter_details)
                })
            )
        )
    print(f"Gathering writes")
    await gather(*writes)
    print(f"Written successfully")


def ensure_essential_metadata(dead_letter_details, meta_data_and_defaults):
    for attribute, default_value in meta_data_and_defaults:
        if attribute not in dead_letter_details:
            dead_letter_details[attribute] = default_value
