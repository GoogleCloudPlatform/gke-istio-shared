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

# This script installs a MariaDB server, adds a user, and loads it with test data

echo "Install MariaDB on mesh expansion GCE instance"
sudo apt-get update && sudo apt-get install --no-install-recommends -y mariadb-server

echo "Setup privileges on mesh expansion gce and setup bookinfo database on"
echo "mesh expansion gce"
sudo mysql -e "grant all privileges on *.* to 'root'@'localhost' identified by \
  'password'; flush privileges" || echo "DB already exists and has a password"

curl https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/src/mysql/mysqldb-init.sql |
  mysql -u root --password=password -h 127.0.0.1 || echo "Wasn't able to load \
  data. Maybe it already exists?"