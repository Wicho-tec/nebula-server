"""Read-only scope/quota/cost checks before starting the approved Terraform lab."""
import json
from datetime import datetime, timezone
from pathlib import Path
import boto3

root=Path(__file__).resolve().parent
evidence=root/'evidencias'; evidence.mkdir(exist_ok=True)
s=boto3.Session(region_name='us-east-1')
assert s.client('sts').get_caller_identity()['Account']=='911797457485'
eks=s.client('eks'); iam=s.client('iam')
assert 'nebula-default' not in eks.list_clusters()['clusters']
for name in ['nebula-terraform-cluster','nebula-terraform-nodes','nebula-terraform-operator']:
    try: iam.get_role(RoleName=name)
    except iam.exceptions.NoSuchEntityException: pass
    else: raise AssertionError(f'Existing role must be inspected: {name}')
quota=s.client('service-quotas').get_service_quota(ServiceCode='ec2',QuotaCode='L-1216C47A')['Quota']['Value']
assert quota>=12, 'Three c7i.xlarge nodes need twelve standard on-demand vCPUs'
versions=eks.describe_cluster_versions(clusterVersions=['1.35'])['clusterVersions']
assert versions and versions[0].get('status',versions[0].get('versionStatus')) in ['STANDARD_SUPPORT','standard-support']
products=s.client('pricing',region_name='us-east-1').get_products(ServiceCode='AmazonEC2',MaxResults=100,
    Filters=[{'Type':'TERM_MATCH','Field':k,'Value':v} for k,v in {
        'instanceType':'c7i.xlarge','location':'US East (N. Virginia)','operatingSystem':'Linux',
        'tenancy':'Shared','preInstalledSw':'NA','capacitystatus':'Used'}.items()])['PriceList']
prices=[float(d['pricePerUnit']['USD']) for p in products for term in json.loads(p)['terms']['OnDemand'].values()
        for d in term['priceDimensions'].values() if d['unit']=='Hrs']
assert len(prices)==1 and 0<prices[0]<=.18
ecr=s.client('ecr').describe_repositories(repositoryNames=['nebula-server'])['repositories'][0]
result={'checked_at':datetime.now(timezone.utc).isoformat(),'ec2_vcpu_quota':quota,
    'kubernetes_versions':versions,'c7i_xlarge_usd_h':prices[0],
    'estimated_base_usd_h':3*prices[0]+.10+3*.005+90*.08/730+1/730,
    'approved_budget_goal_usd':1.50,'existing_ecr':ecr['repositoryArn']}
(evidence/'preflight.json').write_text(json.dumps(result,default=str,indent=2))
print(json.dumps(result,default=str,indent=2))
