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

# This script deploys Grafana to the GKE cluster

ISTIO_DIR="${1}"
NAMESPACE="${2}"
SHARED_DIR="${3}"

#### functions to check existence of resources
source "$SHARED_DIR/verify-functions.sh"

# Install the Grafana add-on so the user can view Istio metrics in a graphical
# dashboard
echo "Installing Grafana addon"
kubectl apply -f "${ISTIO_DIR}"/install/kubernetes/addons/grafana.yaml

# Verify the install
echo "Verifying Grafana is installed"

# Verify grafana services
for SERVICE_LABEL in "grafana"
do
  # Poll 12 times on a 5 second interval
  if ! service_is_installed "${SERVICE_LABEL}" 12 5 "${NAMESPACE}" ; then
    echo "Timed out waiting for grafana to come online"
	  exit 1
  fi
done

echo "Grafana was installed"
