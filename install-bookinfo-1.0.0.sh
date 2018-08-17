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

ISTIO_DIR="${1}"
NAMESPACE="${2}"
SHARED_DIR="${3}"
ISTIO_AUTH_POLICY="${4}"

source "${SHARED_DIR}/verify-functions.sh"

# Install the istio bookinfo applicaton
kubectl apply -f <("${ISTIO_DIR}"/bin/istioctl kube-inject -f \
  "${ISTIO_DIR}"/samples/bookinfo/platform/kube/bookinfo.yaml)

# The following loops are used to clean up any configuration left over from a
# failed deployment before attempting to redeploy. This prevents errors from
# istioctl.

# Clean up any VirtualService left configured in Istio.
for SERVICE in "productpage" "reviews" "ratings" "details" "bookinfo"; do
  if ! "${ISTIO_DIR}"/bin/istioctl get virtualservice "${SERVICE}" \
       | grep -q 'No resources found'; then
    "${ISTIO_DIR}"/bin/istioctl delete virtualservice "${SERVICE}"
  fi
done

# Clean up any DestinationRule left configured in Istio
for DEST_RULE in "productpage" "reviews" "ratings" "details"; do
  if ! "${ISTIO_DIR}"/bin/istioctl get destinationrule "${DEST_RULE}" \
       | grep -q 'No resources found'; then
    "${ISTIO_DIR}"/bin/istioctl delete destinationrule "${DEST_RULE}"
  fi
done

# Clean up any Gateway left configured in Istio
if ! "${ISTIO_DIR}"/bin/istioctl get gateways bookinfo-gateway \
     | grep -q 'No resources found'; then
  "${ISTIO_DIR}"/bin/istioctl delete gateway bookinfo-gateway
fi

# Create all necessary Istio Gateway, VirtualService, and DestinationRule
# configurations
"${ISTIO_DIR}"/bin/istioctl create -f \
  "${ISTIO_DIR}"/samples/bookinfo/networking/bookinfo-gateway.yaml

"${ISTIO_DIR}"/bin/istioctl create -f \
  "${ISTIO_DIR}"/samples/bookinfo/networking/virtual-service-all-v1.yaml

if [[ ${ISTIO_AUTH_POLICY} == "MUTUAL_TLS" ]]; then
  "${ISTIO_DIR}"/bin/istioctl create -f \
    "${ISTIO_DIR}"/samples/bookinfo/networking/destination-rule-all-mtls.yaml
else
  "${ISTIO_DIR}"/bin/istioctl create -f \
    "${ISTIO_DIR}"/samples/bookinfo/networking/destination-rule-all.yaml
fi

"${ISTIO_DIR}"/bin/istioctl replace -f \
  "${ISTIO_DIR}"/samples/bookinfo/networking/virtual-service-reviews-v3.yaml

echo "Check that BookInfo services are installed"

for SERVICE_LABEL in "details" "productpage" "ratings" "reviews"; do
  # Poll 3 times on a 5 second interval
  if ! service_is_installed "${SERVICE_LABEL}" 3 5 "${NAMESPACE}" ; then
    echo "Service ${SERVICE_LABEL} in Istio deployment is not created. Aborting..."
    exit 1
  fi
done

# verify  bookinfo pods
for POD_LABEL in "app=details" "app=productpage" "app=ratings" "app=reviews"; do
  if ! pod_is_running "${POD_LABEL}" 10 15 "${NAMESPACE}" ; then
    echo "Pod ${POD_LABEL} in BookInfo is not running. Aborting..."
    exit 1
  fi
done
