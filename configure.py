"""Read the current operator identity/IP and write ignored, local-only Terraform inputs."""
import ipaddress
import json
from pathlib import Path
from urllib.request import urlopen
import boto3

s=boto3.Session(region_name='us-east-1')
identity=s.client('sts').get_caller_identity()
assert identity['Account']=='911797457485'
arn=identity['Arn']
if ':assumed-role/' in arn:
    role_name=arn.split('/')[-2]
    arn=s.client('iam').get_role(RoleName=role_name)['Role']['Arn']
assert arn.startswith('arn:aws:iam::911797457485:')
ip=ipaddress.ip_address(urlopen('https://checkip.amazonaws.com/',timeout=10).read().decode().strip())
assert ip.version==4
root=Path(__file__).resolve().parent
(root/'infra/terraform.tfvars').write_text(f'cloudshell_cidr = "{ip}/32"\noperator_principal_arn = {json.dumps(arn)}\n')
print('Local inputs ready: one CloudShell IPv4 /32 and the existing operator principal; excluded from Git')
