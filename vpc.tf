# VPC Network for SweatCheck
resource "google_compute_network" "vpc_network" {
  name                    = "${local.prefix}-vpc"
  auto_create_subnetworks = false
  project                 = var.project_id
  depends_on              = [google_project_service.gcp_services]
}

# Subnet for general resources and the Serverless VPC Connector
resource "google_compute_subnetwork" "subnet" {
  name          = "${local.prefix}-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.id
  project       = var.project_id
}

# Allocate a private IP range for Private Services Access (Cloud SQL peering)
resource "google_compute_global_address" "private_ip_alloc" {
  name          = "${local.prefix}-private-ip-alloc"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc_network.id
  project       = var.project_id
}

# Create a private connection between the VPC and Google Services (like Cloud SQL)
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc.name]
  depends_on              = [google_project_service.gcp_services]
}

# Serverless VPC Access Connector to route Cloud Run traffic into the VPC
resource "google_vpc_access_connector" "vpc_connector" {
  name          = "sweat-conn-${var.environment}"
  region        = var.region
  ip_cidr_range = "10.8.0.0/28" # Small /28 block is perfect for Serverless Connector
  network       = google_compute_network.vpc_network.name
  project       = var.project_id

  # Ensure the connection is created and APIs are enabled first
  depends_on = [
    google_project_service.gcp_services,
    google_service_networking_connection.private_vpc_connection
  ]
}
