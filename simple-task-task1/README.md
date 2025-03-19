Overview

This Terraform module automates the provisioning of a Google Cloud environment, including:

Enabling required APIs

Creating a Virtual Private Cloud (VPC) with subnets

Setting up an Artifact Registry for storing container images

Deploying a Cloud Run service with VPC access

Configuring public access to the Cloud Run service

-------

Clone the repository 

git clone <repo-url>
cd <repo-directory>

Initialize Terraform
terraform init

Plan the deployment
terraform plan 

Apply the configuration
terraform apply -auto-approve

Resources Created 
This module provisions the following resources:

- VPC and Subnets

- Artifact Registry

- Cloud Run Service with VPC Connector

- IAM role for public access