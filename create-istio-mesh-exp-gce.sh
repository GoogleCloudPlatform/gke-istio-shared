#! /usr/bin/env bash

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

# shellcheck source=verify-functions.sh

VM="${1}"
PROJECT="${2}"
NETWORK="${3}"
ZONE="${4}"

# Create gce instance for istio mesh expansion if it doesn't exist
if [[ ! $(gcloud compute instances list --project "${PROJECT}" \
                                        --filter "name=${VM}" \
                                        --format "value(name)") ]]; then
  gcloud compute instances create "${VM}" --project "${PROJECT}" \
                                          --network "${NETWORK}" \
                                          --tags "mysql" \
                                          --zone "${ZONE}"
fi

# Ensure that the GKE cluster can access the MySQL DB port on the VM
if [[ ! $(gcloud compute firewall-rules list --project "${PROJECT}" \
                                             --filter "name=allow-mysql" \
                                             --format 'value(name)') ]]; then
  gcloud compute firewall-rules create allow-mysql --project "${PROJECT}" \
                                                   --network "${NETWORK}" \
                                                   --target-tags "mysql" \
                                                   --source-ranges "10.0.0.0/9" \
                                                   --allow "tcp:3306"
fi

# Ensure that one can SSH to the cluster from anywhere
if [[ ! $(gcloud compute firewall-rules list --project "${PROJECT}" \
                                             --filter "name=allow-ssh-${VM}" \
                                             --format 'value(name)') ]]; then
  gcloud compute firewall-rules create allow-ssh-"${VM}" --project "${PROJECT}" \
                                                         --network "${NETWORK}" \
                                                         --target-tags "mysql" \
                                                         --source-ranges "0.0.0.0/0" \
                                                         --allow "tcp:22"
fi
