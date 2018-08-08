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

COMMAND="gcloud compute ssh gke-demo-bastion --command"
HELLO_WORLD='Hello, world!'
TIMED_OUT='wget: download timed out'

$COMMAND 'kubectl logs --tail 10 $(kubectl get pods -oname -l app=hello)' \
 | grep "$HELLO_WORLD" &> /dev/null
if [ $? == 0 ]; then
  echo "step 1 of the validation passed."
else
  exit 1
fi

$COMMAND 'kubectl logs --tail 10 $(kubectl get pods -oname -l app=not-hello)' \
 | grep "$HELLO_WORLD" &> /dev/null
if [ $? == 0 ]; then
  echo "step 2 of the validation passed."
else
  exit 1
fi

$COMMAND 'kubectl apply -f ./manifests/network-policy.yaml' &> /dev/null
# Sleep for 3s while more logs come in.
sleep 3
$COMMAND 'kubectl logs --tail 10 $(kubectl get pods -oname -l app=not-hello)' \
 | grep "$TIMED_OUT" &> /dev/null
if [ $? == 0 ]; then
  echo "step 3 of the validation passed."
else
  exit 1
fi

$COMMAND 'kubectl logs --tail 10 $(kubectl get pods -oname -l app=hello)' \
 | grep "$HELLO_WORLD" &> /dev/null
if [ $? == 0 ]; then
  echo "step 4 of the validation passed."
else
  exit 1
fi

# Clean Up

$COMMAND "kubectl delete -f ./manifests/network-policy.yaml" &> /dev/null
