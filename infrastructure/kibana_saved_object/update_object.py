import os
import sys
import boto3
from requests_aws4auth import AWS4Auth
import requests
import json

if len(sys.argv[1:]) != 7:
    raise ValueError(f"update_object.py region app_name object_def_file object_type object_id, existing_ids url")

region, app_name, object_def_file, object_type, oid, existing_ids, url = sys.argv[1:]

credentials = (
    boto3.Session()
    if "AWS_ACCESS_KEY_ID" in os.environ.keys() else
    boto3.Session(profile_name=app_name)
).get_credentials()

aws_auth = AWS4Auth(
    credentials.access_key,
    credentials.secret_key,
    region,
    "es",
    session_token=credentials.token
)

headers = {"kbn-xsrf": "anything"}

with open(object_def_file, "r") as definition:
    def_json = json.load(definition)
    r = requests.post(
        f"https://{url}/_plugin/kibana/api/saved_objects/{object_type}/{oid}",
        headers=headers,
        auth=aws_auth,
        json=def_json
    )

    if not r.ok:
        raise ValueError(f"Failure response ({r.status_code}): {r.text}")

print(f"{{\"data\":{json.dumps(r.text)}}}")
