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
    "artifactregistry.googleapis.com"
  ])
  service = each.value
}
##########################

###### Artifact Registry #######
resource "google_artifact_registry_repository" "repo" {
  provider = google
  project  = var.project_id
  location = var.region
  repository_id = "hello-world-repo"
  format = "DOCKER"
}
########################

######## cloudrun ########
resource "google_cloud_run_service" "hello_world" {
  name     = "hello-world"
  location = var.region

  template {
    spec {
      containers {
        image = "${var.region}-docker.pkg.dev/${var.project_id}/hello-world-repo/hello-world:latest"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

resource "google_cloud_run_service_iam_member" "public_access" {
  service  = google_cloud_run_service.hello_world.name
  location = google_cloud_run_service.hello_world.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}
########################

#### variables.tf ######
variable "project_id" {
    type = string
    description = "The ID of the project"
    default     = "sample-147852369"
}
variable "region" {
    type = string
    description = "The region of the project"
    default     = "us-central1"
}
####################

##### output.tf ####
output "cloud_run_url" {
  value = google_cloud_run_service.hello_world.status[0].url
}
############