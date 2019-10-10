##Muse Challenge Readme

Basic Steps

Local
-Create docker image which can run locally

Prod/test
-create VPC (AWS CLI?)
-create security group (AWS CLI?)
This:
    -create task definition
      -https://docs.aws.amazon.com/AmazonECS/latest/developerguide/example_task_definitions.html
    -configure the service
Or this:
    -docker-compose-style commands
    https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cmd-ecs-cli-compose-service.html
-create cluster https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cmd-ecs-cli-up.html
-setup logging (https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cmd-ecs-cli-logs.html?)
-deploy image to cluster

How?
-two shell scripts
    -local script takes no parameters
    -remote script takes env name parameter (prod/test/dev/whatever)


Outstanding items
-HTTP Proxy
-Private subnet
-database access
-ability to add more services


### Dependencies

1. Install docker, docker-compose,

### To run the application locally:

1. Clone this repo
2. From within the project root run:
> docker-compose up -d

3. Visit your site running at localhost port 80

### To run the application in AWS:

1. Clone this repo
2. From within the project root run:
> docker-compose up -d

3. Visit your site running at localhost port 80


Resources Used
https://gist.github.com/cjus/1047794

