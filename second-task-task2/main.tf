terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

####### enable apis #######
resource "google_project_service" "enabled_services" {
  for_each = toset([
    "run.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "compute.googleapis.com"
  ])
  service = each.value
}
###################

####### VPC and Subnets #####

resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  for_each   = var.subnet_configs
  name       = each.key
  region     = var.region
  network    = google_compute_network.vpc.id
  ip_cidr_range = each.value
}

####### Artifact Registry ########

resource "google_artifact_registry_repository" "repo" {
  provider      = google
  project       = var.project_id
  location      = var.region
  repository_id = "hello-world-repo"
  format        = "DOCKER"
  depends_on    = [google_project_service.enabled_services]
}
##################

######## Cloudrun ########

resource "google_cloud_run_v2_service" "hello_world" {
  name     = "hello-world-gcp"
  location = var.region

  template {
    vpc_access {
      connector = google_vpc_access_connector.connector.id
      egress    = "PRIVATE_RANGES_ONLY"
    }
    containers {
      image  = "${var.region}-docker.pkg.dev/${var.project_id}/hello-world-repo/${var.image_name}:latest"
      memory = var.memory
    }
  }

  depends_on = [google_project_service.enabled_services]
}

####### VPC #####

resource "google_vpc_access_connector" "connector" {
  name          = "vpc-connector"
  region        = var.region
  network       = google_compute_network.vpc.id
  ip_cidr_range = var.vpc_connector_cidr
}
#############

##### Adding invoker role cloudRun #####

resource "google_cloud_run_service_iam_member" "public_access" {
  service  = google_cloud_run_v2_service.hello_world.name
  location = google_cloud_run_v2_service.hello_world.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}
##################

######## Variables  #########

variable "project_id" {
  type        = string
  description = "The GCP project ID"
  default     = "sample-147852369"
}

variable "region" {
  type        = string
  description = "The GCP region"
  default     = "us-central1"
}

variable "vpc_name" {
  type        = string
  description = "The name of the VPC"
}

variable "subnet_configs" {
  type        = map(string)
  description = "Subnets with CIDR blocks"
  default = {
    "subnet-1" = "10.0.1.0/24"
    "subnet-2" = "10.0.2.0/24"
  }
}

variable "vpc_connector_cidr" {
  type        = string
  description = "CIDR block for the VPC connector"
  default     = "10.8.0.0/28"
}

variable "image_name" {
  type        = string
  description = "Docker image name"
}

variable "memory" {
  type        = string
  description = "Memory allocation for Cloud Run"
  default     = "512Mi"
}
####################

####### Outputs ###########
output "cloud_run_url" {
  value = google_cloud_run_v2_service.hello_world.uri
}
##########################