/*
Copyright 2018 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

/*
This file defines the kubernetes cluster configuration. It is effectively a codified
version of the Cloud Console form you would use to create a Kubernetes Engine cluster.
*/

# Gets the current version of Kubernetes engine
data "google_container_engine_versions" "gke_version" {
  location   = var.zone
}

// https://www.terraform.io/docs/providers/google/d/google_container_cluster.html
// Create the primary cluster for this project.
resource "google_container_cluster" "primary" {
  name               = var.cluster_name
  project            = var.project
  location           = var.zone
  network            = google_compute_network.gke-network.self_link
  subnetwork         = google_compute_subnetwork.cluster-subnet.self_link
  initial_node_count = var.initial_node_count
  min_master_version = data.google_container_engine_versions.gke_version.latest_master_version
  node_locations   = []

  // Scopes necessary for the nodes to function correctly
  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    machine_type = var.node_machine_type
    image_type   = "COS"

    // (Optional) The Kubernetes labels (key/value pairs) to be applied to each node.
    labels = {
      status = "poc"
    }

    // (Optional) The list of instance tags applied to all nodes.
    // Tags are used to identify valid sources or targets for network firewalls.
    tags = ["poc"]
  }

  // (Required for private cluster, optional otherwise) Configuration for cluster IP allocation.
  // As of now, only pre-allocated subnetworks (custom type with
  // secondary ranges) are supported. This will activate IP aliases.
  ip_allocation_policy {
    cluster_secondary_range_name = "secondary-range"
  }

  // In a private cluster, the master has two IP addresses, one public and one
  // private. Nodes communicate to the master through this private IP address.
  private_cluster_config {
    enable_private_nodes   = true
    master_ipv4_cidr_block = "10.0.90.0/28"
  }

  // (Required for private cluster, optional otherwise) network (cidr) from which cluster is accessible
  master_authorized_networks_config {
    cidr_blocks {
      display_name = "bastion"
      cidr_block   = join("/", [google_compute_instance.gke-bastion.network_interface[0].access_config[0].nat_ip, "32"])

    }
  }

  // Required for Calico, optional otherwise.
  // Configuration options for the NetworkPolicy feature
  network_policy {
    enabled  = true
    provider = "CALICO" // CALICO is currently the only supported provider
  }

  // Required for network_policy enabled cluster, optional otherwise
  // Addons config supports other options as well, see:
  // https://www.terraform.io/docs/providers/google/r/container_cluster.html#addons_config
  addons_config {
    network_policy_config {
      disabled = false
    }
  }

  // This is required to workaround a perma-diff bug in terraform:
  // see: https://github.com/terraform-providers/terraform-provider-google/issues/1382
  lifecycle {
    ignore_changes = [
      ip_allocation_policy,
      network,
      subnetwork,
    ]
  }
}
