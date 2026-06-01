# Service Account for the SweatCheck Backend Cloud Run Service
resource "google_service_account" "cloud_run_sa" {
  account_id   = "${local.prefix}-run-sa"
  display_name = "SweatCheck Cloud Run Service Account"
  project      = var.project_id
}

# Grant Secret Manager Secret Accessor to the Cloud Run Service Account for DB_URL
resource "google_secret_manager_secret_iam_member" "db_url_accessor" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.db_url_secret.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# Grant Cloud SQL Client permission to the Cloud Run Service Account
resource "google_project_iam_member" "sql_client_role" {
  project    = var.project_id
  role       = "roles/cloudsql.client"
  member     = "serviceAccount:${google_service_account.cloud_run_sa.email}"
  depends_on = [google_project_service.gcp_services]
}

# Google Cloud Run Service (v2 API)
resource "google_cloud_run_v2_service" "backend_service" {
  name     = "${local.prefix}-backend"
  location = var.region
  project  = var.project_id

  # Ensure the VPC connector and Database secrets are created first
  depends_on = [
    google_vpc_access_connector.vpc_connector,
    google_secret_manager_secret_version.db_url_secret_version,
    google_project_service.gcp_services
  ]

  template {
    service_account = google_service_account.cloud_run_sa.email

    containers {
      image = var.app_image

      # Container Port (FastAPI usually runs on 8000, or we can use Cloud Run default 8080)
      ports {
        container_port = 8000
      }

      # Inject database connection URL securely from Secret Manager
      env {
        name = "DATABASE_URL"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.db_url_secret.secret_id
            version = "latest"
          }
        }
      }

      # Standard application settings as env variables
      env {
        name  = "ENVIRONMENT"
        value = var.environment
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }

    # Configure secure connection to our VPC
    vpc_access {
      connector = google_vpc_access_connector.vpc_connector.id
      # egress = "PRIVATE_RANGES_ONLY" routes only private database traffic through the VPC,
      # allowing the app to fetch external APIs (Strava, Weather) directly over public internet,
      # completely avoiding the need and costs of setting up a Cloud NAT.
      egress = "PRIVATE_RANGES_ONLY"
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
}

# Allow unauthenticated (public) access to the API endpoints so our mobile app and Strava webhooks can access it
resource "google_cloud_run_v2_service_iam_member" "allow_unauthenticated" {
  name     = google_cloud_run_v2_service.backend_service.name
  location = google_cloud_run_v2_service.backend_service.location
  project  = var.project_id
  role     = "roles/run.invoker"
  member   = "allUsers"
}
