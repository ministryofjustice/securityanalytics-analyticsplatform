from lambda_decorators import async_handler
import os
import boto3
from requests_aws4auth import AWS4Auth
from utils.lambda_decorators import ssm_parameters
from utils.json_serialisation import dumps
import requests
from json import loads

region = os.environ["REGION"]
stage = os.environ["STAGE"]
app_name = os.environ["APP_NAME"]
task_name = os.environ["TASK_NAME"]
ssm_prefix = f"/{app_name}/{stage}"
ssm_client = boto3.client("ssm", region_name=region)
sqs_client = boto3.client("sqs", region_name=region)
SSM_ES_ENDPOINT = f"{ssm_prefix}/analytics/elastic/es_endpoint/url"
credentials = boto3.Session().get_credentials()
awsauth = AWS4Auth(credentials.access_key, credentials.secret_key, region, "es", session_token=credentials.token)


@ssm_parameters(
    ssm_client,
    SSM_ES_ENDPOINT
)
@async_handler
async def ingest(event, _):
    print(f"Processing {event}")
    ssm_params = event["ssm_params"]

    for event in event["Records"]:
        body = loads(event["body"])
        subject = body["Subject"]
        es_url = f"https://{ssm_params[SSM_ES_ENDPOINT]}/{subject}/{subject}"
        message = body["Message"]
        print(f"Posting {message} to {es_url}")
        headers = {"content-type": "application/json"}

        r = requests.post(es_url, auth=awsauth, data=message, headers=headers)
        print(f"Post completed {r.text}")
        response_json = r.json()
        if "error" in response_json.keys():
            raise RuntimeError(dumps(response_json["error"]))
