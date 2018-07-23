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

# This script integrates the GCE expansion VM into the Istio mesh and
# updates the routing rules to point to the expansion VM.

PROJECT="${1}"
ZONE="${2}"
VM="${3}"
ISTIO_DIR="${4}"
SHARED_DIR="${5}"

# Variables used later in the script
SETUP_SIDECAR_COMMAND='./setup-remote-gce-sidecar.sh '

# Register service on GCE instance with the Istio infrastructure
echo "Register GCE service with Istio"
"${ISTIO_DIR}/bin/istioctl" register -n vm mysqldb "$(gcloud compute instances \
  describe "${VM}" --format='value(networkInterfaces[].networkIP)' \
                   --project "${PROJECT}" \
                   --zone "${ZONE}")" 3306

# Update bookinfo rating service to use the GCE MySQL service
echo "Update bookinfo ratings service to use GCE service"
kubectl apply -f <("${ISTIO_DIR}"/bin/istioctl kube-inject -f \
  "${ISTIO_DIR}/samples/bookinfo/kube/bookinfo-ratings-v2-mysql-vm.yaml")
"${ISTIO_DIR}/bin/istioctl" replace -f \
  "${ISTIO_DIR}/samples/bookinfo/routing/route-rule-ratings-mysql-vm.yaml"

# Copy mesh expansion sidecar setup script to GCE
echo "Copy mesh expansion GCE service setup script to instance"
gcloud compute scp "${SHARED_DIR}/setup-remote-gce-sidecar.sh" "${VM}":~/ \
  --project "${PROJECT}" \
  --zone "${ZONE}"

# Run mesh expansion sidecar setup script
echo "Run service setup script on GCE"
gcloud compute ssh "${VM}" --command "${SETUP_SIDECAR_COMMAND}" \
                           --project "${PROJECT}" \
                           --zone "${ZONE}"
