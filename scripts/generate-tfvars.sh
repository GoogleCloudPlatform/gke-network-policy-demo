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

# "---------------------------------------------------------"
# "-                                                       -"
# "-  Helper script to generate terraform variables        -"
# "-  file based on glcoud defaults.                       -"
# "-                                                       -"
# "---------------------------------------------------------"

# Stop immediately if something goes wrong
set -euo pipefail

# The purpose is to populate defaults for subsequent terraform commands.
ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck disable=SC1090
source "$ROOT"/common.sh

# This script should be run from directory that contains the terraform directory.

# Use git to find the top-level directory and confirm
# by looking for the 'terraform' directory
PROJECT_DIR="$(git rev-parse --show-toplevel)"
if [[ -d "./terraform" ]]; then
	PROJECT_DIR="$(pwd)"
fi
if [[ -z "${PROJECT_DIR}" ]]; then
    echo "Could not identify project base directory." 1>&2
    echo "Please re-run from a project directory and ensure" 1>&2
    echo "the .git directory exists." 1>&2
    exit 1;
fi


(
cd "${PROJECT_DIR}"

TFVARS_FILE="./terraform/terraform.tfvars"

# We don't want to overwrite a pre-existing tfvars file
if [[ -f "${TFVARS_FILE}" ]]
then
    echo "${TFVARS_FILE} already exists." 1>&2
    echo "Please remove or rename before regenerating." 1>&2
    exit 1;
else
# Write out all the values we gathered into a tfvars file so you don't
# have to enter the values manually
    cat <<EOF > "${TFVARS_FILE}"
project="${PROJECT}"
region="${REGION}"
zone="${ZONE}"
ssh_user_bastion="${USER}"
EOF
fi
)

