"""
This script fetch an AAD token for an Azure Application using its client ID, client secret, and tenant ID. This AAD
token is then used to authenticate the Databricks service principal so it can then provision itself a personal access
token (PAT). The script was written in Python to be as platform-agnostic as possible (as compared to something like
curl) but that means Python3 is a necessary dependency to use this module.
"""
import urllib.request
import json
import sys

input = json.loads(sys.stdin.read())
url = f'https://login.microsoftonline.com/{input.get("tenant_id")}/oauth2/v2.0/token'
data = (f'client_id={input.get("client_id")}&'
        'grant_type=client_credentials&'
        'scope=2ff814a6-3304-4ab8-85cb-cd0e6f879c1d%2F.default&'  # programmatic ID for Azure Databricks
        f'client_secret={input.get("client_secret")}').encode('utf-8')

request = urllib.request.Request(url, data=data)
response = json.load(urllib.request.urlopen(request))
token = {
    "token": response.get("access_token")
}
print(json.dumps(token))
