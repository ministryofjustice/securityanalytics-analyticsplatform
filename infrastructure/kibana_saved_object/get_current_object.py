import os
import sys
import boto3
from requests_aws4auth import AWS4Auth
import requests
import json


if len(sys.argv[1:]) != 5:
    raise ValueError(f"get_current_object.py region app_name object_name object_type url")

region, app_name, object_name, object_type, url = sys.argv[1:]

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

url = f"https://{url}/_plugin/kibana/api/saved_objects/_find?type={object_type}&search_fields=title&search={object_name}"
r = requests.get(url, auth=aws_auth)

if not r.ok:
    raise ValueError(f"Failure response ({r.status_code}): {r.text}")

result = r.json()
total = int(result["total"])
per_page = int(result["per_page"])

if not total < per_page:
    raise ValueError(f"Results of existing {object_type} matching {object_name} exceed {total} per page limit {per_page}")

existing_ids = [x["id"] for x in result["saved_objects"]]


print(f"{{\"existing_ids\":\"[{','.join(existing_ids)}]\"}}")
