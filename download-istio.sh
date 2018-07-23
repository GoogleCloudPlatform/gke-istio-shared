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

# Download the Istio components from GitHub and extract them to disk

ISTIO_VERSION="${1}"
TARGET_DIR="${2}"

echo "Istio version: ${ISTIO_VERSION}"

# The istioctl binary is precompiled so we must determine which Istio version
# we need to download.
if [[ "$(uname -s)" == "Linux" ]]; then
    export OS_TYPE="linux"
elif [[ "$(uname -s)" == "Darwin" ]]; then
    export OS_TYPE="osx"
fi

curl -s -L --remote-name "https://github.com/istio/istio/releases/download/${ISTIO_VERSION}/istio-${ISTIO_VERSION}-${OS_TYPE}.tar.gz"

# extract istio
echo "Extracting Istio tarball to ${TARGET_DIR}"
tar xzf "istio-${ISTIO_VERSION}-${OS_TYPE}.tar.gz" --directory "${TARGET_DIR}"

# remove istio zip
rm "istio-${ISTIO_VERSION}-${OS_TYPE}.tar.gz"
