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

// https://www.terraform.io/docs/providers/google/r/compute_firewall.html
// Defines a firewall rule to allow access to the bastion host is accessible
resource "google_compute_firewall" "bastion-ssh" {
  name          = "bastion-ssh"
  network       = "${google_compute_network.gke-network.self_link}"
  direction     = "INGRESS"
  project       = "${var.project}"
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags = "${var.bastion_tags}"
}
