#!/bin/bash


set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' 

echo -e "${GREEN}=== Django Image Build and Push Script ===${NC}"

if [ -z "$1" ]; then
    echo -e "${RED}Error: ECR repository URL is required${NC}"
    echo "Usage: ./build-and-push.sh <ECR_REPOSITORY_URL>"
    echo "Example: ./build-and-push.sh 123456789.dkr.ecr.us-east-1.amazonaws.com/lesson-7-ecr"
    exit 1
fi

ECR_URL=$1
AWS_REGION=${2:-us-east-1}
IMAGE_TAG=${3:-latest}

echo -e "${YELLOW}ECR URL: ${ECR_URL}${NC}"
echo -e "${YELLOW}AWS Region: ${AWS_REGION}${NC}"
echo -e "${YELLOW}Image Tag: ${IMAGE_TAG}${NC}"

echo -e "${GREEN}Step 1: Logging in to ECR...${NC}"
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URL


echo -e "${GREEN}Step 2: Building Docker image...${NC}"
cd django
docker build -t django-app:$IMAGE_TAG .
cd ..


echo -e "${GREEN}Step 3: Tagging image...${NC}"
docker tag django-app:$IMAGE_TAG $ECR_URL:$IMAGE_TAG


echo -e "${GREEN}Step 4: Pushing image to ECR...${NC}"
docker push $ECR_URL:$IMAGE_TAG

echo -e "${GREEN}=== Successfully pushed image to ECR ===${NC}"
echo -e "${YELLOW}Image URL: ${ECR_URL}:${IMAGE_TAG}${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Update charts/django-app/values.yaml with:"
echo "   image:"
echo "     repository: \"$ECR_URL\""
echo "     tag: \"$IMAGE_TAG\""
echo ""
echo "2. Deploy with Helm:"
echo "   helm install django-app ./charts/django-app"
