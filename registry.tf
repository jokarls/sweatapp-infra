# Google Artifact Registry Repository for the backend Docker images
resource "google_artifact_registry_repository" "backend_repo" {
  project       = var.project_id
  location      = var.region
  repository_id = "${local.prefix}-backend"
  description   = "Docker repository for SweatCheck Backend"
  format        = "DOCKER"

  depends_on = [google_project_service.gcp_services]
}

# Dedicated Service Account for building and pushing backend Docker images
resource "google_service_account" "backend_deploy_sa" {
  project      = var.project_id
  account_id   = "${local.prefix}-backend-deploy"
  display_name = "SweatCheck Backend Deploy Service Account"
}

# Grant the dedicated deploy service account writer permission to the specific Artifact Registry repository
resource "google_artifact_registry_repository_iam_member" "backend_repo_writer" {
  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.backend_repo.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.backend_deploy_sa.email}"
}

# Fetch current GCP project data to retrieve the numerical Project Number
data "google_project" "project" {
  project_id = var.project_id
}

# Allow GitHub Actions via OIDC Workload Identity Federation to assume this dedicated Service Account
resource "google_service_account_iam_member" "backend_sa_workload_identity" {
  service_account_id = google_service_account.backend_deploy_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${var.workload_identity_pool_id}/attribute.repository/${var.github_repository_path}"
}


