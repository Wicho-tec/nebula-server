"""Create only the separately approved private Terraform backend bucket."""
import json
from pathlib import Path
import boto3

account, bucket = '911797457485', 'nebula-tfstate-911797457485-us-east-1'
s=boto3.Session(region_name='us-east-1')
assert s.client('sts').get_caller_identity()['Account']==account
c=s.client('s3')
assert bucket not in {b['Name'] for b in c.list_buckets()['Buckets']}, 'Backend exists: inspect ownership/tags before reuse'
c.create_bucket(Bucket=bucket)
c.put_bucket_tagging(Bucket=bucket,Tagging={'TagSet':[{'Key':'practica','Value':'3.6'}]})
c.put_public_access_block(Bucket=bucket,PublicAccessBlockConfiguration={
    'BlockPublicAcls':True,'IgnorePublicAcls':True,'BlockPublicPolicy':True,'RestrictPublicBuckets':True})
c.put_bucket_encryption(Bucket=bucket,ServerSideEncryptionConfiguration={'Rules':[
    {'ApplyServerSideEncryptionByDefault':{'SSEAlgorithm':'AES256'}}]})
c.put_bucket_versioning(Bucket=bucket,VersioningConfiguration={'Status':'Enabled'})
c.put_bucket_policy(Bucket=bucket,Policy=json.dumps({'Version':'2012-10-17','Statement':[{
    'Sid':'DenyInsecureTransport','Effect':'Deny','Principal':'*','Action':'s3:*',
    'Resource':[f'arn:aws:s3:::{bucket}',f'arn:aws:s3:::{bucket}/*'],
    'Condition':{'Bool':{'aws:SecureTransport':'false'}}}]}))
root=Path(__file__).resolve().parent
(root/'infra/backend.hcl').write_text((root/'infra/backend.hcl.example').read_text())
print('Private encrypted versioned backend created; S3 native lockfile will be used')
