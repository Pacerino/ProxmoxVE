#!/usr/bin/env bash
export SOURCE_REPO="${SOURCE_REPO:-Pacerino/ProxmoxVE}"
export SOURCE_BRANCH="${SOURCE_BRANCH:-main}"
source <(curl -fsSL "https://raw.githubusercontent.com/${SOURCE_REPO}/${SOURCE_BRANCH}/misc/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MoldyTaint
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/MoldyTaint/Cinephage

APP="Cinephage"
var_tags="${var_tags:-media;arr}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-6144}"
var_disk="${var_disk:-12}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-no}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/cinephage ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  NODE_VERSION="22" setup_nodejs

  if check_for_gh_release "cinephage" "MoldyTaint/Cinephage"; then
    msg_info "Stopping Service"
    systemctl stop cinephage
    msg_ok "Stopped Service"

    create_backup /opt/cinephage/.env /opt/cinephage/data

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "cinephage" "MoldyTaint/Cinephage" "tarball"

    restore_backup

    msg_info "Rebuilding Application"
    cd /opt/cinephage
    $STD npm ci
    $STD npm run build
    $STD npm prune --omit=dev
    msg_ok "Rebuilt Application"

    msg_info "Starting Service"
    systemctl start cinephage
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:3000${CL}"
