# Google Cloud DNS Managed Zone for this project's custom domain/subdomain
resource "google_dns_managed_zone" "dns_zone" {
  count       = var.domain_name != "" ? 1 : 0
  name        = "sweatapp-dns-zone"
  dns_name    = "${var.domain_name}." # Must end with a trailing dot
  description = "Managed DNS zone for SweatCheck"
  project     = var.project_id

  depends_on = [google_project_service.gcp_services]
}

# Note: Cloud Run Custom Domain Mapping was created manually in the GCP Console
# to bypass the Google Search Console Service Account "email does not exist" sync delay/bug.
# Since it is managed manually, we do not define it in Terraform to prevent 403 authorization errors.

# Static DNS records for the domain mapping.
# Since Cloud Run custom domains always map to Google's global hosting infrastructure,
# we can define these statically. This avoids any dynamic API dependencies during plan.
resource "google_dns_record_set" "root_a" {
  count        = var.domain_name != "" ? 1 : 0
  project      = var.project_id
  managed_zone = google_dns_managed_zone.dns_zone[0].name
  name         = "${var.domain_name}."
  type         = "A"
  ttl          = 300
  rrdatas = [
    "216.239.32.21",
    "216.239.34.21",
    "216.239.36.21",
    "216.239.38.21"
  ]
}

resource "google_dns_record_set" "root_aaaa" {
  count        = var.domain_name != "" ? 1 : 0
  project      = var.project_id
  managed_zone = google_dns_managed_zone.dns_zone[0].name
  name         = "${var.domain_name}."
  type         = "AAAA"
  ttl          = 300
  rrdatas = [
    "2001:4860:4802:32::15",
    "2001:4860:4802:34::15",
    "2001:4860:4802:36::15",
    "2001:4860:4802:38::15"
  ]
}

# Also support the 'www' subdomain pointing to Cloud Run by default
resource "google_dns_record_set" "www_cname" {
  count        = var.domain_name != "" ? 1 : 0
  project      = var.project_id
  managed_zone = google_dns_managed_zone.dns_zone[0].name
  name         = "www.${var.domain_name}."
  type         = "CNAME"
  ttl          = 300
  rrdatas      = ["ghs.googlehosted.com."]
}
