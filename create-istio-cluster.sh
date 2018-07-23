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

PROJECT="${1}"
CLUSTER_NAME="${2}"
ZONE="${3}"
ISTIO_NETWORK_NAME="${4}"

# Get the latest available cluster version
MASTER_VERSION=$(gcloud container get-server-config --zone="${ZONE}" \
  --format "value(validMasterVersions[0])" 2>/dev/null)

gcloud container clusters create "${CLUSTER_NAME}" \
  --enable-autorepair \
  --machine-type=n1-standard-2 \
  --num-nodes=4 \
  --network="${ISTIO_NETWORK_NAME}" \
  --project "${PROJECT}" \
  --cluster-version="${MASTER_VERSION}" \
  --zone "${ZONE}"

# Get the credentials to access the cluster
gcloud container clusters get-credentials "${CLUSTER_NAME}" --project "${PROJECT}" \
  --zone "${ZONE}"

# Bind cluster-admin role to the current user to grant sufficient privileges to
# deploy the rest of the infrastructure and print the current context
kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin \
  --user="$(gcloud config get-value core/account)"
kubectl config current-context
