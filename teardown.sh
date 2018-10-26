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
# "-  Delete uninstalls Cassandra and deletes              -"
# "-  the GKE cluster                                      -"
# "-                                                       -"
# "---------------------------------------------------------"

# Do not set errexit as it makes partial deletes impossible
set -o nounset
set -o pipefail

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck disable=SC1090
source "$ROOT"/common.sh

# Tear down hello-app
gcloud compute ssh "${USER}"@"${BASTION_INSTANCE_NAME}" --command "kubectl delete -f manifests/hello-app/"

# remove metadata for bastion (SSH keys)
gcloud compute instances remove-metadata --all "${BASTION_INSTANCE_NAME}" --project "${PROJECT}" --zone "${ZONE}"

# Terraform destroy
cd terraform && terraform destroy -auto-approve

