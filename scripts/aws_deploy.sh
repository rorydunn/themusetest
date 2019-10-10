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

ecs-cli configure \
  --cluster $clusterName \
  --default-launch-type EC2 \
  --config-name $clusterName \
  --region us-east-1

echo 'Creating cluster' $clusterName

ecs-cli up \
  --capability-iam \
  --size 2 \
  --instance-type t2.medium \
  --cluster-config $clusterName \
  --launch-type EC2 \
  --force \
  --verbose

#Start a container
ecs-cli compose up --cluster-config $clusterName
