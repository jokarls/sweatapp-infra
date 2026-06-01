terraform {
  required_version = ">= 1.5.0"

  backend "gcs" {
    prefix = "state/sweatcheck-backend-${var.environment}"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.15.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.15.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# Local variables for consistent naming across the infrastructure
locals {
  prefix = "sweatcheck-${var.environment}"

  services = [
    "run.googleapis.com",               # Cloud Run
    "sqladmin.googleapis.com",          # Cloud SQL Admin
    "secretmanager.googleapis.com",     # Secret Manager
    "vpcaccess.googleapis.com",         # Serverless VPC Access
    "servicenetworking.googleapis.com", # Private Services Access (for Private IP Cloud SQL)
    "compute.googleapis.com",           # Compute Engine (required for networking)
    "iam.googleapis.com",               # IAM API
  ]
}

# Enable GCP APIs automatically
resource "google_project_service" "gcp_services" {
  for_each           = toset(local.services)
  project            = var.project_id
  service            = each.key
  disable_on_destroy = false
}
