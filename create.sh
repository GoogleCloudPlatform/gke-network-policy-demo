#!/bin/bash -e

# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# "---------------------------------------------------------"
# "-                                                       -"
# "-  Create starts a GKE Cluster and installs             -"
# "-  a Cassandra StatefulSet                              -"
# "-                                                       -"
# "---------------------------------------------------------"

set -o errexit
set -o nounset
set -o pipefail

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck disable=SC1090
source "$ROOT"/common.sh

# Enable Compute Engine, Kubernetes Engine, and Container Builder
echo "Enabling the Compute API, the Container API, the Cloud Build API"
gcloud services enable \
compute.googleapis.com \
container.googleapis.com \
cloudbuild.googleapis.com

# Runs the generate-tfvars.sh
"$ROOT"/generate-tfvars.sh

cd "$ROOT"/terraform && \
terraform init -input=false && \
terraform apply -input=false -auto-approve

# Roll out hello-app
"$ROOT"/setup_manifests.sh
