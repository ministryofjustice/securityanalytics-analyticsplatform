import subprocess
import time
import sys

# python .\check_policy.py eu-west-2 progers-sec-an-user AmazonESCognitoAccess


def check_policy(region, user, policy):
    try:
        output = subprocess.check_output(
            ["aws", "iam", "list-attached-role-policies", "--role-name="+user, '--region='+region]).decode('utf-8')
        print(output)
        if '"PolicyName": "'+policy+'"' in output:
            return True
        print('Policy '+policy+' not attached to '+user)
        return False
    except Exception as e:
        print('Error ', e)
        return False


if len(sys.argv) != 4:
    sys.stderr.write("Syntax: python check_policy.py region user policy")
else:
    while not check_policy(sys.argv[1], sys.argv[2], sys.argv[3]):
        time.sleep(2)
    time.sleep(15)
