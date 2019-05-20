from lambda_decorators import async_handler
import os
import boto3
from requests_aws4auth import AWS4Auth
from utils.lambda_decorators import ssm_parameters
from utils.json_serialisation import dumps
import requests
from json import loads
import warnings

region = os.environ["REGION"]
stage = os.environ["STAGE"]
app_name = os.environ["APP_NAME"]
task_name = os.environ["TASK_NAME"]
ssm_prefix = f"/{app_name}/{stage}"
ssm_client = boto3.client("ssm", region_name=region)
sqs_client = boto3.client("sqs", region_name=region)
SSM_ES_ENDPOINT = f"{ssm_prefix}/analytics/elastic/es_endpoint/url"
HEADERS = {"content-type": "application/json"}
credentials = boto3.Session().get_credentials()
awsauth = AWS4Auth(credentials.access_key, credentials.secret_key, region, "es", session_token=credentials.token)


@ssm_parameters(
    ssm_client,
    SSM_ES_ENDPOINT
)
@async_handler
async def ingest(event, _):
    print(f"Processing {event}")
    endpoint = event["ssm_params"][SSM_ES_ENDPOINT]

    for event in event["Records"]:
        body = loads(event["body"])
        subject = body["Subject"]
        message = body["Message"]
        print(f"Posting {message} to {es_url}")

        # TODO (https://dsdmoj.atlassian.net/browse/SA-91)
        if "MessageAttributes" not in body:
            warnings.warn("No message attributes found in results message, falling back to old behaviour")
            post_to_es(endpoint, subject, message)
        else:
            attrs = body["MessageAttributes"]
            scan_end_time = attrs["ScanEndTime"]
            non_temporal_key = attrs["NonTemporalKey"]
            # This post is the history, used in time series, note that key enables re-ingestion
            post_to_es(endpoint, f"{subject}_history", message, f"{non_temporal_key}@{scan_end_time}")
            # This post is going to update the latest doc for this non temporal key
            # i.e. this produces an index where we can access the latest version of each scan.
            post_to_es(endpoint, f"{subject}_snapshot", message, non_temporal_key)


def post_to_es(endpoint, subject, message, doc_id=None):
    doc_id = f"/{doc_id}" if doc_id else ""
    es_url = f"https://{endpoint}/{subject}/_doc{doc_id}"
    r = requests.post(es_url, auth=awsauth, data=message, headers=HEADERS)
    print(f"Post completed {r.text}")
    response_json = r.json()
    if "error" in response_json.keys():
        raise RuntimeError(dumps(response_json["error"]))
