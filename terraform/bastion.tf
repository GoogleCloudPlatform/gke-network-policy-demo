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
This file contains the configuration of a GCP instance to use as a bastion node.
A bastion node is an accessible instance within an otherwise unaccessible network that is
most often used when a VPN is not available
*/

// https://www.terraform.io/docs/providers/template/index.html
// This template will be rendered and used as the startup script for the bastion.
// It installs kubectl and configures it to access the GKE cluster.
data "template_file" "startup_script" {
  template = <<EOF
sudo apt-get update -y
sudo apt-get install -y kubectl
echo "gcloud container clusters get-credentials $${cluster_name} --zone $${cluster_zone} --project $${project}" >> /etc/profile
EOF


  vars = {
    cluster_name = var.cluster_name
    cluster_zone = var.zone
    project = var.project
  }
}

// https://www.terraform.io/docs/providers/google/r/compute_instance.html
// bastion host for access and administration of a private cluster.

resource "google_compute_instance" "gke-bastion" {
  name = var.bastion_hostname
  machine_type = var.bastion_machine_type
  zone = var.zone
  project = var.project
  tags = var.bastion_tags
  allow_stopping_for_update = true

  // Specify the Operating System Family and version.
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  // Define a network interface in the correct subnet.
  network_interface {
    subnetwork = google_compute_subnetwork.cluster-subnet.self_link

    // Add an ephemeral external IP.
    access_config {
      // Implicit ephemeral IP
    }
  }

  // Ensure that when the bastion host is booted, it will have kubectl.
  # metadata_startup_script = "sudo apt-get install -y kubectl"
  metadata_startup_script = data.template_file.startup_script.rendered

  // Necessary scopes for administering kubernetes.
  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro", "cloud-platform"]
  }

  // Copy the manifests to the bastion
  // Copy the manifests to the bastion
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOF
        READY=""
        for i in $(seq 1 18); do
          if gcloud compute ssh ${var.ssh_user_bastion}@${var.bastion_hostname} --command uptime; then
            READY="yes"
            break;
          fi
          echo "Waiting for ${var.bastion_hostname} to initialize..."
          sleep 10;
        done

        if [[ -z $READY ]]; then
          echo "${var.bastion_hostname} failed to start in time."
          echo "Please verify that the instance starts and then re-run `terraform apply`"
          exit 1
        fi

        gcloud compute  --project ${var.project} scp --zone ${var.zone} --recurse ../manifests ${var.ssh_user_bastion}@${var.bastion_hostname}:
EOF

}
}
