#!/bin/bash
#
# This script creates a VPC and private subnets within AWS
#
# Usage: aws_deploy.sh <cluster_name>

# aws rds create-db-instance
#random string code from here https://stackoverflow.com/questions/2793812/generate-a-random-filename-in-unix-shell

masterpassword=$(cat /dev/urandom | env LC_CTYPE=C tr -cd 'a-f0-9' | head -c 12)

aws rds create-db-instance \
    --allocated-storage 20 --db-instance-class db.m4.large \
    --db-instance-identifier nameofthethign \
    --engine mysql \
    --enable-cloudwatch-logs-exports '["audit","error","general","slowquery"]' \
    --master-username master \
    --master-user-password $masterpassword \
    --multi-az

echo 'master' \ $masterpassword > rdscredentials.txt
