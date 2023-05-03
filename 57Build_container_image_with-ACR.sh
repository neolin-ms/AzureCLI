#!/bin/sh

## Automate container image builds and maintenance with ACR Tasks
## https://learn.microsoft.com/en-us/azure/container-registry/container-registry-tasks-overview
## Quickstart: Build and run a container image using Azure Container Registry Tasks
## https://learn.microsoft.com/en-us/azure/container-registry/container-registry-quickstart-task-cli
## az acr task create
## https://learn.microsoft.com/en-us/cli/azure/acr/task?view=azure-cli-latest#az-acr-task-create

## === Part 1 ===

## 1. Create image hello-world
echo "FROM mcr.microsoft.com/hello-world" > Dockerfile

## 2. Builds the image and pushes it to your registry
az acr build --image sample/hello-world:v1 \
  --registry myacr010923 \
  --file Dockerfile .

## 3. Run the image, "Hello from Docker"
docker run hello-world

az acr run --registry myacr010923 \
  --cmd '$Registry/sample/hello-world:v1' /dev/null

## === Part 2 ===

## 1. Create image ubuntu
echo "FROM ubuntu" > Dockerfile

## 2. Builds the image and pushes it to your registry
az acr build --image sample/ubuntu:v1 \
  --registry myacr010923 \
  --file Dockerfile .

## 3-1. Run the image, Capture container ID "--cidfile"
docker run --cidfile /tmp/docker_test.cid ubuntu echo "test"

az acr run --registry myacr010923 \
  --cmd '--cidfile /tmp/docker_test.cid $Registry/sample/ubuntu:v1 echo "test"' /dev/null

## 3-2. Run the image, Set environment variables "--env"

docker run --env VAR1=value1 --env VAR2=value2 ubuntu env | grep VAR

az acr run --registry myacr010923 \
  --cmd '--env VAR1=value1 --env VAR2=value2 $Registry/sample/ubuntu:v1 env | grep VAR' /dev/null

## === Part 3 ===

## 1. Builds the image and pushes it to your registry
az acr build --registry myacr010923 --image helloacrtasks:v1 .

## 2. Run the image, "Hello World"

az acr run --registry myacr010923 \
  --cmd '$Registry/helloacrtasks:v1' /dev/null

## === Part 4 ===

az acr task create \
  --name timertask1 \
  --registry myacr010923 \
  --cmd '--cidfile /tmp/docker_test.cid $Registry/sample/ubuntu:v1 echo "test"' \
  --schedule "0 21 * * *" \
  --context /dev/null

az acr task show --name timertask1 --registry myacr010923 --output table

az acr task run --name timertask1 --registry myacr010923

## === Part 5 ===

az acr task create \
  --name timertask2 \
  --registry myacr010923 \
  --cmd '--env VAR1=value1 --env VAR2=value2 $Registry/sample/ubuntu:v1 env | grep VAR' \
  --schedule "0 21 * * *" \
  --context /dev/null

az acr task show --name timertask2 --registry myacr010923 --output table

az acr task run --name timertask2 --registry myacr010923
