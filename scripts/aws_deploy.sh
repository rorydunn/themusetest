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

#Show the service is running
ecs-cli ps --cluster-config $clusterName
