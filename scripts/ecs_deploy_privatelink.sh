#!/bin/bash
#
# This script creates a VPC and private subnets within AWS
#
# Usage: aws_deploy.sh <cluster_name>

# Collect parameters

clusterName="$1"

# Confirm parameters

if [[ "$1" = "" ]]; then
echo "############################################################"
echo "# Parameter usage: aws_vpc.sh <clusterName>                #"
echo "#                                                          #"
echo "# Specify cluster name, e.g. muse_prod_01 or muse-test     #"
echo "############################################################"
exit 0
fi

#This extracts a value from JSON and was found here https://gist.github.com/cjus/1047794
function jsonval {
    temp=`echo $json | sed 's/\\\\\//\//g' | sed 's/[{}]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w $prop| cut -d":" -f2| sed -e 's/^ *//g' -e 's/ *$//g'`
    echo ${temp##*|}
}

function countContainers {
    json=$(aws ecs describe-clusters --cluster $clusterName)
    prop='registeredContainerInstancesCount'
    containers=`jsonval`
    echo $containers
}

function clusterStatus {
    json=$(aws ecs describe-clusters --cluster $clusterName)
    prop='status'
    status=`jsonval`
    echo $status
}

function natGatewayStatus {
    json=$(aws ec2 describe-nat-gateways --nat-gateway-ids $clusterName)
    prop='status'
    status=`jsonval`
    echo $status
}

## Create VPC
json=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16)
prop='VpcId'
vpcId=`jsonval`

json=$(aws ec2 describe-vpcs --vpc-ids $vpcId)
prop='State'
vpcStatus=`jsonval`
echo 'VPC status is' $vpcStatus
echo 'Created VPC ' $vpcId

aws ec2 modify-vpc-attribute --vpc-id $vpcId --enable-dns-support "{\"Value\":true}"
aws ec2 modify-vpc-attribute --vpc-id $vpcId --enable-dns-hostnames "{\"Value\":true}"

## Create subnets
echo 'Creating Subnets'
json=$(aws ec2 create-subnet --vpc-id $vpcId --cidr-block 10.0.1.0/24)
prop='SubnetId'
subnetId1=`jsonval`
echo 'Created Subnet 1' $subnetId1

json=$(aws ec2 create-subnet --vpc-id $vpcId --cidr-block 10.0.0.0/24)
prop='SubnetId'
subnetId2=`jsonval`
echo 'Created Subnet 2' $subnetId2

#Create Elastic IP
echo 'Creating elasticIp'
json=$(aws ec2 allocate-address)
prop='AllocationId'
elasticIp=`jsonval`
echo 'Created elasticIp' $elasticIp

#Create internet gateway
echo 'Creating Internet Gateway'
json=$(aws ec2 create-internet-gateway)
prop='InternetGatewayId'
gatewayId=`jsonval`
echo 'Created Internet Gateway' $gatewayId

aws ec2 attach-internet-gateway --vpc-id $vpcId --internet-gateway-id $gatewayId

# Create Route table
echo 'Creating Route Table'
json=$(aws ec2 create-route-table --vpc-id $vpcId)
prop='RouteTableId'
routeTableId=`jsonval`
echo 'Created Route Table' $routeTableId

aws ec2 create-route --route-table-id $routeTableId --destination-cidr-block 0.0.0.0/0 --gateway-id $gatewayId
aws ec2 describe-route-tables --route-table-id $routeTableId
aws ec2 associate-route-table  --subnet-id $subnetId1 --route-table-id $routeTableId

#Create NAT Gateway
echo 'Creating NAT Gateway'
json=$(aws ec2 create-nat-gateway --subnet-id $subnetId1 --allocation-id $elasticIp)
prop='NatGatewayId'
natGateway=`jsonval`

##wait for NAT Gateway to be ready
##Create route table for private subnet
sleep 60s
# Create Route table
echo 'Creating Route Table'
json=$(aws ec2 create-route-table --vpc-id $vpcId)
prop='RouteTableId'
routeTableId2=`jsonval`
echo 'Created Route Table' $routeTableId2

aws ec2 create-route-table --vpc-id $vpcId
aws ec2 create-route --route-table-id $routeTableId2 --destination-cidr-block 0.0.0.0/0 --gateway-id $natGateway
aws ec2 associate-route-table --subnet-id $subnetId2 --route-table-id $routeTableId2

## Create security group
echo 'Creating Security Group'
json=$(aws ec2 create-security-group --group-name SSHAccess --description "Security group for SSH access" --vpc-id $vpcId)
prop='GroupId'
securityGroupId=`jsonval`
echo 'Security Group' $securityGroupId 'created'

## Setup AWS Privatelink
aws ec2 create-vpc-endpoint --vpc-id $vpcId --vpc-endpoint-type Interface --service-name com.amazonaws.us-east-1.ecs-agent --subnet-id $subnetId2 --security-group-id $securityGroupId
aws ec2 create-vpc-endpoint --vpc-id $vpcId --vpc-endpoint-type Interface --service-name com.amazonaws.us-east-1.ecs-telemetry --subnet-id $subnetId2 --security-group-id $securityGroupId
aws ec2 create-vpc-endpoint --vpc-id $vpcId --vpc-endpoint-type Interface --service-name com.amazonaws.us-east-1.ecs --subnet-id $subnetId2 --security-group-id $securityGroupId

aws ec2 authorize-security-group-ingress --group-id $securityGroupId --protocol tcp --port 443 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $securityGroupId --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $securityGroupId --protocol tcp --port 22 --cidr 0.0.0.0/0

# Configure the cluster
ecs-cli configure \
  --cluster $clusterName \
  --default-launch-type EC2 \
  --config-name $clusterName \
  --region us-east-1

echo 'Creating cluster' $clusterName

ecs-cli up \
  --capability-iam \
  --size 2 \
  --keypair saleslightprod \
  --instance-type t2.micro \
  --cluster-config $clusterName \
  --security-group $securityGroupId \
  --subnets $subnetId2 \
  --vpc $vpcId \
  --no-associate-public-ip-address \
  --launch-type EC2 \
  --force

##Verify containers are online
containers=`countContainers`

while [[ $containers != [2] ]]
do
  aws ecs describe-clusters --cluster $clusterName
  echo $containers 'containers available.'
  echo 'Waiting for all containers to come online.'
  containers=`countContainers`
  sleep 10s
done

sleep 30s
echo $containers 'containers available.'

#Start a container
ecs-cli compose up --cluster-config $clusterName

#Show the container is running
ecs-cli ps --cluster-config $clusterName

#Shut down the container
ecs-cli compose down --cluster-config $clusterName

#Start a service
ecs-cli compose service up --cluster-config $clusterName
# ecs-cli compose service up --cluster-config muse-test-01

#Show the service is running
ecs-cli ps --cluster-config $clusterName
