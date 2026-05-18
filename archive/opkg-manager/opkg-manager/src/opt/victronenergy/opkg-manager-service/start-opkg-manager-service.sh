#!/bin/bash

set -eu

SERVICE_NAME="opkg-manager-service"
SERVICE_TEMPLATE_DIR="${VE_ROOT_DIR:-}/opt/victronenergy/service/${SERVICE_NAME}"
SERVICE_DIR="${VE_ROOT_DIR:-}/service/${SERVICE_NAME}"

if [[ ! -d "${SERVICE_TEMPLATE_DIR}" ]]; then
  echo "warning: service template not found at ${SERVICE_TEMPLATE_DIR}"
  exit 0
fi

if [[ ! -d "${SERVICE_DIR}" ]]; then
  cp -R "${SERVICE_TEMPLATE_DIR}/" "${VE_ROOT_DIR:-}/service/"
fi

svc -u "${SERVICE_DIR}" >/dev/null 2>&1 || true
