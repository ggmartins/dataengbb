##TODO move to ../../../stage/services/gke-cluster/main.tf
provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_client_config" "default" {}

data "gc_gke_cluster" "cluster" {
  name = module.gke.cluster_id
}

data "gc_gke_cluster_auth" "cluster" {
  name = module.gke.cluster_id
}

module "gke" {
  source                     = "terraform-google-modules/kubernetes-engine/google"
  project_id                 = var.project_id
  name                       = local.cluster_name
  region                     = var.region
  zones                      = ["us-central1-a", "us-central1-b", "us-central1-f"]
  network                    = "vpc-01"
  subnetwork                 = "us-central1-01"
  ip_range_pods              = "us-central1-01-gke-01-pods"
  ip_range_services          = "us-central1-01-gke-01-services"
  http_load_balancing        = false
  horizontal_pod_autoscaling = true
  network_policy             = true

  tags = {
    Environment = var.environment
    GithubRepo  = "opendata-infrastructure"
    GithubOrg   = "chicago-cdac"
  }

  node_pools = [
    {
      name               = "default-node-pool"
      machine_type       = "n1-standard-1"
      node_locations     = "us-central1-b,us-central1-c"
      min_count          = 1
      max_count          = 2
      local_ssd_count    = 0
      disk_size_gb       = 5
      disk_type          = "pd-standard"
      image_type         = "COS"
      auto_repair        = true
      auto_upgrade       = true
      # gcloud iam service-accounts list (email ?)
      service_account    = "XXXXXXXXX-compute@developer.gserviceaccount.com"
      preemptible        = false
      initial_node_count = 80
    },
  ]

  node_pools_oauth_scopes = {
    all = []

    default-node-pool = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  node_pools_labels = {
    all = {}

    default-node-pool = {
      default-node-pool = true
    }
  }

  node_pools_metadata = {
    all = {}

    default-node-pool = {
      node-pool-metadata-custom-value = "my-node-pool"
    }
  }

  node_pools_taints = {
    all = []

    default-node-pool = [
      {
        key    = "default-node-pool"
        value  = true
        effect = "PREFER_NO_SCHEDULE"
      },
    ]
  }

  node_pools_tags = {
    all = []

    default-node-pool = [
      "default-node-pool",
    ]
  }
}
