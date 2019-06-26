import os
import boto3
import aioboto3
from requests_aws4auth import AWS4Auth
from utils.lambda_decorators import ssm_parameters, async_handler
from utils.json_serialisation import dumps
import requests
from json import loads

region = os.environ["REGION"]
stage = os.environ["STAGE"]
app_name = os.environ["APP_NAME"]
task_name = os.environ["TASK_NAME"]
ssm_prefix = f"/{app_name}/{stage}"
ssm_client = aioboto3.client("ssm", region_name=region)
SSM_ES_ENDPOINT = f"{ssm_prefix}/analytics/elastic/es_endpoint/url"
HEADERS = {"content-type": "application/json"}
credentials = boto3.Session().get_credentials()
awsauth = AWS4Auth(credentials.access_key, credentials.secret_key, region, "es", session_token=credentials.token)


@ssm_parameters(
    ssm_client,
    SSM_ES_ENDPOINT
)
@async_handler()
async def ingest(event, _):
    print(f"Processing {event}")
    endpoint = event["ssm_params"][SSM_ES_ENDPOINT]

    for event in event["Records"]:
        body = loads(event["body"])
        subject = body["Subject"]
        message = body["Message"]

        # If there are message attributes present, then it is assumed that the message received
        # is from the ResultsContext object. This contains a collection of document changes caused by
        # one scan, and adds additional data in order to maintain a history and snapshot view of all those
        # documents
        if "MessageAttributes" in body:
            post_snap_and_history(body, endpoint, message, subject)

        # Otherwise very simple logic is used to post the message body as a new event
        else:
            post_to_es(endpoint, subject, message)


def post_snap_and_history(body, endpoint, message, subject):
    attrs = body["MessageAttributes"]

    if not ("TemporalKey" in attrs or "ParentKey" in attrs):
        raise ValueError("Analytics ingestor requires both the TemporalKey and ParentKey message attributes be present")

    temporal_key = attrs["TemporalKey"]["Value"]
    parent_key = attrs["ParentKey"]["Value"]

    all_docs = loads(message)["__docs"]

    for doc_type, docs in all_docs:
        delete_old_snapshots(endpoint, subject, doc_type, parent_key)
        for doc in docs:
            non_temporal_key = doc["NonTemporalKey"]
            content = doc["Data"]

            # This post is the history, used in time series, note that key enables re-ingestion
            post_to_es(endpoint, f"{subject}_history:write", content, f"{non_temporal_key}@{temporal_key}")
            # This post is going to update the latest doc for this non temporal key
            # i.e. this produces an index where we can access the latest version of each scan.
            post_to_es(endpoint, f"{subject}_snapshot:write", content, non_temporal_key)


def delete_old_snapshots(endpoint, subject, doc_type, parent_key):
    es_url = f"https://{endpoint}/{subject}_snapshot:write/_doc/_delete_by_query?conflicts=proceed"
    print(f"Deleting {doc_type} snapshots for {parent_key} using {es_url}")
    delete_query = {
      "query": {
        "term": {
            "__ParentKey": parent_key
        }
      }
    }
    r = requests.delete(es_url, auth=awsauth, data=dumps(delete_query), headers=HEADERS)
    print(f"Delete completed {r.text}")
    response_json = r.json()
    if "error" in response_json.keys():
        raise RuntimeError(dumps(response_json["error"]))


def post_to_es(endpoint, subject, message, doc_id=None):
    doc_id = f"/{doc_id}" if doc_id else ""
    es_url = f"https://{endpoint}/{subject}/_doc{doc_id}"
    print(f"Posting {message} to {es_url}")
    r = requests.post(es_url, auth=awsauth, data=message, headers=HEADERS)
    print(f"Post completed {r.text}")
    response_json = r.json()
    if "error" in response_json.keys():
        raise RuntimeError(dumps(response_json["error"]))
