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
ZONE="${2}"
CLUSTER_NAME="${3}"
ISTIO_AUTH_POLICY="${4}"
EXP_SRVC_NAMESPACE="${5}"
ISTIO_DIR="${6}"

# Export GCP_OPTS as they are required by the setupMeshEx.sh script
# Navigate to the Istio directory so that the generated .env files are in the
# correct directory for the setupVmEx.sh script.
pushd "${ISTIO_DIR}"
export GCP_OPTS="--zone ${ZONE} --project ${PROJECT}"
./install/tools/setupMeshEx.sh generateClusterEnv "${CLUSTER_NAME}"

# Update the cluster.env file if not doing TLS (mesh expansion does not support TLS)
if [[ "${ISTIO_AUTH_POLICY}" == "NONE" ]] ; then
  # Be careful when editing this sed command as Mac and Linux do not use the
  # same version of sed
  sed -i'' -e "s/CONTROL_PLANE_AUTH_POLICY=MUTUAL_TLS/CONTROL_PLANE_AUTH_POLICY=${ISTIO_AUTH_POLICY}/g" cluster.env
fi

# Verify cluster.env file has correct auth setting
TLS="$(grep CONTROL_PLANE_AUTH_POLICY="${ISTIO_AUTH_POLICY}" < cluster.env)"
if [ "${TLS}" == "CONTROL_PLANE_AUTH_POLICY=${ISTIO_AUTH_POLICY}" ] ; then
  echo "cluster.env authentication policy parameter set correctly with
CONTROL_PLANE_AUTH_POLICY=${ISTIO_AUTH_POLICY}"
else
  echo "cluster.env authentication policy parameter does not match required
setting of ${ISTIO_AUTH_POLICY}"
  exit 1
fi

# Create the DNS config file for the VM. This is necessary to allow the VM to
# resolve cluster service names.
echo "Creating DNS configuration file for the Istio-integrated VM"
./install/tools/setupMeshEx.sh generateDnsmasq

# Verify kubedns file created
KUBE_DNS_CREATED=$(ls kubedns)
if [ "${KUBE_DNS_CREATED}" == "kubedns" ] ; then
  echo "DNS configuration created successfully"
else
  echo "DNS configuration not created successfully"
  exit 1
fi

# Create expansion service namespace to locate the VM's service if not already
# created
NS="$(kubectl get namespace --field-selector=metadata.name="${EXP_SRVC_NAMESPACE}" \
                            --output jsonpath="{.items[*].metadata.name}")"
if [ "${NS}" == "" ] ; then
  echo "Creating namespace for VM services"
  kubectl create namespace "${EXP_SRVC_NAMESPACE}"
fi
popd