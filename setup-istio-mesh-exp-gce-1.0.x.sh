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

# This script takes an untouched GCE VM and adds the necessary configuration to
# it to allow it to join the Istio mesh.

PROJECT="${1}"
VM="${2}"
ISTIO_DIR="${3}"
SHARED_DIR="${4}"
ZONE="${5}"

# Variables to be used later in the script
RETRY_COUNT=0
MESH_TEST_COMMAND='curl -s --fail -w "\n" http://productpage.default.svc.cluster.local:9080/api/v1/products/0/ratings'
SLEEP=5
SETUP_SERVICE_COMMAND='./setup-remote-gce-service.sh'

source "${SHARED_DIR}"/verify-functions.sh

# Must export these options for the setupMeshEx.sh script
export GCP_OPTS="--zone ${ZONE} --project ${PROJECT}"

# Setup Envoy on the created GCE instance
# Navigate to the Istio directory because that is what this script expects
pushd "${ISTIO_DIR}"
./install/tools/setupMeshEx.sh gceMachineSetup "${VM}"
popd

# Copy mesh expansion service setup script to gce
echo "Copy mesh expansion GCE service setup script to GCE"
gcloud compute scp "${SHARED_DIR}/setup-remote-gce-service.sh" "${VM}":~/ \
  --project "${PROJECT}" --zone "${ZONE}"

# run mesh expansion service setup script on remote gce
echo "Run service setup script on GCE"
gcloud compute ssh "${VM}" --command "${SETUP_SERVICE_COMMAND}" \
  --project "${PROJECT}" --zone "${ZONE}"
