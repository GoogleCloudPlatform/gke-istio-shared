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

# This file configures the Envoy proxy to support a MariaDB/MySQL database on a
# GCE instance.

# update the service proxy environment config
echo "Update istio service proxy environment file"

sudo sed -i -e "\$aISTIO_INBOUND_PORTS=3306" /var/lib/istio/envoy/sidecar.env
sudo sed -i -e "\$aISTIO_SERVICE=mysqldb" /var/lib/istio/envoy/sidecar.env
sudo sed -i -e "\$aISTIO_NAMESPACE=vm" /var/lib/istio/envoy/sidecar.env

sudo systemctl restart istio