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

# This script verifies that the sample application is responding to HTTP
# requests

ISTIO_NAMESPACE="${1}"
SHARED_DIR="${2}"
RETRY_COUNT=0
SLEEP=10

source "${SHARED_DIR}/verify-functions.sh"

#  verify bookinfo application is running
echo "Verify /productpage returns a 200 response code"

# get gateway info
INGRESS_HOST=$(kubectl get -n "$ISTIO_NAMESPACE" service istio-ingressgateway -o \
  jsonpath='{.status.loadBalancer.ingress[0].ip}')
INGRESS_PORT=$(kubectl get -n "$ISTIO_NAMESPACE" service istio-ingressgateway -o \
  jsonpath='{.spec.ports[?(@.name=="http")].port}')

# Curl for /productpage with retries
until [[ $(curl -s -o /dev/null --fail -w "%{http_code}\n"\
           http://"${INGRESS_HOST}":"${INGRESS_PORT}"/productpage) -eq 200 ]]; do
    if [[ ${RETRY_COUNT} -gt 24 ]]; then
     echo "Retry count exceeded. Exiting..."
     exit 1
    fi
    NUM_SECONDS="$(( RETRY_COUNT * SLEEP ))"
    echo "/productpage did not return an HTTP 200 response code after"
    echo "${NUM_SECONDS} seconds"
    sleep "${SLEEP}"
    RETRY_COUNT="$(( RETRY_COUNT + 1 ))"
done

echo "/productpage returns an HTTP 200 response code"
