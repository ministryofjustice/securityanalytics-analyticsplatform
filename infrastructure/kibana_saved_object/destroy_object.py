import os
import sys
import boto3
from requests_aws4auth import AWS4Auth
import requests


if len(sys.argv[1:]) != 5:
    raise ValueError(f"destroy_object.py region app_name object_type existing_ids url")

region, app_name, object_type, existing_ids, url = sys.argv[1:]

credentials = (
    boto3.Session()
    if "AWS_ACCESS_KEY" in os.environ.keys() else
    boto3.Session(profile_name=app_name)
).get_credentials()

aws_auth = AWS4Auth(
    credentials.access_key,
    credentials.secret_key,
    region,
    "es",
    session_token=credentials.token
)

existing_ids = existing_ids[1:-1].split(",")
headers = {"kbn-xsrf": "anything"}

# delete all existing
for oid in existing_ids:
    if oid != "":
        r = requests.delete(
            f"https://{url}/_plugin/kibana/api/saved_objects/{object_type}/{oid}",
            headers=headers,
            auth=aws_auth
        )

        if not r.ok:
            # TODO how to determine the difference between a failure because it isn't there to delete and it is there
            # and we couldn't delete it, only the second should be considered an exception
            print(f"{{\"aok\":\"false\"}}")
            sys.exit()

print(f"{{\"aok\":\"true\"}}")
