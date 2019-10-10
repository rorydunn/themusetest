# TheMuse Challenge ReadMe

### Requirements
* docker
* docker-compose
* aws-cli
* ecs-cli
* port 80 available locally. If you don't want to use port 80 modify line 6 of the docker-compose file.
* AWS permissions to create ECS Clusters, EC2 resources (VPCs, subnets, EC2 instances), and an RDS instance

### To run the application locally:

1. Clone or download this repository.
2. From within the repository root run:
> docker-compose up -d

3. Visit your site running at localhost port 80

### To run the application in AWS:

1. Clone or download this repository.
2. From within the repository root run:
> bash scripts/ecs_deploy.sh $env-name

3. When the script is done it will provide an IP where the service is running.
4. Deploying the environment in AWS with the same $env-name used before will
replace the existing environment. Using a different $env-name will create an
additional environment.
5. Notes on the $env-name variable: it must contain only ASCII letters, digits, and hyphens; and must not end with a hyphen or contain two consecutive hyphens.
6. RDS information is written to a file when the script has completed - rdscredentials.txt


### To add additional services:

1. Add services to the docker-compose.yml file.
2. Deploy locally or to AWS in the same manner as listed above.

### Outstanding items
* Private subnet - not working correctly, discussed in NOTES file.
* database access - need to create this in vpc
* logging - discussed in notes file
