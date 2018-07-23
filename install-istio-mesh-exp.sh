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

# This script creates the Kubernetes resources necessary to expand Istio
# outside the GKE cluster.

ISTIO_DIR="${1}"
ISTIO_NAMESPACE="${2}"
SHARED_DIR="${3}"

source "${SHARED_DIR}/verify-functions.sh"

echo "Install Istio components necessary for mesh expansion"
kubectl apply -f "$ISTIO_DIR/install/kubernetes/mesh-expansion.yaml"

echo "Verify Istio mesh expansion services have IP addresses"

# Verify the Istio mesh expansion ILB's have IP addresses allocated
for ISTIO_SERVICE in "istio-pilot-ilb" "mixer-ilb" "istio-ingressgateway"; do
  if ! service_ip_is_allocated "${ISTIO_SERVICE}" "10" "30" \
        "${ISTIO_NAMESPACE}" ; then
    echo "Timed out waiting for Istio mesh expansion services to be allocated"
    echo "IP addresses"
    exit 1
  fi
done
