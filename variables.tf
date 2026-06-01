variable "project_id" {
  description = "The ID of the GCP project where resources will be deployed."
  type        = string
}

variable "region" {
  description = "The GCP region to deploy resources into (e.g., europe-north1 for Stockholm/Sweden)."
  type        = string
  default     = "europe-north1"
}

variable "environment" {
  description = "The deployment environment name (e.g., dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "db_tier" {
  description = "The machine type for the Cloud SQL instance. Use db-f1-micro for low-cost testing."
  type        = string
  default     = "db-f1-micro"
}

variable "db_version" {
  description = "The PostgreSQL database engine version."
  type        = string
  default     = "POSTGRES_15"
}

variable "app_image" {
  description = "The Docker image for the SweatCheck FastAPI backend. Defaults to a standard hello image for initial bootstrap."
  type        = string
  default     = "gcr.io/cloudrun/hello"
}


