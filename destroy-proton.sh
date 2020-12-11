#!/bin/bash

REGION="us-east-1"
PROFILE="data"
ENV_MAJOR="1"
ENV_MINOR="0"
SVC_MAJOR="1"
SVC_MINOR="0"

ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account --profile ${PROFILE})
ENDPOINT_URL="https://proton.${REGION}.amazonaws.com"

echo -e "\n\nDeleting service template minor version"
aws proton-preview \
  --endpoint-url ${ENDPOINT_URL} \
  --region ${REGION} \
  --profile ${PROFILE} \
  delete-service-template-minor-version \
  --major-version-id ${SVC_MAJOR} \
  --minor-version-id ${SVC_MINOR} \
  --template-name "lb-fargate-service"

echo -e "\n\nDeleting service template major version"
aws proton-preview \
  --endpoint-url ${ENDPOINT_URL} \
  --region ${REGION} \
  --profile ${PROFILE} \
  delete-service-template-major-version \
  --major-version-id ${SVC_MAJOR} \
  --template-name "lb-fargate-service"

echo -e "\n\nDeleting service template"
aws proton-preview \
  --endpoint-url ${ENDPOINT_URL} \
  --region ${REGION} \
  --profile ${PROFILE} \
  delete-service-template \
  --template-name "lb-fargate-service"

##################################

echo -e "\n\nDeleting environment template minor version"
aws proton-preview \
  --endpoint-url ${ENDPOINT_URL} \
  --region ${REGION} \
  --profile ${PROFILE} \
  delete-environment-template-minor-version \
  --major-version-id ${ENV_MAJOR} \
  --minor-version-id ${ENV_MINOR} \
  --template-name "proton-example-dev-env"

echo -e "\n\nDeleting environment template major version"
aws proton-preview \
  --endpoint-url ${ENDPOINT_URL} \
  --region ${REGION} \
  --profile ${PROFILE} \
  delete-environment-template-major-version \
  --major-version-id ${ENV_MAJOR} \
  --template-name "proton-example-dev-env"

echo -e "\n\nDeleting environment template"
aws proton-preview \
  --endpoint-url ${ENDPOINT_URL} \
  --region ${REGION} \
  --profile ${PROFILE} \
  delete-environment-template \
  --template-name "proton-example-dev-env"

####################################

#######################################################
# Create a role named ProtonServiceRole
echo -e "\n\nDetaching policy from IAM Role"
aws iam detach-role-policy \
  --role-name "ProtonServiceRole" \
  --policy-arn "arn:aws:iam::aws:policy/AdministratorAccess" \
  --profile ${PROFILE}

#aws iam delete-role-policy \
#  --role-name "ProtonServiceRole" \
#  --policy-name "AdministratorAccess" \
#  --profile ${PROFILE}

echo -e "\n\nDeleting IAM Role"
aws iam delete-role \
  --role-name "ProtonServiceRole" \
  --profile ${PROFILE}
#######################################################

