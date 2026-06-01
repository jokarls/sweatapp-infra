# Google Cloud DNS Managed Zone for this project's custom domain/subdomain
resource "google_dns_managed_zone" "dns_zone" {
  count       = var.domain_name != "" ? 1 : 0
  name        = "sweatapp-dns-zone"
  dns_name    = "${var.domain_name}." # Must end with a trailing dot
  description = "Managed DNS zone for SweatCheck"
  project     = var.project_id

  depends_on = [google_project_service.gcp_services]
}

# Cloud Run Custom Domain Mapping
resource "google_cloud_run_domain_mapping" "backend_mapping" {
  count    = var.domain_name != "" ? 1 : 0
  name     = var.domain_name
  location = var.region
  project  = var.project_id

  metadata {
    namespace = var.project_id
  }

  spec {
    route_name = google_cloud_run_v2_service.backend_service.name
  }

  depends_on = [google_project_service.gcp_services]
}

# Dynamically extract and apply DNS records from Cloud Run domain mapping status
locals {
  dns_records = var.domain_name != "" ? {
    for idx, record in try(google_cloud_run_domain_mapping.backend_mapping[0].status[0].resource_records, []) :
    "${record.type}-${record.name}-${record.rrdata}" => record
  } : {}
}

resource "google_dns_record_set" "backend_dns_records" {
  for_each = local.dns_records

  project      = var.project_id
  managed_zone = google_dns_managed_zone.dns_zone[0].name

  # Standardize root records (@) and subdomains
  name    = each.value.name == "@" ? "${var.domain_name}." : "${each.value.name}.${var.domain_name}."
  type    = each.value.type
  ttl     = 300
  rrdatas = [each.value.rrdata]
}
