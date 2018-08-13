#!/usr/bin/env bash
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

# bash "strict-mode", fail immediately if there is a problem
set -euo pipefail

call_bastion() {
  local command=$1; shift;
  # shellcheck disable=SC2005
  echo "$(gcloud compute ssh gke-demo-bastion --command "${command}")"
}
MESSAGE="successfully rolled out"

call_bastion "source /etc/profile && exit"
call_bastion "kubectl apply -f ./manifests/hello-app/"

while true
do
  ROLLOUT=$(call_bastion "kubectl rollout status --watch=false \
  deployment/hello-server") &> /dev/null
  if [[ $ROLLOUT = *"$MESSAGE"* ]]; then
    break
  fi
  sleep 2
done
while true
do
  ROLLOUT=$(call_bastion "kubectl rollout status --watch=false \
  deployment/hello-client-allowed") &> /dev/null
  if [[ $ROLLOUT = *"$MESSAGE"* ]]; then
    break
  fi
  sleep 2
done
while true
do
  ROLLOUT=$(call_bastion "kubectl rollout status --watch=false \
  deployment/hello-client-blocked") &> /dev/null
  if [[ $ROLLOUT = *"$MESSAGE"* ]]; then
    break
  fi
  sleep 2
done
exit 0
