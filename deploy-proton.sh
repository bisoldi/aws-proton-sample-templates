#!/bin/bash

REGION="us-east-1"
PROFILE="data"
ENV_MAJOR="1"
ENV_MINOR="0"
SVC_MAJOR="1"
SVC_MINOR="0"

ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account --profile ${PROFILE})
ENDPOINT_URL="https://proton.${REGION}.amazonaws.com"

cd ~/git/aws-proton-sample-templates/loadbalanced-fargate-svc/

aws s3api create-bucket --bucket "proton-cli-templates-${ACCOUNT_ID}" --region ${REGION} --profile ${PROFILE}

#######################################################
# Create a role named ProtonServiceRole
aws iam create-role \
  --role-name ProtonServiceRole \
  --assume-role-policy-document \
  file://./policies/proton-service-assume-policy.json \
  --profile ${PROFILE}

# Attach the AWS managed AdministratorAccess policy to the ProtonServiceRole
aws iam attach-role-policy \
  --role-name ProtonServiceRole \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess \
  --profile ${PROFILE}
######################################################

######################################################################################
# Allow the Proton service to use the ProtonServiceRole when provisioning infrastructure.
aws proton-preview \
  --endpoint-url ${ENDPOINT_URL} \
  --region ${REGION} \
  --profile ${PROFILE} \
  update-account-roles \
  --account-role-details "pipelineServiceRoleArn=arn:aws:iam::${ACCOUNT_ID}:role/ProtonServiceRole"

# Define an environment template
aws proton-preview \
  --endpoint-url ${ENDPOINT_URL} \
  --region ${REGION} \
  --profile ${PROFILE} \
  create-environment-template \
  --template-name "proton-example-dev-env" \
  --display-name "ProtonExampleDevVPC" \
  --description "Proton Example Dev VPC with Public Access and ECS Cluster"

# Tag the template with a major version
aws proton-preview \
  --endpoint-url ${ENDPOINT_URL} \
  --region ${REGION} \
  --profile ${PROFILE} \
  create-environment-template-major-version \
  --template-name "proton-example-dev-env" \
  --description "Version 1"


# Tar and upload to s3
tar -zcvf env-template.tar.gz environment/ && aws s3 cp env-template.tar.gz s3://proton-cli-templates-${ACCOUNT_ID}/env-template.tar.gz --region ${REGION} --profile ${PROFILE} && rm env-template.tar.gz

# Now, we inform Proton that we have a new version of our environment template available and wait for it to complete
# registration. Pay close attention to the minor version in the output of the registration command, and ensure that’s
# the minor version you’re waiting for in the second command
aws proton-preview \
  --endpoint-url ${ENDPOINT_URL} \
  --region ${REGION} \
  --profile ${PROFILE} \
  create-environment-template-minor-version \
  --template-name "proton-example-dev-env" \
  --description "Proton Example Dev Environment Version 1" \
  --major-version-id ${ENV_MAJOR} \
  --source-s3-bucket proton-cli-templates-${ACCOUNT_ID} \
  --source-s3-key env-template.tar.gz \

# Wait for above command to complete
aws proton-preview \
  --endpoint-url ${ENDPOINT_URL} \
  --region ${REGION} \
  --profile ${PROFILE} \
  wait environment-template-registration-complete \
  --template-name "proton-example-dev-env" \
  --major-version-id ${ENV_MAJOR} \
  --minor-version-id ${ENV_MINOR}

# <---- Iterate on Cloudformation template ----->

# Publish environment template
#aws proton-preview \
#  --endpoint-url ${ENDPOINT_URL} \
#  --region ${REGION} \
#  --profile ${PROFILE} \
#  update-environment-template-minor-version \
#  --template-name "proton-example-dev-env" \
#  --major-version-id ${ENV_MAJOR} \
#  --minor-version-id ${ENV_MINOR} \
#  --status "PUBLISHED"

#####################################################################
# Create service template
aws proton-preview \
  --endpoint-url ${ENDPOINT_URL} \
  --region ${REGION} \
  --profile ${PROFILE} \
  create-service-template \
  --template-name "lb-fargate-service" \
  --display-name "LoadbalancedFargateService" \
  --description "Fargate Service with an Application Load Balancer"

# Tag template with major version
aws proton-preview \
  --endpoint-url ${ENDPOINT_URL} \
  --region ${REGION} \
  --profile ${PROFILE} \
  create-service-template-major-version \
  --template-name "lb-fargate-service" \
  --description "Version ${SVC_MAJOR}" \
  --compatible-environment-template-major-version-arns arn:aws:proton:${REGION}:${ACCOUNT_ID}:environment-template/proton-example-dev-env:${SVC_MAJOR}

# Tar and upload service template
tar -zcvf svc-template.tar.gz service/ && aws s3 cp svc-template.tar.gz s3://proton-cli-templates-${ACCOUNT_ID}/svc-template.tar.gz  --region ${REGION} --profile ${PROFILE} && rm svc-template.tar.gz

# Tag template with minor version
aws proton-preview \
  --endpoint-url ${ENDPOINT_URL} \
  --region ${REGION} \
  --profile ${PROFILE} \
  create-service-template-minor-version \
  --template-name "lb-fargate-service" \
  --description "Version 1" \
  --major-version-id ${SVC_MAJOR} \
  --source-s3-bucket proton-cli-templates-${ACCOUNT_ID} \
  --source-s3-key svc-template.tar.gz

aws proton-preview \
  --endpoint-url ${ENDPOINT_URL} \
  --region ${REGION} \
  --profile ${PROFILE} \
  wait service-template-registration-complete \
  --template-name "lb-fargate-service" \
  --major-version-id ${SVC_MAJOR} \
  --minor-version-id ${SVC_MINOR}

# <---- Iterate on Cloudformation template ----->

# Publish service template
#aws proton-preview \
#  --endpoint-url ${ENDPOINT_URL} \
#  --region ${REGION} \
#  --profile ${PROFILE} \
#  update-service-template-minor-version \
#  --template-name "lb-fargate-service" \
#  --major-version-id ${SVC_MAJOR} \
#  --minor-version-id ${SVC_MINOR} \
#  --status "PUBLISHED"

