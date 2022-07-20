"""
This script fetch an AAD token for an Azure Application using its client ID, client secret, and tenant ID. This AAD
token is then used to authenticate the Databricks service principal so it can then provision itself a personal access
token (PAT). The script was written in Python to be as platform-agnostic as possible (as compared to something like
curl) but that means Python3 is a necessary dependency to use this module.
"""
import urllib.request
import json
import sys
import os
import math
import random
import time

INTERVAL_MAX = 30
INTERVAL_BASE = 5
MAX_EXPONENT = 10


def backoff_with_jitter(attempt):
    """
    Creates a growing but randomized wait time based on the number of attempts already made.
    """
    exponent = min(attempt, MAX_EXPONENT)
    sleep_time = min(INTERVAL_MAX, INTERVAL_BASE * 2 ** exponent)
    return random.randrange(math.floor(sleep_time * 0.5), sleep_time)

scope = os.getenv('DATABRICKS_AAD_TOKEN_SCOPE')  # INTERNAL USE ONLY
if scope is None:
    scope = '2ff814a6-3304-4ab8-85cb-cd0e6f879c1d'  # programmatic ID for Azure Databricks

input = json.loads(sys.stdin.read())
url = f'https://login.microsoftonline.com/{input.get("tenant_id")}/oauth2/v2.0/token'
data = (f'client_id={input.get("client_id")}&'
        'grant_type=client_credentials&'
        f'scope={scope}%2F.default&'
        f'client_secret={input.get("client_secret")}').encode('utf-8')

while True:
    attempt = 1
    try:
        request = urllib.request.Request(url, data=data)
        response = json.load(urllib.request.urlopen(request))
    except urllib.error.HTTPError as e:
        print(f'Token fetch attempt {attempt} FAILED with error {e}', file=sys.stderr)
        time.sleep(backoff_with_jitter(attempt))
    else:
        break

token = {
    "token": response.get("access_token")
}
print(json.dumps(token))
