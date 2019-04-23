import subprocess
import time
import sys

# usage example
# python .\check_policy.py eu-west-2 progers-sec-an-user AmazonESCognitoAccess


# A script added to work around the apparent eventual consistency issues in attaching a new policy
# without this, the domain fails to create
def check_policy(region, user, policy, profile):
    try:
        print(f"Woooo {region} {user} {policy} {profile}")
        output = subprocess.check_output([
            "aws", "iam", "list-attached-role-policies",
            "--profile="+profile,
            "--role-name="+user,
            "--region="+region
        ], shell=True).decode('utf-8')
        if f"\"PolicyName\": \"{policy}\"" in output:
            print(f"Policy {policy} is attached to role {user}")
            return True
        else:
            print(f"Policy {policy} not attached to {user}")
            return False
    except Exception as e:
        print('Error ', e)
        return False


if len(sys.argv) != 5:
    sys.stderr.write("Syntax: python check_policy.py region user policy")
else:
    while not check_policy(*sys.argv[1:]):
        time.sleep(2)
    # TODO: remove the time delay hack
    print(f"Sleeping for a short while")
    time.sleep(15)
