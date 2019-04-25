

from lambda_decorators import async_handler
import os
import boto3

from utils.lambda_decorators import ssm_parameters
from utils.json_serialisation import dumps
from utils.objectify_dict import objectify
import tarfile
import re
import io
import untangle
import datetime
import pytz
from urllib.parse import unquote_plus
import requests

region = os.environ["REGION"]
stage = os.environ["STAGE"]
app_name = os.environ["APP_NAME"]
task_name = os.environ["TASK_NAME"]
ssm_prefix = f"/{app_name}/{stage}"
ssm_client = boto3.client("ssm", region_name=region)
sqs_client = boto3.client("sqs", region_name=region)
es_url = 'https://search-d-progers-sec-an-es-llytvwd7nqmfijkmjgvfx35lpu.eu-west-2.es.amazonaws.com/'+'sec-an'+'/data'


# @ssm_parameters(
#     ssm_client
# )
def injest(event, _):
    print(f'region {region}')
    SUBNETS = f"{ssm_prefix}/vpc/subnets/instance"
    es_url = f"{ssm_prefix}/analytics/elastic/es_endpoint/arn"
    print(f'{SUBNETS}')
    for event in event["Records"]:

        print(f"new record: {dumps(event['body'])}")
        # TODO: get the URL of elasticesearch and construct an endpoint
        # es_url = f"{var.elastic_search}"

        print(es_url)
        # send the record from queue to ES
        # r = requests.post(es_url, auth=awsauth,
        #                   json=event['body'], headers=headers)
        headers = {'content-type': 'application/json'}
        r = requests.post(es_url, dumps(event['body']), headers=headers)
        print(f"post completed, return {r.text}")
    # print(event)
    # print('hello')
    # print(sqs_client)


# take from the queue - see results_parser.py
# push to ES
