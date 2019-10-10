# TheMuse Challenge Readme

### Requirements
* docker
* docker-compose
* aws-cli
* ecs-cli
* AWS permissions to create ECS Clusters, EC2 resources (VPCs, subnets, EC2 instances), and an RDS instance

### To run the application locally:

1. Clone or download this repository.
2. From within the repository root run:
> docker-compose up -d

3. Visit your site running at localhost port 80

### To run the application in AWS:

1. Clone or download this repository.
2. From within the repository root run:
> bash scripts/aws_deploy.sh

3. When the script is done it will provide an IP where the service is running.

### Outstanding items
* Private subnet - need to create this not have it be automatically created.
* database access - need to create this in vpc
* ability to add more services - document this
* logging https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cmd-ecs-cli-logs.html?
