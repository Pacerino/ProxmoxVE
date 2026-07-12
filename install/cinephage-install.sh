#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MoldyTaint
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/MoldyTaint/Cinephage

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  build-essential \
  ffmpeg
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs

fetch_and_deploy_gh_release "cinephage" "MoldyTaint/Cinephage" "tarball"

msg_info "Building Application"
cd /opt/cinephage
$STD npm ci
$STD npm run build
$STD npm prune --omit=dev
msg_ok "Built Application"

msg_info "Configuring Application"
mkdir -p /opt/cinephage/data
BETTER_AUTH_SECRET=$(openssl rand -base64 32)
cat <<EOF >/opt/cinephage/.env
NODE_ENV=production
HOST=0.0.0.0
PORT=3000
ORIGIN=http://${LOCAL_IP}:3000
BETTER_AUTH_URL=http://${LOCAL_IP}:3000
BETTER_AUTH_SECRET=${BETTER_AUTH_SECRET}
DATA_DIR=/opt/cinephage/data
TZ=UTC
EOF
{
  echo "Cinephage Credentials"
  echo "BETTER_AUTH_SECRET: ${BETTER_AUTH_SECRET}"
} >>~/cinephage.creds
msg_ok "Configured Application"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/cinephage.service
[Unit]
Description=Cinephage Media Manager
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/cinephage
EnvironmentFile=/opt/cinephage/.env
ExecStart=/usr/bin/node server.js
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now cinephage
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
