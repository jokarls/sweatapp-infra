output "backend_url" {
  description = "The public URL of the deployed SweatCheck FastAPI backend."
  value       = google_cloud_run_v2_service.backend_service.uri
}

output "database_private_ip" {
  description = "The private IP address of the PostgreSQL database instance."
  value       = google_sql_database_instance.postgres_instance.private_ip_address
}

output "database_connection_name" {
  description = "The Cloud SQL connection name (project:region:instance_name) for Cloud SQL Auth Proxy or debugging."
  value       = google_sql_database_instance.postgres_instance.connection_name
}

output "cloud_run_service_account_email" {
  description = "The email of the Service Account running the backend Cloud Run service."
  value       = google_service_account.cloud_run_sa.email
}

output "dns_name_servers" {
  description = "The DNS Name Servers for the created Cloud DNS Zone. Copy these to your registrar if you configured domain_name."
  value       = var.domain_name != "" ? google_dns_managed_zone.dns_zone[0].name_servers : null
}

