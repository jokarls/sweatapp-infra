# Generate a secure random password for PostgreSQL
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Cloud SQL PostgreSQL Instance (Private IP only)
resource "google_sql_database_instance" "postgres_instance" {
  name             = "${local.prefix}-db"
  database_version = var.db_version
  region           = var.region
  project          = var.project_id

  # Deletion protection can be set to true for production environments
  deletion_protection = false

  settings {
    tier = var.db_tier

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = google_compute_network.vpc_network.id
      enable_private_path_for_google_cloud_services = true
    }

    # Backup configuration (Optional but good practice)
    backup_configuration {
      enabled    = true
      start_time = "02:00"
    }
  }

  depends_on = [
    google_service_networking_connection.private_vpc_connection,
    google_project_service.gcp_services
  ]
}

# Create the SweatCheck database
resource "google_sql_database" "database" {
  name     = "sweatcheck"
  instance = google_sql_database_instance.postgres_instance.name
  project  = var.project_id
}

# Create the database user
resource "google_sql_user" "db_user" {
  name     = "sweat_admin"
  instance = google_sql_database_instance.postgres_instance.name
  password = random_password.db_password.result
  project  = var.project_id
}

# Store Database URL in GCP Secret Manager
resource "google_secret_manager_secret" "db_url_secret" {
  secret_id = "DATABASE_URL"
  project   = var.project_id

  replication {
    auto {}
  }

  depends_on = [google_project_service.gcp_services]
}

resource "google_secret_manager_secret_version" "db_url_secret_version" {
  secret      = google_secret_manager_secret.db_url_secret.id
  secret_data = "postgresql://sweat_admin:${random_password.db_password.result}@${google_sql_database_instance.postgres_instance.private_ip_address}:5432/sweatcheck"
}

# Store standalone DB Password in Secret Manager
resource "google_secret_manager_secret" "db_password_secret" {
  secret_id = "DB_PASSWORD"
  project   = var.project_id

  replication {
    auto {}
  }

  depends_on = [google_project_service.gcp_services]
}

resource "google_secret_manager_secret_version" "db_password_secret_version" {
  secret      = google_secret_manager_secret.db_password_secret.id
  secret_data = random_password.db_password.result
}
